import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event_detector.dart';

/// Unit tests for [HarshEventDetector] (#1922).
///
/// The detector counts harsh braking / acceleration from a speed
/// stream. Its whole reason to exist is **cadence independence**: the
/// trip recorder feeds it every 250 ms, but the OBD speed PID refreshes
/// only ~1 Hz, so `speedKmh` arrives as a staircase of repeated values.
/// Differentiating that staircase over the 250 ms emit interval used to
/// inflate every acceleration ~4x (428 "harsh brakes" on one 157 km
/// motorway drive in a real backup). The detector re-samples speed at
/// ~1 Hz before taking the derivative.
///
/// Default thresholds: harsh brake ≤ -3.5 m/s², harsh accel ≥ 3.0 m/s².
void main() {
  group('HarshEventDetector (#1922)', () {
    late HarshEventDetector detector;
    final start = DateTime.utc(2026);

    setUp(() {
      detector = HarshEventDetector();
    });

    /// Feed a list of per-second speed values as a staircase at the
    /// given emit cadence: each value is repeated across every emit
    /// tick that falls inside its 1-second window.
    void feedStaircase(
      HarshEventDetector d,
      List<double> speedsPerSecond, {
      required Duration emitInterval,
    }) {
      final ticksPerSecond =
          (const Duration(seconds: 1).inMicroseconds /
                  emitInterval.inMicroseconds)
              .round();
      var tick = 0;
      for (final speed in speedsPerSecond) {
        for (var sub = 0; sub < ticksPerSecond; sub++) {
          d.onSample(speed, start.add(emitInterval * tick));
          tick++;
        }
      }
    }

    test('no samples yields zero counts', () {
      expect(detector.brakes, 0);
      expect(detector.accelerations, 0);
    });

    test('a single sample only seeds the anchor — no count', () {
      detector.onSample(50, start);
      expect(detector.brakes, 0);
      expect(detector.accelerations, 0);
    });

    test('counts a harsh brake when Δv/Δt ≤ -3.5 m/s²', () {
      detector.onSample(80, start);
      // 80 → 30 km/h in 2 s = -6.94 m/s² → harsh.
      detector.onSample(30, start.add(const Duration(seconds: 2)));
      expect(detector.brakes, 1);
      expect(detector.accelerations, 0);
    });

    test('counts a harsh accel when Δv/Δt ≥ 3.0 m/s²', () {
      detector.onSample(0, start);
      // 0 → 50 km/h in 3 s → +4.63 m/s² → harsh.
      detector.onSample(50, start.add(const Duration(seconds: 3)));
      expect(detector.accelerations, 1);
      expect(detector.brakes, 0);
    });

    test('a gentle change does not tick either counter', () {
      detector.onSample(50, start);
      // 50 → 45 km/h in 3 s → -0.46 m/s² → not harsh.
      detector.onSample(45, start.add(const Duration(seconds: 3)));
      expect(detector.brakes, 0);
      expect(detector.accelerations, 0);
    });

    test(
        'a gentle 1.1 m/s² ramp fed as a 4 Hz staircase ticks no harsh '
        'events', () {
      // Real motion is +4 km/h per second (1.11 m/s², gentle), but the
      // speed value is repeated across four 250 ms emit ticks before it
      // steps. Differentiating over the 250 ms tick would read 4.44 m/s²
      // at each step and count a harsh accel every second.
      feedStaircase(
        detector,
        <double>[for (var s = 0; s <= 12; s++) (s * 4).toDouble()],
        emitInterval: const Duration(milliseconds: 250),
      );
      expect(detector.accelerations, 0);
      expect(detector.brakes, 0);
    });

    test('harsh counts are independent of emit cadence', () {
      // The same speed profile fed at 1 Hz and at 4 Hz must yield the
      // same counts — a faster cadence must not manufacture events. The
      // profile carries genuine harsh accels (0→14, 14→28, 28→40 km/h
      // in 1 s) and harsh brakes (50→35, 35→20 km/h in 1 s).
      const profile = <double>[0, 14, 28, 40, 50, 50, 35, 20, 8, 0];

      final atOneHz = HarshEventDetector();
      feedStaircase(atOneHz, profile,
          emitInterval: const Duration(seconds: 1));

      final atFourHz = HarshEventDetector();
      feedStaircase(atFourHz, profile,
          emitInterval: const Duration(milliseconds: 250));

      expect(atOneHz.accelerations, 3);
      expect(atOneHz.brakes, 2);
      expect(atFourHz.accelerations, atOneHz.accelerations);
      expect(atFourHz.brakes, atOneHz.brakes);
    });

    test('a genuine hard brake is still counted at 4 Hz staircase cadence',
        () {
      // An emergency stop: the 1 Hz speed PID drops ~25 km/h between
      // refreshes (~6.9 m/s²). Cadence-independent detection must still
      // register it rather than smoothing it away.
      feedStaircase(
        detector,
        const <double>[90, 90, 65, 40, 15, 0],
        emitInterval: const Duration(milliseconds: 250),
      );
      expect(detector.brakes, greaterThanOrEqualTo(3));
    });

    test('a long speed plateau before a sharp drop is not under-counted',
        () {
      // The car cruises at 90 km/h for 5 s, then brakes hard to 60.
      // The drop must be measured against the ~1 s window it happened
      // in, not averaged across the whole 5 s plateau.
      detector.onSample(90, start);
      for (var s = 1; s <= 5; s++) {
        detector.onSample(90, start.add(Duration(seconds: s)));
      }
      // 90 → 60 km/h over the next second → -8.3 m/s² → harsh.
      detector.onSample(60, start.add(const Duration(seconds: 6)));
      expect(detector.brakes, 1);
    });

    test('reset clears counts and the anchor', () {
      detector.onSample(80, start);
      detector.onSample(20, start.add(const Duration(seconds: 2)));
      expect(detector.brakes, 1);

      detector.reset();
      expect(detector.brakes, 0);
      expect(detector.accelerations, 0);

      // After reset the next sample only re-seeds the anchor.
      detector.onSample(50, start.add(const Duration(seconds: 10)));
      expect(detector.brakes, 0);
    });

    test('custom thresholds are honoured', () {
      final lenient = HarshEventDetector(
        brakeThresholdMps2: 10.0,
        accelThresholdMps2: 10.0,
      );
      lenient.onSample(80, start);
      // -6.94 m/s² — harsh under the default 3.5, not under 10.0.
      lenient.onSample(30, start.add(const Duration(seconds: 2)));
      expect(lenient.brakes, 0);
    });
  });
}
