// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3867 (Epic #3865, GDPR Art. 17) — the local erasure is registry-driven:
// every Hive box constant declared in `hive_boxes.dart` must be a member
// of `HiveBoxes.allBoxes`, otherwise "Delete all data" would silently
// leave it on the device — exactly the defect this epic fixed (recorded
// GPS trips, OBD2 baselines, alerts, VIN/MAC-keyed caches survived it).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/local_data_eraser.dart';

import '../../fakes/fake_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every box constant in hive_boxes.dart is in HiveBoxes.allBoxes',
      () {
    final source = File('lib/core/storage/hive_boxes.dart').readAsStringSync();
    final declared = RegExp(r"static const String \w+ = '([a-z0-9_]+)';")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    expect(declared, isNotEmpty);
    final missing = declared.difference(HiveBoxes.allBoxes);
    expect(missing, isEmpty,
        reason: 'box(es) declared but not registered for erasure: $missing '
            '— add them to HiveBoxes.allBoxes (and the export, #3869)');
  });

  test('the error-trace box name matches TraceStorage', () {
    final source =
        File('lib/core/telemetry/storage/trace_storage.dart').readAsStringSync();
    expect(source, contains("'${HiveBoxes.errorTraces}'"));
  });

  group('eraseAll', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('eraser_');
      Hive.init(dir.path);
    });
    tearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });

    test('clears every open box and deletes closed ones from disk',
        () async {
      final open = await Hive.openBox<dynamic>(HiveBoxes.obd2TripHistory);
      await open.put('trip-1', '{"gps": true}');
      final closed = await Hive.openBox<dynamic>(HiveBoxes.serviceReminders);
      await closed.put('r', 1);
      await closed.close();
      expect(await Hive.boxExists(HiveBoxes.serviceReminders), isTrue);

      // A registry-driven wipe with no storage repository side effects:
      // exercise the box phase alone through the public entry point.
      final result = await LocalDataEraser.eraseBoxesForTest();

      expect(open.isEmpty, isTrue, reason: 'open boxes are cleared in place');
      expect(await Hive.boxExists(HiveBoxes.serviceReminders), isFalse,
          reason: 'closed boxes are deleted from disk');
      expect(result.complete, isTrue, reason: result.failedSteps.toString());
    });
  });

  test('a throwing extra wipe is reported, not propagated (never-throws)',
      () async {
    final dir = Directory.systemTemp.createTempSync('eraser_fault_');
    Hive.init(dir.path);
    addTearDown(() async {
      await Hive.close();
      dir.deleteSync(recursive: true);
    });
    final result = await LocalDataEraser.eraseAll(
      storage: FakeStorageRepository(),
      extraWipes: [() async => throw StateError('widget host gone')],
    );
    expect(result.complete, isFalse);
    expect(result.failedSteps, contains('extra:0'));
  });
}
