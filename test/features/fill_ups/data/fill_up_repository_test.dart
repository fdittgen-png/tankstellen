// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/fill_ups/data/repositories/fill_up_repository.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';

/// In-memory fake [SettingsStorage] for repository tests.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

FillUp _make({
  String id = '1',
  DateTime? date,
  double liters = 40,
  double cost = 60,
  double odo = 10000,
  FuelType fuelType = FuelType.e10,
}) =>
    FillUp(
      id: id,
      date: date ?? DateTime(2026, 1, 1),
      liters: liters,
      totalCost: cost,
      odometerKm: odo,
      fuelType: fuelType,
    );

void main() {
  late _FakeSettingsStorage storage;
  late FillUpRepository repo;

  setUp(() {
    storage = _FakeSettingsStorage();
    repo = FillUpRepository(storage);
  });

  test('getAll returns empty when nothing stored', () {
    expect(repo.getAll(), isEmpty);
  });

  test('save adds a new entry', () async {
    await repo.save(_make(id: 'a'));
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'a');
  });

  test('save updates existing entry by id', () async {
    await repo.save(_make(id: 'a', liters: 40));
    await repo.save(_make(id: 'a', liters: 50));
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.liters, 50);
  });

  test('delete removes entry by id', () async {
    await repo.save(_make(id: 'a'));
    await repo.save(_make(id: 'b'));
    await repo.delete('a');
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'b');
  });

  test('delete with unknown id is a no-op', () async {
    await repo.save(_make(id: 'a'));
    await repo.delete('nonexistent');
    expect(repo.getAll().length, 1);
  });

  test('clear empties the log', () async {
    await repo.save(_make(id: 'a'));
    await repo.save(_make(id: 'b'));
    await repo.clear();
    expect(repo.getAll(), isEmpty);
  });

  test('getAll returns entries newest first', () async {
    await repo.save(
      _make(id: 'old', date: DateTime(2026, 1, 1)),
    );
    await repo.save(
      _make(id: 'newest', date: DateTime(2026, 3, 1)),
    );
    await repo.save(
      _make(id: 'mid', date: DateTime(2026, 2, 1)),
    );
    final all = repo.getAll();
    expect(all.map((f) => f.id).toList(), ['newest', 'mid', 'old']);
  });

  test('getAll survives JSON round-trip via storage', () async {
    // The subject here is SERIALISATION fidelity, so the record already
    // carries a currency — otherwise `save` stamps one (#4136) and this
    // would be measuring the stamp instead of the round-trip.
    final original = FillUp(
      id: 'x',
      date: DateTime(2026, 3, 15, 10, 30),
      liters: 42.5,
      totalCost: 67.89,
      odometerKm: 15432,
      fuelType: FuelType.diesel,
      stationId: 's1',
      stationName: 'Shell',
      notes: 'hi',
      currency: 'EUR',
    );
    await repo.save(original);
    final restored = repo.getAll().first;
    expect(restored, original);
  });

  group('#4136 — the currency stamp', () {
    test('a record with no currency gets the active one', () async {
      // Stamped in the repository rather than the form, so every
      // creation path is covered — manual entry, receipt scan, and
      // anything added later.
      await repo.save(_make(id: 'fresh'));
      expect(repo.getAll().single.currency, isNotNull);
    });

    test('a record that ALREADY has one keeps it', () async {
      // A backup restored in another country must not be relabelled
      // with today's currency — that is precisely the silent
      // cross-currency history the field exists to prevent.
      await repo.save(_make(id: 'imported').copyWith(currency: 'GBP'));
      expect(repo.getAll().single.currency, 'GBP');
    });

    test('re-saving does not relabel', () async {
      await repo.save(_make(id: 'a').copyWith(currency: 'CLP'));
      final stored = repo.getAll().single;
      await repo.save(stored);
      expect(repo.getAll().single.currency, 'CLP');
    });
  });

  group('#4428 — the stamp follows the evidence, not the profile', () {
    setUp(() => PriceFormatter.setCountry('DE'));
    tearDown(() => PriceFormatter.setCountry('FR'));

    test('a fill at a Swiss forecourt is NOT stored as EUR', () async {
      // The field report: EUR profile, CHF 51,73 paid by card. The
      // receipt scan supplies the currency, and the repository must
      // leave it alone instead of stamping the profile's over it.
      await repo.save(
        _make(id: 'gandria', cost: 51.73, liters: 25.61)
            .copyWith(currency: 'CHF'),
      );
      expect(repo.getAll().single.currency, 'CHF');
      expect(repo.getAll().single.totalCost, 51.73);
    });

    test('a station in another country decides the currency', () async {
      await repo.save(_make(id: 'abroad').copyWith(stationId: 'uk-7'));
      expect(repo.getAll().single.currency, 'GBP');
    });

    test('a domestic station still gets the profile currency', () async {
      await repo.save(_make(id: 'home').copyWith(stationId: 'de-7'));
      expect(repo.getAll().single.currency, 'EUR');
    });

    test('logged while the device is in an unnameable country → unknown',
        () async {
      await repo.save(_make(id: 'ch'), observedCountryCode: 'CH');
      expect(
        repo.getAll().single.currency,
        isNull,
        reason: 'unknown beats a confident wrong label',
      );
    });

    test('the observation is ignored without one (import, merge, edit)',
        () async {
      // `save` defaults to no observation on purpose: today's location
      // says nothing about a record being restored or merged.
      await repo.save(_make(id: 'restored'));
      expect(repo.getAll().single.currency, 'EUR');
    });

    test('an observation in a same-currency country changes nothing',
        () async {
      await repo.save(_make(id: 'fr'), observedCountryCode: 'FR');
      expect(repo.getAll().single.currency, 'EUR');
    });

    test('a deliberate unknown survives the next save', () async {
      // The trip re-linker, a swipe-undo and the correction editor all
      // re-save an existing row. None of them may quietly convert an
      // unknown into the profile's currency.
      await repo.save(_make(id: 'ch'), observedCountryCode: 'CH');
      final stored = repo.getAll().single;
      expect(stored.currency, isNull);
      await repo.save(stored.copyWith(liters: 26));
      expect(repo.getAll().single.currency, isNull);
      expect(repo.getAll().single.liters, 26);
    });

    test('a pre-#4136 legacy record is not labelled by an edit', () async {
      // Same fact as above: no currency was ever recorded. `FillUp
      // .currency` documents null as unknown, so stamping today's on
      // an incidental re-save is the very mislabel #4136 fought.
      await storage.putSetting(StorageKeys.consumptionLog, [
        _make(id: 'legacy').toJson()..remove('currency'),
      ]);
      await repo.save(repo.getAll().single.copyWith(odometerKm: 11000));
      expect(repo.getAll().single.currency, isNull);
    });
  });

  test('getAll tolerates malformed raw entries without crashing', () async {
    // Simulate a previous corrupted store
    await storage.putSetting(StorageKeys.consumptionLog, [
      'not-a-map',
      42,
      _make(id: 'ok').toJson(),
    ]);
    final all = repo.getAll();
    expect(all.length, 1);
    expect(all.first.id, 'ok');
  });

  test('getAll returns empty when stored value is not a list', () async {
    await storage.putSetting(StorageKeys.consumptionLog, 'garbage');
    expect(repo.getAll(), isEmpty);
  });
}
