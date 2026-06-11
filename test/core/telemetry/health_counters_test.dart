// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/health_counters.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('health_counters_test_');
    Hive.init(tempDir.path);
    await HealthCounters.init();
  });

  tearDown(() async {
    healthCounters.resetForTest();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  HealthCounters counters({DateTime? at}) =>
      HealthCounters(clock: () => at ?? DateTime.utc(2026, 6, 10, 12));

  group('increment + flush (#3146)', () {
    test('flush persists the pending deltas under the day key', () async {
      final c = counters();
      c.increment('api.de.ok');
      c.increment('api.de.ok');
      c.increment('sync.favorites.failures', by: 3);

      await c.flush();

      final row = Hive.box(HealthCounters.boxName).get('2026-06-10') as Map;
      expect(row['api.de.ok'], 2);
      expect(row['sync.favorites.failures'], 3);
    });

    test('flush merges into an existing day row instead of replacing it',
        () async {
      final c = counters();
      c.increment('ble.connect.attempts');
      await c.flush();
      c.increment('ble.connect.attempts');
      c.increment('ble.connect.successes');
      await c.flush();

      final row = Hive.box(HealthCounters.boxName).get('2026-06-10') as Map;
      expect(row['ble.connect.attempts'], 2);
      expect(row['ble.connect.successes'], 1);
    });

    test('increment arms the debounced auto-flush once', () {
      final c = counters();
      expect(c.hasScheduledFlush, isFalse);
      c.increment('api.de.ok');
      expect(c.hasScheduledFlush, isTrue);
      c.increment('api.de.ok');
      expect(c.hasScheduledFlush, isTrue);
      c.resetForTest();
    });

    test('flush prunes day rows older than the retention window', () async {
      final box = Hive.box(HealthCounters.boxName);
      await box.put('2026-01-01', {'api.de.ok': 9});
      await box.put('2026-06-09', {'api.de.ok': 1});

      final c = counters(); // clock = 2026-06-10
      c.increment('api.de.ok');
      await c.flush();

      expect(box.get('2026-01-01'), isNull,
          reason: 'rows older than retainDays must be pruned on flush');
      expect(box.get('2026-06-09'), isNotNull,
          reason: 'rows inside the window must be kept');
    });
  });

  group('exportSnapshot', () {
    test('merges persisted rows with the still-pending deltas', () async {
      final c = counters();
      c.increment('api.es.staleFallbacks');
      await c.flush();
      c.increment('api.es.staleFallbacks'); // pending, not yet flushed

      final snapshot = c.exportSnapshot();
      final days = snapshot['days'] as Map;
      final today = days['2026-06-10'] as Map;
      expect(today['api.es.staleFallbacks'], 2);
      c.resetForTest();
    });

    test('rides inside TraceStorage.exportAsJson under diagnostics',
        () async {
      await TraceStorage.init();
      healthCounters.increment('api.de.failures');

      final raw = TraceStorage().exportAsJson();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final diagnostics = decoded['diagnostics'] as Map<String, dynamic>;
      final counters = diagnostics['healthCounters'] as Map<String, dynamic>;
      final days = counters['days'] as Map<String, dynamic>;
      expect(
        days.values.any((row) => (row as Map)['api.de.failures'] == 1),
        isTrue,
        reason: 'a pending increment must be visible in the export',
      );
    });
  });

  group('never-throws contract (fault injection)', () {
    test('increment/flush/exportSnapshot return normally on a clock fault',
        () async {
      final c = HealthCounters(clock: () => throw StateError('clock fault'));
      expect(() => c.increment('api.de.ok'), returnsNormally);
      await expectLater(c.flush(), completes);
      expect(c.exportSnapshot, returnsNormally);
      c.resetForTest();
    });

    test('flush with the box closed keeps the deltas pending and completes',
        () async {
      final c = counters();
      c.increment('api.de.ok');
      await Hive.box(HealthCounters.boxName).close();

      await expectLater(c.flush(), completes);

      // Re-open: the pending delta survives to the next flush.
      await HealthCounters.init();
      await c.flush();
      final row = Hive.box(HealthCounters.boxName).get('2026-06-10') as Map;
      expect(row['api.de.ok'], 1);
    });

    test('increment with Hive entirely closed returns normally', () async {
      await Hive.close();
      final c = counters();
      expect(() => c.increment('api.de.ok'), returnsNormally);
      expect(c.exportSnapshot, returnsNormally);
    });

    test('flush skips malformed persisted rows without throwing', () async {
      final box = Hive.box(HealthCounters.boxName);
      await box.put('2026-06-10', 'not-a-map');

      final c = counters();
      c.increment('api.de.ok');
      await expectLater(c.flush(), completes);

      final row = box.get('2026-06-10') as Map;
      expect(row['api.de.ok'], 1,
          reason: 'a malformed row is replaced by a fresh counted row');
    });
  });
}
