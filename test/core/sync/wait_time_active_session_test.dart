import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/sync/wait_time_active_session.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';

/// Round-trip + auto-expire tests for [WaitTimeActiveSessionStore]
/// (#1119 phase 2). Uses a real Hive box rooted in a per-test temp
/// dir — same pattern as `hive_storage_test.dart`.
void main() {
  late Directory tempDir;
  late WaitTimeActiveSessionStore store;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('wait_time_active_session_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.settings);
    store = WaitTimeActiveSessionStore();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('round-trip', () {
    test('start → read returns the same session', () async {
      final ts = DateTime.utc(2026, 5, 6, 14, 30);
      final session = WaitTimeActiveSession(
        sessionId: 'sess-abc',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: ts,
      );
      await store.start(session);
      final read = store.read(now: ts.add(const Duration(minutes: 5)));
      expect(read, isNotNull);
      expect(read!.sessionId, 'sess-abc');
      expect(read.stationId, 'st-1');
      expect(read.countryCode, 'DE');
      expect(read.arrivedAt, ts);
    });

    test('clear empties the store', () async {
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-1',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: DateTime.utc(2026, 5, 6, 14, 30),
      ));
      await store.clear();
      final read = store.read();
      expect(read, isNull);
    });

    test('start overwrites a previous session', () async {
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-1',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: DateTime.utc(2026, 5, 6, 14, 30),
      ));
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-2',
        stationId: 'st-2',
        countryCode: 'FR',
        arrivedAt: DateTime.utc(2026, 5, 6, 14, 31),
      ));
      final read = store.read(now: DateTime.utc(2026, 5, 6, 14, 35));
      expect(read?.sessionId, 'sess-2');
      expect(read?.stationId, 'st-2');
      expect(read?.countryCode, 'FR');
    });
  });

  group('auto-expire', () {
    test('reads as null past the 1h window', () async {
      final ts = DateTime.utc(2026, 5, 6, 14, 30);
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-stale',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: ts,
      ));
      // 1h + 1s past arrival → stale
      final read = store.read(
        now: ts.add(const Duration(hours: 1, seconds: 1)),
      );
      expect(read, isNull);
    });

    test('reads OK at exactly 59m59s past arrival', () async {
      final ts = DateTime.utc(2026, 5, 6, 14, 30);
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-fresh',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: ts,
      ));
      final read = store.read(
        now: ts.add(const Duration(minutes: 59, seconds: 59)),
      );
      expect(read, isNotNull);
      expect(read!.sessionId, 'sess-fresh');
    });

    test('stale entry is cleaned on read so the next read is also null',
        () async {
      final ts = DateTime.utc(2026, 5, 6, 14, 30);
      await store.start(WaitTimeActiveSession(
        sessionId: 'sess-stale',
        stationId: 'st-1',
        countryCode: 'DE',
        arrivedAt: ts,
      ));
      // First read past 1h → null + drop.
      expect(
        store.read(now: ts.add(const Duration(hours: 2))),
        isNull,
      );
      // Second read with the live wall-clock now sees a clean store.
      expect(store.read(), isNull);
    });
  });

  group('malformed entry tolerance', () {
    test('a corrupt JSON blob reads as null and clears', () async {
      // Inject a non-JSON string directly into the box.
      await Hive.box(HiveBoxes.settings)
          .put('wait_time_active_session', 'not-valid-json{');
      final read = store.read();
      expect(read, isNull);
    });

    test('a missing-field JSON blob reads as null', () async {
      // Valid JSON but with missing keys.
      await Hive.box(HiveBoxes.settings).put(
        'wait_time_active_session',
        '{"sessionId": "x"}',
      );
      final read = store.read();
      expect(read, isNull);
    });
  });
}
