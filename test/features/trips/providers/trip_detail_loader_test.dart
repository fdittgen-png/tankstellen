// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3882 — the trip-detail loader decodes the full trip off the UI isolate
// (loading → data), serves list fixtures synchronously when no box is
// open (widget tests), and re-decodes only when the trip's own identity
// (sample count / verdict) changes — never on an unrelated list refresh.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/domain/trip_verdict.dart';
import 'package:tankstellen/features/trips/providers/trip_history_provider.dart';

final _t0 = DateTime(2026, 8, 30, 9);

TripHistoryEntry _entry(String id, int n) => TripHistoryEntry(
      id: id,
      vehicleId: 'car',
      summary: TripSummary(
          distanceKm: 3,
          maxRpm: 2000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
          startedAt: _t0),
      samples: [
        for (var i = 0; i < n; i++)
          TripSample(
              timestamp: _t0.add(Duration(seconds: i)),
              speedKmh: 20.0 + i,
              fuelRateLPerHour: 2.0),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no repository → the list fixture is served synchronously', () async {
    final container = ProviderContainer(overrides: [
      tripHistoryRepositoryProvider.overrideWithValue(null),
      tripHistoryListProvider.overrideWith(() => _FixedList([_entry('a', 3)])),
    ]);
    addTearDown(container.dispose);
    final v = container.read(tripDetailLoaderProvider('a'));
    expect(v.hasValue, isTrue);
    expect(v.value!.samples, hasLength(3));
    expect(container.read(tripSpeedFuelSamplesProvider('a')), hasLength(3));
  });

  group('with a box', () {
    late Directory dir;
    late ProviderContainer container;
    setUp(() async {
      dir = Directory.systemTemp.createTempSync('trip_loader_');
      Hive.init(dir.path);
      await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
      container = ProviderContainer();
    });
    tearDown(() async {
      container.dispose();
      await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('loading → full entry; an unrelated list refresh does not '
        're-decode; a verdict on THIS trip does', () async {
      final repo = container.read(tripHistoryRepositoryProvider)!;
      await repo.save(_entry('a', 700));
      await repo.save(_entry('b', 5));
      container.read(tripHistoryListProvider.notifier).refresh();

      final seen = <AsyncValue<TripHistoryEntry?>>[];
      container.listen(tripDetailLoaderProvider('a'), (_, next) => seen.add(next),
          fireImmediately: true);
      expect(seen.single.isLoading, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(seen.last.value!.samples, hasLength(700));
      expect(seen.last.value!.columnsPresent, contains('f'));
      final decodes = seen.length;

      // Unrelated: delete trip b → list refreshes, 'a' is untouched.
      await container.read(tripHistoryListProvider.notifier).delete('b');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(seen.length, decodes, reason: 'no re-decode of a');

      // Related: verdict on 'a' → identity changed → re-decode.
      await container
          .read(tripHistoryListProvider.notifier)
          .setVerdict('a', TripVerdict.smooth);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(seen.length, greaterThan(decodes));
      expect(seen.last.value!.verdict, TripVerdict.smooth.wireName);

      // Column reader: two columns, same length.
      expect(container.read(tripSpeedFuelSamplesProvider('a')), hasLength(700));
    });
  });
}

class _FixedList extends TripHistoryList {
  _FixedList(this._entries);
  final List<TripHistoryEntry> _entries;
  @override
  List<TripHistoryEntry> build() => _entries;
}
