// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3602 — the staleness fence. A link that never opens (or dies without
// a transport error) leaves the PID scheduler at 0 Hz: the null-parse
// silent-failure detector counts null PARSES and is structurally blind
// to ABSENT polls. On a real 76.5 km field drive that produced 49 min
// of ghost engine data (rpm 0, resting throttle, 'measured' fuel)
// stamped from a stale snapshot onto every GPS fix. The fence refuses
// to stamp snapshot engine values without a recent successful parse and
// escalates once through the silent-failure drop path.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';

void main() {
  group('engine-data staleness fence (#3602)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('stale_engine_test_');
      Hive.init(tmpDir.path);
      pausedBox = await Hive.openBox<String>(
        'paused_${DateTime.now().microsecondsSinceEpoch}',
      );
      historyBox = await Hive.openBox<String>(
        'history_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    Map<String, String> initResponses() => {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '01A6': 'NO DATA>',
        };

    Future<TripRecordingController> startCtl(DateTime Function() now) async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        now: now,
        pausedRepo: PausedTripRepository(box: pausedBox),
        historyRepo: TripHistoryRepository(box: historyBox),
      );
      await ctl.start();
      return ctl;
    }

    test('no parses ever + past grace → ONE silent-failure escalation, '
        'no stale sample stamped', () async {
      var clock = DateTime(2026, 7, 25, 18, 37);
      final ctl = await startCtl(() => clock);
      final samplesBefore = ctl.capturedSamples.length;

      // Within the start grace: the fence must NOT fire while the
      // connect/scheduler legitimately spin up.
      clock = clock.add(const Duration(seconds: 10));
      ctl.debugEmitNow();
      expect(ctl.currentState, TripRecordingControllerState.recording,
          reason: 'inside the 30 s start grace nothing escalates');

      // Past grace with zero successful parses — the 0 Hz ghost link.
      clock = clock.add(const Duration(seconds: 60));
      ctl.debugEmitNow();

      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop,
          reason: 'a scheduler that never delivered a parse must surface '
              'as the silent-failure drop, not record ghost engine data');
      expect(ctl.capturedSamples.length, samplesBefore,
          reason: 'the stale tick must stamp NOTHING');

      // The escalation is once-latched — further ticks don't re-fire.
      clock = clock.add(const Duration(seconds: 30));
      ctl.debugEmitNow();
      expect(
          ctl.currentState, TripRecordingControllerState.pausedDueToDrop);

      await ctl.stop();
    });

    test('fresh parses keep the fence open — recording continues', () async {
      var clock = DateTime(2026, 7, 25, 18, 37);
      final ctl = await startCtl(() => clock);

      // Simulate the dynamics tier delivering real parses as time moves.
      for (var i = 0; i < 8; i++) {
        clock = clock.add(const Duration(seconds: 10));
        ctl.debugObserveHighPriorityParse(1500.0); // fresh rpm parse
        ctl.debugEmitNow();
        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'recent parses (<15 s) must keep normal emission');
      }

      await ctl.stop();
    });

    test('a parse drought AFTER healthy streaming also trips the fence',
        () async {
      var clock = DateTime(2026, 7, 25, 18, 37);
      final ctl = await startCtl(() => clock);

      clock = clock.add(const Duration(seconds: 40));
      ctl.debugObserveHighPriorityParse(1500.0);
      ctl.debugEmitNow();
      expect(ctl.currentState, TripRecordingControllerState.recording);

      // Link silently dies: 20 s with no parse (> the 15 s limit).
      clock = clock.add(const Duration(seconds: 20));
      ctl.debugEmitNow();
      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop,
          reason: 'mid-trip parse drought = the same ghost-link shape');

      await ctl.stop();
    });

  group('post-reconnect grace (#3625)', () {
      test('null parses right after replaceService do NOT drop the fresh '
          'session — the K-line gets its bus-init window', () async {
        var clock = DateTime(2026, 7, 26, 6, 40);
        final ctl = await startCtl(() => clock);

        // Healthy streaming past the start grace.
        clock = clock.add(const Duration(seconds: 40));
        ctl.debugObserveHighPriorityParse(1500.0);
        ctl.debugEmitNow();
        expect(ctl.currentState, TripRecordingControllerState.recording);

        // The reconnect adopts a fresh service…
        final transport = FakeObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
        });
        await transport.connect();
        ctl.replaceService(Obd2Service(transport));

        // …whose first polls all fail (bus init in progress): a storm of
        // null parses inside the grace must not fire the silent-failure
        // drop — this exact storm produced the 4.7 s field flap.
        clock = clock.add(const Duration(seconds: 3));
        for (var i = 0; i < 40; i++) {
          ctl.debugObserveHighPriorityParse(null);
        }
        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'inside the 8 s grace the fresh session must survive '
                'its bus init');

        // Past the grace, a bus that STILL never produced a parse is a
        // genuinely dead session — the #3604 staleness fence (15 s since
        // the last fresh parse) takes over and drops it.
        clock = clock.add(const Duration(seconds: 14));
        ctl.debugEmitNow();
        expect(
            ctl.currentState, TripRecordingControllerState.pausedDueToDrop,
            reason: 'the grace is a window, not immunity — the fence '
                'still ends a session whose bus never came up');

        await ctl.stop();
      });
    });
  });
}
