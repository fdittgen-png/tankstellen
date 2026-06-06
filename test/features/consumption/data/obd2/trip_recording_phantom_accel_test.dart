// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/driving_score_calculator.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/pid_scheduler.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #2963 — a short idle-heavy OBD2 trip surfaced a phantom hard-accel
/// (`hardAccelPenalty = 3.0`) with `imu.active = false`. Root cause: the
/// `_emit` loop admitted a sample on RPM alone (the speed PID 0x0D had not
/// parsed yet) and persisted `speedKmh ?? 0` — a fabricated leading `0`.
/// When the car was already rolling once 0x0D answered, the persisted
/// series read `0 → real` and the canonical accel gate scored it as a hard
/// acceleration the driver never made.
///
/// These tests drive the REAL pipeline — `FakeObd2Transport` → `Obd2Service`
/// → scheduler → `TripRecordingController._emit` → persisted
/// `capturedSamples` → `computeDrivingScore` — flipping the 010D response
/// mid-trip to simulate the dropout, with NO fake echoing the answer
/// (the false-green-fakes rule). They assert RED-on-master
/// (hardAccelPenalty > 0) / green-after (0), and that a genuinely sustained
/// acceleration still counts and a real measured idle is untouched.
class _Clock {
  _Clock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

TripRecordingController _controller(Obd2Service service, _Clock clock) =>
    TripRecordingController(
      service: service,
      now: clock.call,
      // No auto-tick — the test drives `debugEmitNow()` deterministically.
      pollInterval: const Duration(minutes: 1),
      scheduler: PidScheduler(
        transport: service.sendCommand,
        tickRate: const Duration(milliseconds: 20),
      ),
    );

Map<String, String> _handshake() => {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '010C': '41 0C 0E A6>', // RPM ~937 (idle, present from the start)
      '01A6': 'NO DATA>', // no odometer → distance via GPS/virtual
      '0902': 'NO DATA>', // no VIN
    };

void main() {
  silenceErrorLoggerSpool();

  group('#2963 OBD2 speed-dropout phantom hard-accel', () {
    test(
        'RPM-acquired-before-speed (car already rolling) no longer '
        'fabricates a hard-accel', () async {
      final clock = _Clock(DateTime(2026, 6, 1, 9));
      final responses = _handshake()..['010D'] = 'NO DATA>'; // speed silent
      final service = Obd2Service(FakeObd2Transport(responses));
      await service.connect();
      final ctl = _controller(service, clock);
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // 3 emits 1 s apart while only RPM answers (the leading edge).
      for (var i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 1));
        ctl.debugEmitNow();
      }
      // 0x0D resumes: the car was ALREADY at 30 km/h. (0->30 over 1 s is
      // 8.33 m/s², just under the 8.83 plausibility ceiling, so on master
      // the fabricated 0 → 30 step counted as a sustained hard accel.)
      responses['010D'] = '41 0D 1E>'; // 30 km/h
      await Future<void>.delayed(const Duration(milliseconds: 500));
      for (var i = 0; i < 3; i++) {
        clock.advance(const Duration(seconds: 1));
        ctl.debugEmitNow();
      }

      final samples = ctl.capturedSamples;
      // The leading RPM-only ticks (speed never read) are not persisted with
      // a fabricated 0; the series starts at the first real speed.
      expect(samples.map((s) => s.speedKmh), everyElement(closeTo(30, 1e-9)),
          reason: 'no fabricated leading 0 in the persisted series');
      final score = computeDrivingScore(samples);
      expect(score.hardAccelPenalty, 0.0,
          reason:
              'RED on master (3.0 — the 0→30 phantom step); 0 after the fix');
      expect(score.hardBrakePenalty, 0.0);

      await ctl.stop();
    });

    test('a genuinely sustained hard acceleration still counts', () async {
      final clock = _Clock(DateTime(2026, 6, 1, 9));
      // Speed present from the start at a real 10 km/h, then a sustained
      // hard launch to ~38 km/h held for >1 s — a real manoeuvre that must
      // survive the fix.
      final responses = _handshake()..['010D'] = '41 0D 0A>'; // 10 km/h
      final service = Obd2Service(FakeObd2Transport(responses));
      await service.connect();
      final ctl = _controller(service, clock);
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Two ticks at 10 km/h to seed the series.
      for (var i = 0; i < 2; i++) {
        clock.advance(const Duration(seconds: 1));
        ctl.debugEmitNow();
      }
      // Hard launch: +28 km/h over 1 s ≈ 7.8 m/s² (under the ceiling),
      // sustained two intervals to clear the ≥1 s window.
      responses['010D'] = '41 0D 26>'; // 38 km/h
      await Future<void>.delayed(const Duration(milliseconds: 500));
      clock.advance(const Duration(seconds: 1));
      ctl.debugEmitNow();
      responses['010D'] = '41 0D 42>'; // 66 km/h — keep climbing hard
      await Future<void>.delayed(const Duration(milliseconds: 500));
      clock.advance(const Duration(seconds: 1));
      ctl.debugEmitNow();

      final score = computeDrivingScore(ctl.capturedSamples);
      expect(score.hardAccelPenalty, greaterThan(0.0),
          reason: 'a real sustained hard launch must still be penalised');

      await ctl.stop();
    });

    test('a measured idle (real speed 0) keeps the idle penalty', () async {
      final clock = _Clock(DateTime(2026, 6, 1, 9));
      // Real measured 0 km/h from the start (engine running, parked). This
      // is a MEASURED 0 (010D answers 41 0D 00), not a fabricated one, so it
      // must persist and accumulate idle.
      final responses = _handshake()..['010D'] = '41 0D 00>'; // 0 km/h
      final service = Obd2Service(FakeObd2Transport(responses));
      await service.connect();
      final ctl = _controller(service, clock);
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      for (var i = 0; i < 8; i++) {
        clock.advance(const Duration(seconds: 1));
        ctl.debugEmitNow();
      }
      final samples = ctl.capturedSamples;
      expect(samples, isNotEmpty,
          reason: 'a measured idle still persists samples');
      expect(samples.map((s) => s.speedKmh), everyElement(0.0));
      final score = computeDrivingScore(samples);
      expect(score.idlingPenalty, greaterThan(0.0),
          reason: 'a real idle is untouched by the phantom fix');
      expect(score.hardAccelPenalty, 0.0);

      await ctl.stop();
    });
  });
}
