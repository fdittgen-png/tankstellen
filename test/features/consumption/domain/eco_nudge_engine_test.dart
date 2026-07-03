// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/eco_nudge_engine.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';

/// #3432 (epic #3416) — pure rate-limit + episode logic of the live
/// eco-nudge engine (≥ 60 s apart, max 3 per trip, one per episode).
void main() {
  final t0 = DateTime.utc(2026, 7, 1, 9);

  TripLiveReading r({
    double? speed,
    double? rpm,
    double? pedal,
  }) =>
      TripLiveReading(
        elapsed: Duration.zero,
        distanceKmSoFar: 0,
        speedKmh: speed,
        rpm: rpm,
        pedalPercent: pedal,
      );

  TripLiveReading idle() => r(speed: 0, rpm: 800);
  TripLiveReading cruise() => r(speed: 80, rpm: 2000, pedal: 20);
  TripLiveReading highRpm() => r(speed: 80, rpm: 3200, pedal: 20);
  TripLiveReading pedalMash() => r(speed: 60, rpm: 3500, pedal: 95);

  group('episode detection', () {
    test('idle nudges once after 30 s and never re-fires within the same '
        'episode', () {
      final engine = EcoNudgeEngine();
      expect(engine.onReading(idle(), t0), isNull);
      expect(
          engine.onReading(idle(), t0.add(const Duration(seconds: 29))),
          isNull);
      expect(
        engine.onReading(idle(), t0.add(const Duration(seconds: 30))),
        EcoNudgeType.idleWaste,
      );
      // Still idling 5 minutes later — same episode, silent.
      expect(
          engine.onReading(idle(), t0.add(const Duration(minutes: 5))),
          isNull);
    });

    test('harsh accel needs the pedal sustained, not a single tick', () {
      final engine = EcoNudgeEngine();
      expect(engine.onReading(pedalMash(), t0), isNull);
      // Pedal released before the sustain window → episode resets.
      expect(
          engine.onReading(cruise(), t0.add(const Duration(seconds: 1))),
          isNull);
      expect(
          engine.onReading(pedalMash(), t0.add(const Duration(seconds: 2))),
          isNull);
      expect(
        engine.onReading(pedalMash(), t0.add(const Duration(seconds: 4))),
        EcoNudgeType.harshAccel,
      );
    });

    test('high-RPM cruise nudges after its sustain window', () {
      final engine = EcoNudgeEngine();
      expect(engine.onReading(highRpm(), t0), isNull);
      expect(
          engine.onReading(highRpm(), t0.add(const Duration(seconds: 3))),
          isNull);
      expect(
        engine.onReading(highRpm(), t0.add(const Duration(seconds: 6))),
        EcoNudgeType.highRpmCruise,
      );
    });
  });

  group('rate limiting', () {
    test('two qualifying episodes < 60 s apart yield ONE nudge', () {
      final engine = EcoNudgeEngine();
      engine.onReading(idle(), t0);
      expect(
        engine.onReading(idle(), t0.add(const Duration(seconds: 30))),
        EcoNudgeType.idleWaste,
      );
      // Drive off, then a high-RPM episode qualifying at +40 s — inside
      // the 60 s gap → suppressed.
      engine.onReading(highRpm(), t0.add(const Duration(seconds: 34)));
      expect(
        engine.onReading(highRpm(), t0.add(const Duration(seconds: 40))),
        isNull,
      );
      expect(engine.firedCount, 1);
    });

    test('a qualifying episode ≥ 60 s after the last nudge fires', () {
      final engine = EcoNudgeEngine();
      engine.onReading(idle(), t0);
      expect(
        engine.onReading(idle(), t0.add(const Duration(seconds: 30))),
        EcoNudgeType.idleWaste,
      );
      engine.onReading(highRpm(), t0.add(const Duration(seconds: 85)));
      expect(
        engine.onReading(highRpm(), t0.add(const Duration(seconds: 91))),
        EcoNudgeType.highRpmCruise,
      );
    });

    test('never more than 3 nudges per trip', () {
      final engine = EcoNudgeEngine();
      var fired = 0;
      // 6 idle episodes, each 40 s long, separated by movement, spaced
      // well past the 60 s gap.
      for (var episode = 0; episode < 6; episode++) {
        final base = t0.add(Duration(minutes: 3 * episode));
        engine.onReading(cruise(), base);
        engine.onReading(idle(), base.add(const Duration(seconds: 1)));
        final verdict = engine.onReading(
            idle(), base.add(const Duration(seconds: 40)));
        if (verdict != null) fired++;
      }
      expect(fired, 3);
      expect(engine.firedCount, 3);
    });

    test('reset() restores the per-trip budget', () {
      final engine = EcoNudgeEngine();
      for (var episode = 0; episode < 4; episode++) {
        final base = t0.add(Duration(minutes: 2 * episode));
        engine.onReading(cruise(), base);
        engine.onReading(idle(), base.add(const Duration(seconds: 1)));
        engine.onReading(idle(), base.add(const Duration(seconds: 40)));
      }
      expect(engine.firedCount, 3);

      engine.reset();
      expect(engine.firedCount, 0);
      engine.onReading(idle(), t0.add(const Duration(hours: 1)));
      expect(
        engine.onReading(
            idle(), t0.add(const Duration(hours: 1, seconds: 30))),
        EcoNudgeType.idleWaste,
      );
    });
  });

  group('priority', () {
    test('harsh accel outranks a simultaneous idle candidate', () {
      // Contrived but pins the ordering: an idle episode matures while
      // the pedal has also been pinned (e.g. brake-torque launch prep).
      final engine = EcoNudgeEngine();
      engine.onReading(r(speed: 0, rpm: 1500, pedal: 95), t0);
      expect(
        engine.onReading(
            r(speed: 0, rpm: 1500, pedal: 95),
            t0.add(const Duration(seconds: 35))),
        EcoNudgeType.harshAccel,
      );
    });
  });
}
