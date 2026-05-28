// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import '../../../helpers/silence_error_logger.dart';

/// Regression tests for #1923 — `_saveToHistory` must discard stub
/// trips so they never clutter trip history.
///
/// The pre-#1923 guard required *both* `distanceKm < 0.01` AND
/// `startedAt == null`, so a 0 km false-start that did capture a few
/// idle samples (`startedAt` set) was still persisted. Real device
/// backups showed several such stubs — e.g. a 20-second 0 km entry
/// alongside the real drive.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_stub_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('a trip that captured samples but covered 0 km is NOT persisted',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);

    final ctl = notifier.debugController;
    expect(ctl, isNotNull);
    // Six stationary samples — the recorder gets a `startedAt`, but the
    // integrated distance stays 0. A false-start: recording ran while
    // the car never moved.
    final start = DateTime(2026, 5, 18, 8);
    for (var i = 0; i < 6; i++) {
      ctl!.debugInjectSample(
        speedKmh: 0,
        rpm: 800,
        at: start.add(Duration(seconds: i)),
      );
    }
    await notifier.stop();

    final repo = container.read(tripHistoryRepositoryProvider);
    expect(repo, isNotNull);
    expect(repo!.loadAll(), isEmpty,
        reason: 'a 0 km stub trip must not be written to history');
  });

  test('a trip that captured no samples at all is NOT persisted', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);
    // Stop immediately — the recorder never received a sample, so the
    // summary has a null `startedAt`.
    await notifier.stop();

    final repo = container.read(tripHistoryRepositoryProvider);
    expect(repo!.loadAll(), isEmpty,
        reason: 'a 0-sample stub trip must not be written to history');
  });

  test('a genuine moving trip IS still persisted', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);

    final ctl = notifier.debugController;
    final start = DateTime(2026, 5, 18, 9);
    // 50 km/h for 60 s ≈ 0.83 km — a real drive, well above the
    // 0.01 km stub threshold. `debugInjectSample` gives the recorder a
    // `startedAt`; `debugRecordSpeedSample` feeds the virtual odometer
    // that the finalised summary's `distanceKm` is integrated from.
    for (var i = 0; i <= 60; i++) {
      final at = start.add(Duration(seconds: i));
      ctl!.debugInjectSample(speedKmh: 50, rpm: 2000, at: at);
      ctl.debugRecordSpeedSample(speedKmh: 50, at: at);
    }
    await notifier.stop();

    final repo = container.read(tripHistoryRepositoryProvider);
    expect(repo!.loadAll(), hasLength(1),
        reason: 'a genuine moving trip must still be persisted');
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
