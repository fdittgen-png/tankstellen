// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3877 — the odometer is re-read every few minutes while the engine runs
// (one PID, no stalls on a car that never answered), and the controller
// exposes reading + distance-since so the stop can estimate the end km.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

import '../../../helpers/silence_error_logger.dart';

class _Scanner implements Obd2ReattachSource {
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  set onPassiveWait(VoidCallback? callback) {}

  @override
  set adoptionGate(Obd2AdoptionGate? gate) {}
  @override
  bool get isPassiveWaiting => false;
  @override
  int get currentAttemptNumber => 0;
  @override
  int get currentBackoffMs => 0;
}

/// 41 A6 + 4 bytes = odometer × 10 km.
String _odo(int km) {
  final v = km * 10;
  final b = [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff]
      .map((x) => x.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
  return '41 A6 $b>';
}

void main() {
  silenceErrorLoggerSpool();
  late Directory tmpDir;
  late Box<String> pausedBox;
  late Box<String> historyBox;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('odo_refresh_');
    Hive.init(tmpDir.path);
    pausedBox = await Hive.openBox<String>('paused');
    historyBox = await Hive.openBox<String>('history');
    // The supported-PID / protocol caches the discovery writes to.
    await Hive.openBox<String>(HiveBoxes.obd2SupportedPids);
    await Hive.openBox<String>(HiveBoxes.obd2NegotiatedProtocol);
  });
  tearDown(() async {
    Obd2VehiclePower.instance.reset();
    await pausedBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  Map<String, String> runningCar(int odoKm) => {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        'ATI': 'ELM327 v1.5>',
        '0100': '41 00 BE 3E B8 11>',
        'ATDPN': 'A6>',
        'ATRV': '14.2V>',
        '01A6': _odo(odoKm),
        '010C': '41 0C 1A F8>', // rpm 1726
        '010D': '41 0D 32>', // 50 km/h
      };

  int sent(FakeObd2Transport t, String cmd) =>
      t.sentCommands.where((c) => c == cmd).length;

  test('start reads the odometer once; a refresh lands only after the '
      'interval while the engine runs; the estimate adds the distance since',
      () async {
    final responses = runningCar(100000);
    final transport = FakeObd2Transport(responses);
    final svc = Obd2Service(transport);
    await svc.connect();
    await svc.discoverSupportedPids();

    var nowValue = DateTime(2026, 8, 29, 9);
    final ctl = TripRecordingController(
      service: svc,
      pollInterval: const Duration(milliseconds: 60),
      vehicleId: 'car-odo',
      pausedRepo: PausedTripRepository(box: pausedBox),
      historyRepo: TripHistoryRepository(box: historyBox),
      pauseGraceWindow: const Duration(hours: 1),
      silentReconnectWindow: Duration.zero,
      pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
      reconnectScannerFactory: (mac, onReconnect) => _Scanner(),
      now: () => nowValue,
      // A scheduler that never ticks: the fake car answers no polled PID,
      // and 50 null parses would otherwise read as a silent failure.
      scheduler: PidScheduler(
          transport: svc.sendCommand, tickRate: const Duration(hours: 1)),
    );
    await ctl.start();
    expect(ctl.odometerStartKm, 100000);
    expect(ctl.odometerLatestAt, nowValue);
    expect(ctl.distanceKmAtOdometerLatest, 0);
    final readsAfterStart = sent(transport, '01A6');

    // A minute of driving: no re-read yet (interval is 5 min).
    nowValue = nowValue.add(const Duration(minutes: 1));
    // Keep the #3602 staleness fence fed: the car answers rpm as it drives.
    ctl.debugObserveHighPriorityParse(1726.0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(sent(transport, '01A6'), readsAfterStart,
        reason: 'no re-read inside the interval');

    // Past the interval, the car has moved on: ONE re-read lands.
    responses['01A6'] = _odo(100004);
    nowValue = nowValue.add(const Duration(minutes: 5));
    ctl.debugObserveHighPriorityParse(1726.0);
    // The start-time protocol quiet window may still own the link for a
    // couple of seconds; the refresh waits for it.
    await Future<void>.delayed(const Duration(seconds: 3));
    expect(ctl.currentState, TripRecordingControllerState.recording,
        reason: 'power=${Obd2VehiclePower.instance.detail}');
    expect(sent(transport, '01A6'), readsAfterStart + 1,
        reason: 'exactly one refresh per interval');
    expect(ctl.odometerLatestKm, 100004);
    expect(ctl.odometerLatestAt, nowValue);
    // Real delta start→latest = 4 km, so the distance stamp is 4.
    expect(ctl.distanceKmAtOdometerLatest, closeTo(4, 0.2));
    expect(ctl.estimatedOdometerNowKm, closeTo(100004, 0.2),
        reason: 'nothing driven since the reading → the reading itself');

    await ctl.stop();
  });

  test('a car that never answered at start is never re-asked', () async {
    final responses = runningCar(0)..remove('01A6');
    final transport = FakeObd2Transport(responses);
    final svc = Obd2Service(transport);
    await svc.connect();
    await svc.discoverSupportedPids();
    var nowValue = DateTime(2026, 8, 29, 9);
    final ctl = TripRecordingController(
      service: svc,
      pollInterval: const Duration(milliseconds: 60),
      vehicleId: 'car-noodo',
      pausedRepo: PausedTripRepository(box: pausedBox),
      historyRepo: TripHistoryRepository(box: historyBox),
      pauseGraceWindow: const Duration(hours: 1),
      silentReconnectWindow: Duration.zero,
      pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
      reconnectScannerFactory: (mac, onReconnect) => _Scanner(),
      now: () => nowValue,
      // A scheduler that never ticks: the fake car answers no polled PID,
      // and 50 null parses would otherwise read as a silent failure.
      scheduler: PidScheduler(
          transport: svc.sendCommand, tickRate: const Duration(hours: 1)),
    );
    await ctl.start();
    expect(ctl.odometerStartKm, isNull);
    final readsAfterStart = sent(transport, '01A6');
    nowValue = nowValue.add(const Duration(minutes: 12));
    ctl.debugObserveHighPriorityParse(1726.0);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(sent(transport, '01A6'), readsAfterStart,
        reason: 'no periodic stall on a car without an odometer PID');
    expect(ctl.estimatedOdometerNowKm, isNull);
    await ctl.stop();
  });
}
