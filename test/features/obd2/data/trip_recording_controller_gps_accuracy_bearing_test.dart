// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/pid_scheduler.dart';
import 'package:tankstellen/features/obd2/data/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/data/trip_sample_codec.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2648 — the OBD2 emit path stamps the GPS horizontal accuracy + bearing
/// latched via [TripRecordingController.updateGpsFix] onto every
/// [TripSample] (they used to reach only 0.3 % of samples — the OBD2 path
/// dropped `pos.accuracy` / `pos.heading`). This pins the controller `_emit`
/// build + the codec round-trip, so a persisted OBD2 trip carries them.
class _MutableClock {
  _MutableClock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// ELM327 handshake + RPM/speed so an emit builds a real sample.
Map<String, String> _basicResponses() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '010C': '41 0C 0E A6>', // RPM ~937.5
      '010D': '41 0D 32>', // 50 km/h
      '01A6': 'NO DATA>',
      '0902': 'NO DATA>',
    };

void main() {
  silenceErrorLoggerSpool();

  group('#2648 OBD2 _emit stamps GPS accuracy + bearing onto the sample', () {
    test(
        'a sample built after updateGpsFix(hAccuracyM, bearingDeg) carries '
        'them, and they round-trip through the codec', () async {
      final clock = _MutableClock(DateTime(2026, 6, 1, 9));
      final transport = FakeObd2Transport(_basicResponses());
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        now: clock.call,
        pollInterval: const Duration(minutes: 1), // no auto-tick
        scheduler: PidScheduler(
          transport: service.sendCommand,
          tickRate: const Duration(milliseconds: 20),
        ),
      );
      await ctl.start();
      // Let the scheduler fill the snapshot with RPM + speed.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      ctl.updateGpsFix(
        latitude: 43.40,
        longitude: 3.50,
        altitudeM: 100,
        hAccuracyM: 3.8,
        bearingDeg: 154.0,
        speedKmh: 50,
      );
      clock.advance(const Duration(seconds: 1));
      ctl.debugEmitNow();

      final samples = ctl.capturedSamples;
      expect(samples, isNotEmpty,
          reason: 'an emit with speed/rpm must capture a sample');
      final sample = samples.last;
      expect(sample.hAccuracyM, closeTo(3.8, 1e-9),
          reason: 'the OBD2 path must stamp the latched GPS accuracy '
              '(enables the harsh-event accuracy-gate)');
      expect(sample.bearingDeg, closeTo(154.0, 1e-9),
          reason: 'the OBD2 path must stamp the latched GPS bearing '
              '(revives the cornering analytic)');

      // Persisted form keeps them ('ha' / 'be') and decodes clean.
      final decoded = sampleFromJson(sampleToJson(sample));
      expect(decoded.hAccuracyM, closeTo(3.8, 1e-9));
      expect(decoded.bearingDeg, closeTo(154.0, 1e-9));

      await ctl.stop();
    });

    test(
        'a trip with no GPS fix carries null accuracy + bearing '
        '(pre-#2648 behaviour, byte-for-byte for non-GPS trips)', () async {
      final clock = _MutableClock(DateTime(2026, 6, 1, 10));
      final transport = FakeObd2Transport(_basicResponses());
      final service = Obd2Service(transport);
      await service.connect();

      final ctl = TripRecordingController(
        service: service,
        now: clock.call,
        pollInterval: const Duration(minutes: 1),
        scheduler: PidScheduler(
          transport: service.sendCommand,
          tickRate: const Duration(milliseconds: 20),
        ),
      );
      await ctl.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      clock.advance(const Duration(seconds: 1));
      ctl.debugEmitNow();

      final sample = ctl.capturedSamples.last;
      expect(sample.hAccuracyM, isNull);
      expect(sample.bearingDeg, isNull);

      await ctl.stop();
    });
  });
}
