// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_trip_history_index.dart';
import 'package:tankstellen/core/storage/hive_box_mutation_epoch.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/data/trip_history_store_v2.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import '../../../helpers/hive_temp_dir.dart';

class GateBox implements LazyBox<String> {
  GateBox(this.actual);
  final LazyBox<String> actual;
  int reads = 0;
  int writes = 0;
  int pauseRead = -1;
  int failWrite = -1;
  int pauseWrite = -1;
  final writeReached = Completer<void>();
  final writeRelease = Completer<void>();
  final reached = Completer<void>();
  final release = Completer<void>();
  @override
  Iterable<dynamic> get keys => actual.keys;
  @override
  bool containsKey(dynamic key) => actual.containsKey(key);
  @override
  Future<String?> get(dynamic key, {String? defaultValue}) async {
    final result = await actual.get(key, defaultValue: defaultValue);
    reads++;
    if (reads == pauseRead) {
      reached.complete();
      await release.future;
    }
    return result;
  }

  @override
  Future<void> putAll(Map<dynamic, String> rows) async {
    writes++;
    if (writes == failWrite) throw StateError('injected I/O failure');
    if (writes == pauseWrite) {
      writeReached.complete();
      await writeRelease.future;
    }
    await actual.putAll(rows);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) => actual.deleteAll(keys);
  @override
  Future<int> clear() => actual.clear();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ContentionBox extends GateBox {
  ContentionBox(super.actual);
  bool conflict = false;
  late HiveTripHistoryIndex index;
  @override
  Future<String?> get(dynamic key, {String? defaultValue}) async {
    final raw = await super.get(key, defaultValue: defaultValue);
    if (conflict && key == 'trip') {
      await index.putAll({'noise': jsonEncode(entry('noise').toJson())});
    }
    return raw;
  }
}

TripHistoryEntry entry(String id, {int count = 0, double speed = 40}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: null,
      summary: const TripSummary(
        distanceKm: 10,
        maxRpm: 2000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      samples: [
        for (var i = 0; i < count; i++)
          TripSample(
            timestamp: DateTime(2026, 1, 1).add(Duration(seconds: i)),
            speedKmh: speed,
            fuelRateLPerHour: 3,
          ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late LazyBox<String> actual;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('startup-review-race');
    Hive.init(dir.path);
    actual = await Hive.openLazyBox<String>(
      'history',
      encryptionCipher: HiveAesCipher(List.generate(32, (i) => i)),
    );
  });
  tearDown(() async {
    await closeHiveAndDeleteTemp(dir);
  });

  test(
    'full export fails visibly instead of omitting a contended healthy trip',
    () async {
      final box = ContentionBox(actual);
      await HiveTripHistoryIndex.prepare(box);
      box.index = HiveTripHistoryIndex.of(box);
      final repo = TripHistoryRepository.lazy(box: box);
      await repo.save(entry('trip', count: 650));
      box.conflict = true;
      await expectLater(
        repo.loadAllAsync(),
        throwsA(isA<HiveBoxSnapshotConflict>()),
      );
      expect(actual.containsKey('trip'), isTrue);
      box.conflict = false;
      expect((await repo.loadAllAsync()).map((e) => e.id), contains('trip'));
    },
  );

  test('a snapshot waits for an already-started canonical write', () async {
    await actual.putAll(encodeTripRowsV2(entry('trip', count: 650).toJson()));
    final box = GateBox(actual);
    await HiveTripHistoryIndex.prepare(box);
    box.reads = 0;
    box.pauseWrite = 1;
    final repo = TripHistoryRepository.lazy(box: box);
    final saving = repo.save(entry('trip', count: 650, speed: 80));
    await box.writeReached.future;
    final reading = repo.loadByIdAsync('trip');
    expect(box.reads, 0, reason: 'do not read a partially committed version');
    box.writeRelease.complete();
    expect(await saving, isTrue);
    expect((await reading)!.samples.map((s) => s.speedKmh).toSet(), {80.0});
  });

  test(
    'clear during chunk collection discards the entire old snapshot',
    () async {
      await actual.putAll(encodeTripRowsV2(entry('trip', count: 650).toJson()));
      final box = GateBox(actual);
      await HiveTripHistoryIndex.prepare(box);
      box.reads = 0;
      box.pauseRead = 2;
      final repo = TripHistoryRepository.lazy(box: box);
      final reading = repo.loadByIdAsync('trip');
      await box.reached.future;
      await repo.clearAll();
      box.release.complete();
      expect(await reading, isNull);
      expect(repo.loadSummaries(), isEmpty);
    },
  );

  test('a migration snapshot must not resurrect a later deletion', () async {
    await actual.put('legacy', jsonEncode(entry('legacy').toJson()));
    final box = GateBox(actual);
    await HiveTripHistoryIndex.prepare(box);
    box.reads = 0;
    box.pauseRead = 1;
    final repo = TripHistoryRepository.lazy(box: box);
    final migrating = repo.migrateLegacyRow('legacy');
    await box.reached.future;
    await repo.delete('legacy');
    expect(actual.containsKey('legacy'), isFalse);
    box.release.complete();
    await migrating;
    expect(
      actual.containsKey('legacy'),
      isFalse,
      reason: 'the user deleted after the initial read captured its old frame',
    );
  });

  test(
    'async detail read must not mix chunks from two saved versions',
    () async {
      final box = GateBox(actual);
      await HiveTripHistoryIndex.prepare(box);
      final repo = TripHistoryRepository.lazy(box: box);
      await repo.save(entry('trip', count: 650, speed: 40));
      box.reads = 0;
      box.pauseRead = 2; // meta, then first chunk captured from the old row
      final loading = repo.loadByIdAsync('trip');
      await box.reached.future;
      await repo.save(entry('trip', count: 650, speed: 80));
      box.release.complete();
      final loaded = (await loading)!;
      expect(
        loaded.samples.map((s) => s.speedKmh).toSet(),
        hasLength(1),
        reason: 'one trip must represent one saved version, not old+new chunks',
      );
    },
  );

  test(
    'failed later write must not suppress an earlier durable projection',
    () async {
      final box = GateBox(actual);
      await HiveTripHistoryIndex.prepare(box);
      final index = HiveTripHistoryIndex.of(box);
      box.failWrite = 2;
      final first = index.putAll({'trip': jsonEncode(entry('trip').toJson())});
      await expectLater(
        index.putAll({'trip': 'newer write fails'}),
        throwsStateError,
      );
      await first;
      expect(await actual.get('trip'), isNotNull);
      expect(
        index.get('trip'),
        isNotNull,
        reason: 'metadata must describe the successfully persisted first write',
      );
    },
  );
}
