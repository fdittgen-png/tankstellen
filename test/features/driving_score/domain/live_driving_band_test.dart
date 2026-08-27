// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/api.dart';

/// #3845 — the always-on live driving-behaviour band.
///
/// The user's ask: "always analyze the driving behaviour and display
/// green / yellow / orange / red for good to bad". These tests pin the
/// three properties that makes that true — it is ALWAYS on (GPS-only
/// trajets included), it MOVES with how the car is actually driven, and
/// it never publishes a confident colour it has not earned yet.
void main() {
  final t0 = DateTime.utc(2026, 8, 27, 9);

  /// Feed [seconds] of driving at 4 Hz, with [speedAt] giving km/h for
  /// each elapsed second (fractional).
  LiveDrivingBandTracker driveFor(
    double seconds,
    double Function(double t) speedAt, {
    LiveDrivingBandTracker? into,
    double? Function(double t)? rpmAt,
    bool suppressSpeedHarsh = false,
  }) {
    final tracker = into ?? LiveDrivingBandTracker();
    final ticks = (seconds * 4).round();
    for (var i = 0; i <= ticks; i++) {
      final t = i / 4.0;
      tracker.add(
        at: t0.add(Duration(milliseconds: (t * 1000).round())),
        speedKmh: speedAt(t),
        rpm: rpmAt?.call(t),
        suppressSpeedHarsh: suppressSpeedHarsh,
      );
    }
    return tracker;
  }

  group('the band is earned before it is shown', () {
    test('nothing is published before the minimum span', () {
      // 10 s of driving, minSpan is 15 s.
      final tracker = driveFor(10, (t) => 50);
      expect(tracker.band, isNull,
          reason: 'a perfect 100 here would be the calculator answering '
              'about a window too short to judge — green meaning "no data"');
    });

    test('nothing is published before the minimum sample count', () {
      final tracker = LiveDrivingBandTracker();
      // Three ticks spread over a long span: span passes, count does not.
      for (var i = 0; i < 3; i++) {
        tracker.add(at: t0.add(Duration(seconds: i * 20)), speedKmh: 50);
      }
      expect(tracker.band, isNull);
    });

    test('a band appears once both gates are met', () {
      final tracker = driveFor(30, (t) => 50);
      expect(tracker.band, isNotNull);
      expect(tracker.band!.score, inInclusiveRange(0, 100));
    });
  });

  group('the band reflects how the car is driven', () {
    test('steady cruising scores in the top band (green)', () {
      final tracker = driveFor(60, (t) => 90);
      expect(tracker.band!.styleClass, DrivingStyleClass.veryGood);
    });

    test('repeated hard accelerate / brake cycles score worse than '
        'steady cruising', () {
      // 0 -> 60 km/h and back every 4 s: ~8 m/s², far past the harsh gate.
      final aggressive = driveFor(60, (t) {
        final phase = t % 4.0;
        return phase < 2.0 ? phase / 2.0 * 60.0 : (4.0 - phase) / 2.0 * 60.0;
      });
      final steady = driveFor(60, (t) => 60);
      expect(aggressive.band, isNotNull);
      expect(steady.band, isNotNull);
      expect(aggressive.band!.score, lessThan(steady.band!.score),
          reason: 'a band that does not move with the driving is decoration');
    });

    test('the colour band follows the score through the shared cut-offs', () {
      // The widget colours off DrivingStyleClass, so the band must agree
      // with the same thresholds the end-of-trip card uses.
      final tracker = driveFor(60, (t) => 90);
      expect(tracker.band!.styleClass,
          DrivingStyleClass.fromScore(tracker.band!.score));
    });
  });

  group('always on — a GPS-only trajet still gets a band', () {
    test('no rpm, no throttle, no fuel rate still scores', () {
      // Exactly the GPS-only shape: speed and nothing else.
      final tracker = driveFor(60, (t) => 70, rpmAt: (t) => null);
      expect(tracker.band, isNotNull,
          reason: 'this is the "always analyze" half of the request — a '
              'GPS-only recording must still be graded');
      expect(tracker.band!.score, inInclusiveRange(0, 100));
    });

    test('a dead-reckoned speed series can be excluded from harsh scoring',
        () {
      // #2653: on a `virtual` distance source the speed series is
      // synthesised, so harsh events off it are manufactured.
      final scored = driveFor(60, (t) {
        final phase = t % 4.0;
        return phase < 2.0 ? phase / 2.0 * 60.0 : (4.0 - phase) / 2.0 * 60.0;
      });
      final suppressed = driveFor(60, (t) {
        final phase = t % 4.0;
        return phase < 2.0 ? phase / 2.0 * 60.0 : (4.0 - phase) / 2.0 * 60.0;
      }, suppressSpeedHarsh: true);
      expect(suppressed.band!.score, greaterThan(scored.band!.score));
    });
  });

  group('cost and robustness', () {
    test('the window is bounded — a long trip does not grow the workload',
        () {
      // 10 minutes at 4 Hz = 2400 ticks; a 90 s window holds ~361.
      final tracker = driveFor(600, (t) => 80);
      expect(tracker.windowSampleCount, lessThanOrEqualTo(4 * 90 + 1));
    });

    test('the score is recomputed at most once per second, not per tick',
        () {
      final tracker = driveFor(30, (t) => 50);
      final before = tracker.band;
      // Three more ticks inside the same second must not recompute...
      for (var i = 1; i <= 3; i++) {
        tracker.add(
          at: t0.add(Duration(milliseconds: 30000 + i * 250)),
          speedKmh: 50,
        );
      }
      expect(identical(tracker.band, before), isTrue,
          reason: '4 Hz scoring is 4x the work for a number no eye can '
              'follow');
    });

    test('a backwards clock restarts the window rather than scoring it', () {
      final tracker = driveFor(30, (t) => 50);
      expect(tracker.band, isNotNull);
      tracker.add(at: t0.subtract(const Duration(minutes: 5)), speedKmh: 50);
      expect(tracker.band, isNull,
          reason: 'every dt in the window would be corrupt');
      expect(tracker.windowSampleCount, 1);
    });

    test('reset clears the published band', () {
      final tracker = driveFor(30, (t) => 50);
      expect(tracker.band, isNotNull);
      tracker.reset();
      expect(tracker.band, isNull);
      expect(tracker.windowSampleCount, 0);
    });
  });
}
