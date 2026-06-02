// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/harsh_event.dart';
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

    // ---- #2653 de-noising gates -----------------------------------------

    group('sustained-window gate (#2653)', () {
      test('a single sub-1 s spike does NOT fire', () {
        // 80 → 60 km/h is -6.2 m/s² — harsh by magnitude — but it
        // happened across only a 0.9 s window. A coarse staircase
        // sampled against the ~0.9 s resample produces exactly this kind
        // of one-interval phasing artefact; the sustained gate rejects
        // it because the derivative did not span ≥ 1 s.
        detector.onSample(80, start);
        detector.onSample(
            60, start.add(const Duration(milliseconds: 900)));
        expect(detector.brakes, 0);
        expect(detector.accelerations, 0);
      });

      test('a ≥1 s sustained event DOES fire', () {
        // The same -6.2 m/s² magnitude, now measured over a full 1.0 s
        // window — a genuine hard brake, counted.
        detector.onSample(90, start);
        detector.onSample(74, start.add(const Duration(seconds: 1)));
        expect(detector.brakes, 1);
      });

      test('minSustainedSec is configurable', () {
        // Tighten the window to 0.5 s and the 0.9 s spike now counts —
        // proves the gate is the only thing suppressing it above.
        final loose = HarshEventDetector(minSustainedSec: 0.5);
        loose.onSample(80, start);
        loose.onSample(60, start.add(const Duration(milliseconds: 900)));
        expect(loose.brakes, 1);
      });
    });

    group('accuracy gate (#2653)', () {
      test('a bad-fix sample (> 10 m) is rejected and breaks the anchor',
          () {
        // A jittery urban-canyon fix with 25 m accuracy must not feed the
        // derivative — "a bad fix is worse than no fix". The anchor at
        // 80 km/h is dropped, so no brake is computed across it.
        detector.onSample(80, start, hAccuracyM: 4);
        detector.onSample(30, start.add(const Duration(seconds: 2)),
            hAccuracyM: 25);
        expect(detector.brakes, 0);
      });

      test('a good-fix sample (≤ 10 m) is scored normally', () {
        detector.onSample(80, start, hAccuracyM: 4);
        detector.onSample(30, start.add(const Duration(seconds: 2)),
            hAccuracyM: 6);
        expect(detector.brakes, 1);
      });

      test('a null / unknown accuracy is accepted (OBD-speed-only path)',
          () {
        detector.onSample(80, start);
        detector.onSample(30, start.add(const Duration(seconds: 2)));
        expect(detector.brakes, 1);
      });
    });

    group('min-speed floor (#2653)', () {
      // A genuine ≥ 3.5 m/s² derivative is physically impossible below a
      // 5 km/h mean over a ≥ 1 s window (both endpoints < 10 km/h ⇒
      // Δv < 2.8 m/s²), so the floor is exercised against a *lenient*
      // threshold that a low-speed dead-reckoning wobble can cross —
      // proving the floor, not the magnitude threshold.
      test('a crawl-speed wobble below the floor is not scored', () {
        final crawl = HarshEventDetector(brakeThresholdMps2: 1.0);
        crawl.onSample(7, start);
        // 7 → 0 km/h over 1 s = -1.94 m/s² (≥ 1.0 lenient threshold), but
        // the mean is 3.5 km/h — below the 5 km/h floor → not scored.
        crawl.onSample(0, start.add(const Duration(seconds: 1)));
        expect(crawl.brakes, 0);
        expect(crawl.accelerations, 0);
      });

      test('the same wobble above the floor IS scored', () {
        final fast = HarshEventDetector(brakeThresholdMps2: 1.0);
        fast.onSample(20, start);
        // 20 → 13 km/h over 1 s = -1.94 m/s², mean 16.5 km/h ≥ 5 → counts.
        fast.onSample(13, start.add(const Duration(seconds: 1)));
        expect(fast.brakes, 1);
      });

      test('minSpeedKmh is configurable', () {
        // Drop the floor to 0 and the crawl-speed wobble now counts —
        // confirming the floor is the only thing suppressing it above.
        final noFloor =
            HarshEventDetector(brakeThresholdMps2: 1.0, minSpeedKmh: 0);
        noFloor.onSample(7, start);
        noFloor.onSample(0, start.add(const Duration(seconds: 1)));
        expect(noFloor.brakes, 1);
      });
    });

    group('source-aware suppression (#2653)', () {
      test('a suppressed sample is ignored entirely (anchor not seeded)',
          () {
        // Feed a clearly-harsh brake on a suppressed (virtual) source —
        // it must produce nothing AND not even seed the anchor, so a
        // following non-suppressed sample starts fresh.
        detector.onSample(90, start, suppress: true);
        detector.onSample(40, start.add(const Duration(seconds: 1)),
            suppress: true);
        expect(detector.brakes, 0);
        expect(detector.accelerations, 0);
      });
    });

    group('optional speed pre-smoothing (#2653)', () {
      test('a 3-sample moving average damps a single-step quantisation '
          'spike', () {
        // A 1 km/h-quantised signal sits at 50, jumps to 70 for one
        // sample, then settles at 51. Differentiated raw, the 50→70
        // step over 1 s is +5.6 m/s² → a phantom harsh accel. The
        // 3-sample MA blunts the lone spike below the threshold.
        final smoothed = HarshEventDetector(smoothSpeed: true);
        smoothed.onSample(50, start);
        smoothed.onSample(50, start.add(const Duration(seconds: 1)));
        smoothed.onSample(70, start.add(const Duration(seconds: 2)));
        smoothed.onSample(51, start.add(const Duration(seconds: 3)));
        smoothed.onSample(51, start.add(const Duration(seconds: 4)));
        expect(smoothed.accelerations, 0);

        // The same series WITHOUT smoothing fires the phantom.
        final raw = HarshEventDetector();
        raw.onSample(50, start);
        raw.onSample(50, start.add(const Duration(seconds: 1)));
        raw.onSample(70, start.add(const Duration(seconds: 2)));
        raw.onSample(51, start.add(const Duration(seconds: 3)));
        raw.onSample(51, start.add(const Duration(seconds: 4)));
        expect(raw.accelerations, greaterThanOrEqualTo(1));
      });
    });

    group('live onEvent callback (#2663)', () {
      test('fires onEvent the instant a de-noised event is detected', () {
        final fired = <HarshEvent>[];
        final d = HarshEventDetector(onEvent: fired.add);
        d.onSample(0, start);
        // 0 → 50 km/h in 3 s → +4.63 m/s² → one harsh accel.
        d.onSample(50, start.add(const Duration(seconds: 3)));
        expect(fired, hasLength(1));
        expect(fired.single.type, HarshEventType.acceleration);
        // The callback and the post-trip list agree on the same event.
        expect(d.events, equals(fired));
      });

      test('does NOT fire onEvent for a suppressed / sub-threshold sample',
          () {
        final fired = <HarshEvent>[];
        final d = HarshEventDetector(onEvent: fired.add);
        // Suppressed source: ignored entirely.
        d.onSample(90, start, suppress: true);
        d.onSample(40, start.add(const Duration(seconds: 1)), suppress: true);
        // Gentle change: below threshold.
        d.onSample(50, start.add(const Duration(seconds: 2)));
        d.onSample(48, start.add(const Duration(seconds: 5)));
        expect(fired, isEmpty);
      });
    });
  });
}
