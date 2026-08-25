// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3783 (Epic #3775) — the protocol-establishment gate. With a WARM
// supported-PID cache no `0100` runs at connect time, so the poll
// cadence used to start on a session whose vehicle protocol was never
// negotiated: on a K-line car the first poll triggered the ELM
// auto-search, the cadence interrupted it (#3577 livelock), the #3602
// fence then killed the link mid-recovery, and #3776's ownership seam
// faithfully recycled it — the 2026-08-25 dial-storm spiral (9 dials in
// 2 minutes, 0/191 engine samples). The gate runs ONE quiet-window
// establishment before any polling, at trip start and on every rebind.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

int _boxRunCounter = 0;

void main() {
  group('#3783 protocol-establishment gate', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('protocol_gate_test_');
      Hive.init(tmpDir.path);
      // Unique per-test box names without a raw wall-clock read (#3660).
      final runId = ++_boxRunCounter;
      pausedBox = await Hive.openBox<String>('paused_gate_$runId');
      historyBox = await Hive.openBox<String>('history_gate_$runId');
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    Map<String, String> answeringBus() => {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          // The bus answers the quiet-window probe — protocol negotiable.
          '0100': '41 00 BE 3F A8 13>',
          '01A6': 'NO DATA>',
        };

    test('trip start runs the quiet-window 0100 BEFORE any OBD read '
        '(warm cache ⇒ no probe at connect)', () async {
      final transport = FakeObd2Transport(answeringBus());
      await transport.connect();
      final svc = Obd2Service(transport);
      await svc.connect();
      // The warm-cache shape: connect() ran no probe.
      expect(svc.busProbe, Obd2BusProbeResult.notProbed,
          reason: 'precondition — the connect path left the protocol '
              'un-negotiated (no supported-PID cache miss)');

      final ctl = TripRecordingController(
        service: svc,
        pollInterval: const Duration(minutes: 1),
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
      );
      await ctl.start();

      final probeAt = transport.sentCommands.indexOf('0100');
      final odoAt = transport.sentCommands.indexOf('01A6');
      expect(probeAt, isNot(-1),
          reason: 'the establishment probe must run at trip start');
      expect(odoAt, isNot(-1));
      expect(probeAt, lessThan(odoAt),
          reason: 'the odometer read on an un-negotiated session would '
              'trigger the search itself and burn timeout strikes — the '
              'quiet window must come first (#3783)');
      expect(svc.busProbe, Obd2BusProbeResult.answered);
      expect(ctl.currentState, TripRecordingControllerState.recording);

      await ctl.stop();
    });

    test('a mid-trip rebind establishes the protocol on the FRESH link '
        'before the cadence resumes in earnest', () async {
      final transport = FakeObd2Transport(answeringBus());
      await transport.connect();
      final svc = Obd2Service(transport);
      await svc.connect();

      final ctl = TripRecordingController(
        service: svc,
        pollInterval: const Duration(minutes: 1),
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
        silentReconnectWindow: Duration.zero,
      );
      await ctl.start();
      ctl.debugInjectSample(
        speedKmh: 50,
        rpm: 1800,
        at: DateTime(2026, 8, 25, 19),
      );
      ctl.debugTriggerDrop();
      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop);

      // The redialed replacement: fresh ATZ'd session, warm cache — the
      // exact shape every storm dial produced on 2026-08-25.
      final freshTransport = FakeObd2Transport(answeringBus());
      await freshTransport.connect();
      final fresh = Obd2Service(freshTransport);
      await fresh.connect();
      expect(fresh.busProbe, Obd2BusProbeResult.notProbed);

      ctl.replaceService(fresh);
      ctl.resume();
      // The establishment is kicked asynchronously off the gated start.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(freshTransport.sentCommands, contains('0100'),
          reason: 'the rebind must negotiate the protocol on the fresh '
              'session — starting the cadence blind re-created the '
              '#3577 livelock on every storm dial');
      expect(fresh.busProbe, Obd2BusProbeResult.answered);
      expect(ctl.currentState, TripRecordingControllerState.recording);

      await ctl.stop();
    });

    test('an already-answered bus skips the establishment — no extra '
        'probe traffic on resume', () async {
      final transport = FakeObd2Transport(answeringBus());
      await transport.connect();
      final svc = Obd2Service(transport);
      await svc.connect();
      await svc.discoverSupportedPids();
      expect(svc.busProbe, Obd2BusProbeResult.answered);

      final ctl = TripRecordingController(
        service: svc,
        pollInterval: const Duration(minutes: 1),
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
      );
      await ctl.start();
      final probes =
          transport.sentCommands.where((c) => c == '0100').length;
      expect(probes, 1,
          reason: 'one probe from discoverSupportedPids; the gate must '
              'not add a second on an answered bus');
      await ctl.stop();
    });
  });
}
