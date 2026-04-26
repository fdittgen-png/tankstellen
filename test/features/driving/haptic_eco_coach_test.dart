import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/driving/haptic_eco_coach.dart';

/// Heuristic + cooldown coverage for [HapticEcoCoach] (#1122).
///
/// All tests drive the coach with a manually-controlled clock and
/// `debugFeed` so the rolling window and cooldown can be verified
/// without `Future.delayed` or real timers — we want fast, flake-free
/// coverage of the four fire/don't-fire scenarios called out in the
/// issue. The injected `haptic` callback counts fires; we never touch
/// the platform channel.
void main() {
  group('HapticEcoCoach heuristic', () {
    test('fires once on the floor-it-on-highway pattern', () async {
      final clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      var hapticCount = 0;
      final coach = HapticEcoCoach(
        readings: const Stream<TripLiveReading>.empty(),
        haptic: () async => hapticCount++,
        clock: clock.now,
      );

      // Cruise at 110 km/h with sustained 80 % throttle for 6 s — the
      // classic "stab on the highway" pattern. Speed wobbles ±2 km/h
      // (well under the 10 km/h threshold).
      _feedConstant(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200, // 5 Hz, matches the PidScheduler default
        throttle: 80.0,
        speed: 110.0,
        speedWobbleKmh: 2.0,
      );
      // Yield so any queued futures (haptic) settle.
      await Future<void>.delayed(Duration.zero);

      expect(
        hapticCount,
        equals(1),
        reason:
            'Sustained > 75 % throttle with < 10 km/h Δspeed must fire '
            'exactly one haptic.',
      );
    });

    test(
        'does NOT fire during honest 0→100 acceleration with > 75 % throttle',
        () async {
      final clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      var hapticCount = 0;
      final coach = HapticEcoCoach(
        readings: const Stream<TripLiveReading>.empty(),
        haptic: () async => hapticCount++,
        clock: clock.now,
      );

      // Pull from 20 → 100 km/h over 5 s with throttle pegged at 90 %.
      // Δspeed across the window is 80 km/h — exceeds the 10 km/h
      // threshold, so the heuristic must NOT fire.
      _feedAccelerating(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200,
        throttle: 90.0,
        startSpeedKmh: 20.0,
        endSpeedKmh: 100.0,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        hapticCount,
        equals(0),
        reason:
            'Honest acceleration past the speed-delta gate must not fire — '
            'the user is deliberately accelerating, not wasting fuel.',
      );
    });

    test('does NOT fire when throttle stays below the 75 % threshold',
        () async {
      final clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      var hapticCount = 0;
      final coach = HapticEcoCoach(
        readings: const Stream<TripLiveReading>.empty(),
        haptic: () async => hapticCount++,
        clock: clock.now,
      );

      // Firm cruise at 60 % throttle, 110 km/h, for 6 s. Below the
      // 75 % floor — no fire.
      _feedConstant(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200,
        throttle: 60.0,
        speed: 110.0,
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        hapticCount,
        equals(0),
        reason:
            'Average throttle below the 75 % threshold must not fire even '
            'when the speed-delta condition is satisfied.',
      );
    });

    test(
        'cooldown gates: two fire-condition windows < 30 s apart fire only once',
        () async {
      final clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      var hapticCount = 0;
      final coach = HapticEcoCoach(
        readings: const Stream<TripLiveReading>.empty(),
        haptic: () async => hapticCount++,
        clock: clock.now,
      );

      // First fire-condition burst.
      _feedConstant(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200,
        throttle: 85.0,
        speed: 120.0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        hapticCount,
        equals(1),
        reason: 'First sustained-stab window should fire once.',
      );

      // Skip 10 s (still inside the 30 s cooldown), then fire-condition
      // again.
      clock.advance(const Duration(seconds: 10));
      _feedConstant(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200,
        throttle: 85.0,
        speed: 120.0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        hapticCount,
        equals(1),
        reason:
            'A second matching window inside the 30 s cooldown must NOT '
            'fire — that is the whole point of the cooldown.',
      );

      // Skip past the cooldown and fire-condition once more.
      clock.advance(const Duration(seconds: 35));
      _feedConstant(
        coach,
        clock,
        durationSeconds: 6,
        intervalMs: 200,
        throttle: 85.0,
        speed: 120.0,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        hapticCount,
        equals(2),
        reason: 'Past the cooldown, the next matching window fires again.',
      );
    });

    test('start() subscribes to the readings stream and forwards to heuristic',
        () async {
      final clock = _Clock(DateTime(2026, 1, 1, 12, 0, 0));
      var hapticCount = 0;
      final controller = StreamController<TripLiveReading>();
      addTearDown(controller.close);

      final coach = HapticEcoCoach(
        readings: controller.stream,
        haptic: () async => hapticCount++,
        clock: clock.now,
      );
      final sub = coach.start();
      addTearDown(sub.cancel);

      // Push a 6 s sustained-stab burst onto the real stream.
      for (var i = 0; i < 30; i++) {
        controller.add(TripLiveReading(
          throttlePercent: 80.0,
          speedKmh: 110.0,
          distanceKmSoFar: 0,
          elapsed: Duration(milliseconds: 200 * i),
        ));
        clock.advance(const Duration(milliseconds: 200));
        // Pump the microtask queue so the stream listener actually
        // delivers the reading before the next add.
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        hapticCount,
        equals(1),
        reason:
            '`start()` must wire the real stream into the heuristic — a '
            '6 s sustained-stab burst on the live stream fires once.',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Hand-cranked clock so cooldown / window timing can be verified
/// without `Future.delayed`. Tests advance it explicitly.
class _Clock {
  _Clock(this._now);
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

/// Feed [coach] a stream of constant-throttle / constant-speed
/// readings spanning [durationSeconds] at [intervalMs] cadence. The
/// caller's clock advances in lock-step so the rolling window
/// resolves correctly.
void _feedConstant(
  HapticEcoCoach coach,
  _Clock clock, {
  required int durationSeconds,
  required int intervalMs,
  required double throttle,
  required double speed,
  double speedWobbleKmh = 0.0,
}) {
  final ticks = (durationSeconds * 1000) ~/ intervalMs;
  for (var i = 0; i < ticks; i++) {
    // Alternate ±wobble so the average stays at `speed` but the
    // first/last samples may differ slightly.
    final jitter = speedWobbleKmh == 0 ? 0.0 : (i.isEven ? 1 : -1) * speedWobbleKmh;
    coach.debugFeed(TripLiveReading(
      throttlePercent: throttle,
      speedKmh: speed + jitter,
      distanceKmSoFar: 0,
      elapsed: Duration(milliseconds: intervalMs * i),
    ));
    clock.advance(Duration(milliseconds: intervalMs));
  }
}

/// Feed [coach] a stream of constant-throttle readings with a linear
/// speed ramp from [startSpeedKmh] to [endSpeedKmh] over the duration.
void _feedAccelerating(
  HapticEcoCoach coach,
  _Clock clock, {
  required int durationSeconds,
  required int intervalMs,
  required double throttle,
  required double startSpeedKmh,
  required double endSpeedKmh,
}) {
  final ticks = (durationSeconds * 1000) ~/ intervalMs;
  for (var i = 0; i < ticks; i++) {
    final fraction = ticks <= 1 ? 0.0 : i / (ticks - 1);
    final speed = startSpeedKmh + (endSpeedKmh - startSpeedKmh) * fraction;
    coach.debugFeed(TripLiveReading(
      throttlePercent: throttle,
      speedKmh: speed,
      distanceKmSoFar: 0,
      elapsed: Duration(milliseconds: intervalMs * i),
    ));
    clock.advance(Duration(milliseconds: intervalMs));
  }
}
