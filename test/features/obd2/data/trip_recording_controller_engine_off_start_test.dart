// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3858 (Epic #3855) — a recording started with the engine OFF. The bus
// probe is silent and the adapter reads 12.4 V: the controller starts
// GPS-first, sends NO `0100` (the #3575 livelock trigger) and no identity
// reads, keeps the link, dials nothing — and when the voltage watch sees
// the alternator it runs the whole deferred start on the same link.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_reattach_source.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/vehicle_power_state.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

import '../../../helpers/silence_error_logger.dart';

class _Scanner implements Obd2ReattachSource {
  int startCalls = 0;
  @override
  Future<void> start() async => startCalls++;
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

void main() {
  silenceErrorLoggerSpool();
  late Directory tmpDir;
  late Box<String> pausedBox;
  late Box<String> historyBox;
  late PausedTripRepository pausedRepo;
  late TripHistoryRepository historyRepo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('engine_off_start_');
    Hive.init(tmpDir.path);
    // Each test owns a fresh Hive directory, so fixed box names are unique.
    pausedBox = await Hive.openBox<String>('paused');
    historyBox = await Hive.openBox<String>('history');
    pausedRepo = PausedTripRepository(box: pausedBox);
    historyRepo = TripHistoryRepository(box: historyBox);
  });

  tearDown(() async {
    Obd2VehiclePower.instance.reset();
    await pausedBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  /// The parked car: every AT answers, the bus never does, 12.4 V at rest.
  Map<String, String> parkedResponses() => {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
        'ATI': 'ELM327 v1.5>',
        '0100': 'UNABLE TO CONNECT>',
        'ATDPN': 'A0>',
        'ATRV': '12.4V>',
      };

  int sent(FakeObd2Transport t, String cmd) =>
      t.sentCommands.where((c) => c == cmd).length;

  test('engine off at start: starts GPS-first, no 0100, no identity reads, '
      'no dial; the alternator runs the deferred start', () async {
    final responses = parkedResponses();
    final transport = FakeObd2Transport(responses);
    final svc = Obd2Service(transport);
    await svc.connect();
    await svc.discoverSupportedPids();
    expect(svc.busProbe, Obd2BusProbeResult.probedSilent,
        reason: 'precondition: the dial read a silent bus');
    final probesBeforeStart = sent(transport, '0100');

    var nowValue = DateTime(2026, 8, 29, 20);
    final scanner = _Scanner();
    final ctl = TripRecordingController(
      service: svc,
      pollInterval: const Duration(milliseconds: 60),
      vehicleId: 'car-parked',
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
      pauseGraceWindow: const Duration(hours: 1),
      silentReconnectWindow: Duration.zero,
      pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
      reconnectScannerFactory: (mac, onReconnect) => scanner,
      now: () => nowValue,
    );

    // GPS is alive from the first second — the phone has a fix.
    void gpsFix() => ctl.updateGpsFix(
        latitude: 48.85, longitude: 2.35, hAccuracyM: 8, fixAt: nowValue);
    gpsFix();

    await ctl.start();
    gpsFix();

    expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly,
        reason: 'the recording is RUNNING (GPS), waiting for the engine');
    expect(ctl.dropReason, TripDropReason.engineOff);
    expect(sent(transport, '0100'), probesBeforeStart,
        reason: 'no protocol establishment into a silent bus (#3575)');
    expect(sent(transport, '01A6'), 0, reason: 'no odometer read');
    expect(sent(transport, '0902'), 0, reason: 'no VIN read');
    expect(scanner.startCalls, 0, reason: 'nothing to reattach — no dial');
    expect(svc.isConnected, isTrue, reason: 'the link is kept');
    expect(Obd2VehiclePower.instance.asleep, isTrue,
        reason: '12.4 V + silent bus = asleep');

    // Let a few emit ticks pass parked: still waiting, still no bus traffic.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);
    expect(sent(transport, '0100'), probesBeforeStart);

    // The driver turns the key: the alternator lifts the voltage and the
    // bus answers. The next voltage-watch read (10 s cadence) sees it.
    responses['ATRV'] = '14.2V>';
    responses['0100'] = '41 00 BE 3E B8 11>';
    responses['ATDPN'] = 'A6>';
    nowValue = nowValue.add(const Duration(seconds: 11));
    gpsFix();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(Obd2VehiclePower.instance.engineRunning, isTrue,
        reason: 'engineRunning via voltage');
    expect(ctl.currentState, TripRecordingControllerState.recording,
        reason: 'the engine transition resumed on the same link — no dial');
    expect(ctl.dropReason, isNull);
    expect(sent(transport, '0100'), greaterThan(probesBeforeStart),
        reason: 'the deferred protocol establishment ran NOW');
    expect(scanner.startCalls, 0);

    await ctl.stop();
  });

  test('a silent probe WITH the alternator on (the #3780 livelock shape) '
      'starts the ordinary way — never the engine-off wait', () async {
    final responses = parkedResponses()..['ATRV'] = '14.1V>';
    final transport = FakeObd2Transport(responses);
    final svc = Obd2Service(transport);
    await svc.connect();
    await svc.discoverSupportedPids();
    expect(svc.busProbe, Obd2BusProbeResult.probedSilent);

    final ctl = TripRecordingController(
      service: svc,
      pollInterval: const Duration(minutes: 1),
      vehicleId: 'car-livelock',
      pausedRepo: pausedRepo,
      historyRepo: historyRepo,
      pauseGraceWindow: const Duration(hours: 1),
      silentReconnectWindow: Duration.zero,
      pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
      reconnectScannerFactory: (mac, onReconnect) => _Scanner(),
    );

    await ctl.start();

    expect(ctl.dropReason, isNot(TripDropReason.engineOff),
        reason: 'an alternator at 14 V is a running engine whatever the '
            'bus says — the silent verdict is the livelock, not a parked car');
    expect(ctl.currentState, TripRecordingControllerState.recording);
    await ctl.stop();
  });
}
