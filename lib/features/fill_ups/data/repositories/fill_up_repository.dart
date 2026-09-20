// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';


import '../../../../core/data/storage_repository.dart';
import '../../../../core/storage/hive_map_coercion.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../domain/entities/fill_up.dart';
import '../../domain/fill_up_currency.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/utils/price_formatter.dart';

/// Repository for CRUD operations on [FillUp] records.
///
/// Persists as a simple list under [StorageKeys.consumptionLog] in the
/// existing settings box — adding a dedicated Hive box is overkill for
/// a small, user-owned log.
class FillUpRepository {
  final SettingsStorage _storage;

  FillUpRepository(this._storage);

  static const String _key = StorageKeys.consumptionLog;

  /// Returns all stored fill-ups, newest first.
  List<FillUp> getAll() {
    final raw = _storage.getSetting(_key);
    if (raw == null) return const [];
    if (raw is! List) return const [];

    final result = <FillUp>[];
    for (final item in raw) {
      final map = toStringDynamicMap(item);
      if (map == null) continue;
      try {
        result.add(FillUp.fromJson(map));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'FillUpRepository: skipping malformed entry'}));
      }
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Add or update a single fill-up (matched by id).
  ///
  /// #4136 — labels a record that has none, so a history that later
  /// spans two currencies can be told apart instead of silently summed.
  /// Done HERE rather than in the form: the currency is a property of
  /// the record, not of one screen, and every creation path (manual
  /// entry, receipt scan, a future importer) goes through this.
  ///
  /// A record that ALREADY carries one keeps it — a backup restored in
  /// another country must not be relabelled with today's currency.
  ///
  /// #4428 — the label is now decided from the fill's own evidence by
  /// [resolveFillUpCurrency], not from wherever the profile points. The
  /// active currency used to be stamped unconditionally, which stored a
  /// CHF 51,73 Swiss fill as EUR 51,73 under an EUR profile. When the
  /// evidence says the driver was somewhere else and gives no way to
  /// name the currency, the record stays **unknown** (null) rather than
  /// carrying a confident wrong label.
  ///
  /// [observedCountryCode] is where the device believes it is right
  /// now. Pass it only where that is evidence about THIS record — a
  /// fresh entry the driver is logging. An import, a sync merge or a
  /// re-save of an old row must leave it null: today's location says
  /// nothing about a fill from last year.
  ///
  /// The label is decided ONCE, when the record is first written. A
  /// row that is already in the log keeps whatever it has, **null
  /// included**: a deliberate unknown (#4428) and a pre-#4136 legacy
  /// record are the same fact — no currency was ever recorded — and an
  /// incidental re-save (a trip re-link, a swipe-undo, an edit) is not
  /// the moment to invent one.
  Future<void> save(FillUp rawFillUp, {String? observedCountryCode}) async {
    final all = [...getAll()];
    final index = all.indexWhere((f) => f.id == rawFillUp.id);
    final fillUp = index >= 0
        ? rawFillUp
        : _labelled(rawFillUp, observedCountryCode: observedCountryCode);
    if (index >= 0) {
      all[index] = fillUp;
    } else {
      all.add(fillUp);
    }
    await _writeAll(all);
  }

  /// [fillUp] with the currency its own evidence supports, or unchanged
  /// when that evidence names none — freezed's `copyWith` cannot write
  /// null, and leaving the field alone is exactly the right outcome.
  FillUp _labelled(FillUp fillUp, {String? observedCountryCode}) {
    final resolved = resolveFillUpCurrency(
      recordedCurrency: fillUp.currency,
      stationId: fillUp.stationId,
      observedCountryCode: observedCountryCode,
      profileCountryCode: PriceFormatter.activeCountry,
      profileCurrency: PriceFormatter.currencyCode,
    );
    return resolved == null ? fillUp : fillUp.copyWith(currency: resolved);
  }

  /// Delete a fill-up by id.
  Future<void> delete(String id) async {
    final all = [...getAll()]..removeWhere((f) => f.id == id);
    await _writeAll(all);
  }

  /// Remove all stored fill-ups.
  Future<void> clear() => _storage.putSetting(_key, <Map<String, dynamic>>[]);

  Future<void> _writeAll(List<FillUp> list) async {
    final json = list.map((f) => f.toJson()).toList();
    await _storage.putSetting(_key, json);
  }
}
