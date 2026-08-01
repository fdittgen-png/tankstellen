// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2_fuel_level_snapshot_store.dart';

class _NoopRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  noSuchMethod(Invocation invocation) => null;
}

/// In-memory [SettingsStorage] — can be told to throw so the store's
/// never-throws contract is fault-injected, not assumed.
class _FakeSettings implements SettingsStorage {
  _FakeSettings({this.throws = false});

  final bool throws;
  final Map<String, dynamic> map = {};

  @override
  dynamic getSetting(String key) {
    if (throws) throw StateError('settings box unavailable');
    return map[key];
  }

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (throws) throw StateError('settings box unavailable');
    map[key] = value;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => errorLogger.testRecorderOverride = _NoopRecorder());
  tearDown(() => errorLogger.resetForTest());

  group('Obd2FuelLevelSnapshotStore (#3647)', () {
    test('write → read round-trips litres and timestamp per vehicle', () async {
      final settings = _FakeSettings();
      final store = Obd2FuelLevelSnapshotStore(settings);

      await store.write(
        'v1',
        Obd2FuelLevelSnapshot(liters: 31.5, at: DateTime(2026, 8, 1, 20, 6)),
      );
      await store.write(
        'v2',
        Obd2FuelLevelSnapshot(liters: 12.0, at: DateTime(2026, 8, 2)),
      );

      final v1 = store.read('v1');
      expect(v1, isNotNull);
      expect(v1!.liters, 31.5);
      expect(v1.at, DateTime(2026, 8, 1, 20, 6));
      expect(store.read('v2')!.liters, 12.0);
    });

    test('never captured → null', () {
      expect(
        Obd2FuelLevelSnapshotStore(_FakeSettings()).read('v1'),
        isNull,
      );
    });

    test('malformed entries read as null, never throw', () {
      final settings = _FakeSettings();
      final store = Obd2FuelLevelSnapshotStore(settings);
      const key = 'obd2_fuel_level_snapshot_v1';

      for (final bad in [
        'not json',
        '[]',
        '{"l": "NaN-ish", "at": 5}',
        '{"l": 5}',
        '{"l": -3, "at": 5}',
        42,
      ]) {
        settings.map[key] = bad;
        expect(() => store.read('v1'), returnsNormally, reason: '$bad');
        expect(store.read('v1'), isNull, reason: '$bad');
      }
    });

    test('a throwing settings box degrades: read → null, write completes '
        '(never throws — the next reading overwrites anyway)', () async {
      final store = Obd2FuelLevelSnapshotStore(_FakeSettings(throws: true));

      expect(() => store.read('v1'), returnsNormally);
      expect(store.read('v1'), isNull);
      await expectLater(
        store.write(
          'v1',
          Obd2FuelLevelSnapshot(liters: 20, at: DateTime(2026, 8, 1)),
        ),
        completes,
      );
    });
  });
}
