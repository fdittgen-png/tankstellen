// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/high_speed_band_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/smooth_driving_rule.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson_rule.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

/// Per-rule coverage for the #2287 post-trip analytics lessons computed
/// from #2286 signals + GPS: high-speed-band penalty (fires / skips /
/// graceful no-fuel degradation / impact) and smooth-driving praise
/// (fires / skips on harsh events / skips a pure-idle dwell).
void main() {
  final AppLocalizations l = AppLocalizationsEn();
  final start = DateTime.utc(2026);

  TripSummary summary({
    double distanceKm = 30,
    double? fuelLitersConsumed,
    int harshAccelerations = 0,
    int harshBrakes = 0,
  }) =>
      TripSummary(
        distanceKm: distanceKm,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: harshBrakes,
        harshAccelerations: harshAccelerations,
        fuelLitersConsumed: fuelLitersConsumed,
        startedAt: start,
      );

  LessonContext ctx(TripSummary s, List<TripSample> samples) => LessonContext(
        summary: s,
        samples: samples,
        score: DrivingScore.perfect,
        insights: const <DrivingInsight>[],
      );

  // A motorway run: 10 min at 130 km/h.
  List<TripSample> highSpeedSamples() => <TripSample>[
        TripSample(timestamp: start, speedKmh: 130, rpm: 2800),
        TripSample(
            timestamp: start.add(const Duration(seconds: 600)),
            speedKmh: 130,
            rpm: 2800),
      ];

  // A steady town cruise: 10 min at 50 km/h, no harsh inputs.
  List<TripSample> calmCruiseSamples() => <TripSample>[
        TripSample(timestamp: start, speedKmh: 50, rpm: 1900),
        TripSample(
            timestamp: start.add(const Duration(seconds: 300)),
            speedKmh: 51,
            rpm: 1900),
        TripSample(
            timestamp: start.add(const Duration(seconds: 600)),
            speedKmh: 50,
            rpm: 1900),
      ];

  group('highSpeedTimeShare helper (#2287)', () {
    test('all-high-speed run → share ≈ 1.0', () {
      expect(highSpeedTimeShare(highSpeedSamples()), closeTo(1.0, 1e-9));
    });

    test('town cruise below the threshold → share 0', () {
      expect(highSpeedTimeShare(calmCruiseSamples()), 0.0);
    });

    test('< 2 samples → 0', () {
      expect(
        highSpeedTimeShare(
            [TripSample(timestamp: start, speedKmh: 130, rpm: 2800)]),
        0.0,
      );
    });
  });

  group('HighSpeedBandRule (#2287)', () {
    const rule = HighSpeedBandRule();

    test('fires on a sustained-high-speed trip with a fuel figure and '
        'estimates wasted litres', () {
      final lesson = rule.evaluate(
        ctx(summary(fuelLitersConsumed: 5.0), highSpeedSamples()),
        l,
      );
      expect(lesson, isNotNull);
      expect(lesson!.id, highSpeedBandLessonId);
      // share≈1.0 × 5 L × 0.20 drag factor = ~1.0 L wasted.
      expect(lesson.metricValue, closeTo(1.0, 1e-6));
      expect(lesson.impact, closeTo(1.0, 1e-6));
      expect(lesson.trailing, isNotNull);
      expect(lesson.advice, isNotEmpty);
    });

    test('does NOT fire on a town cruise below the threshold', () {
      final lesson = rule.evaluate(
        ctx(summary(fuelLitersConsumed: 4.0), calmCruiseSamples()),
        l,
      );
      expect(lesson, isNull);
    });

    test('degrades gracefully on a GPS-only trip with no fuel figure — '
        'fires on the time-share, no litres badge', () {
      final lesson = rule.evaluate(
        ctx(summary(), highSpeedSamples()), // fuelLitersConsumed null
        l,
      );
      expect(lesson, isNotNull);
      expect(lesson!.trailing, isNull,
          reason: 'no fuel figure → no wasted-litres badge');
      // Impact is the time-share (~1.0) rather than litres.
      expect(lesson.impact, closeTo(1.0, 1e-9));
    });
  });

  group('SmoothDrivingRule (#2287)', () {
    const rule = SmoothDrivingRule();

    test('fires (praise) on a real, moved, harsh-event-free trip', () {
      final lesson = rule.evaluate(ctx(summary(), calmCruiseSamples()), l);
      expect(lesson, isNotNull);
      expect(lesson!.id, smoothDrivingLessonId);
      expect(lesson.title, isNotEmpty);
      expect(lesson.advice, isNotEmpty);
      // Praise ranks below any real waste lesson.
      expect(lesson.impact, lessThan(0.01));
    });

    test('does NOT fire when the trip had a harsh event', () {
      // 0 → 40 km/h in 1 s ≈ 11 m/s² — a harsh acceleration.
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 1000),
        TripSample(
            timestamp: start.add(const Duration(seconds: 1)),
            speedKmh: 40,
            rpm: 3200),
        TripSample(
            timestamp: start.add(const Duration(seconds: 60)),
            speedKmh: 45,
            rpm: 2000),
      ];
      expect(rule.evaluate(ctx(summary(), samples), l), isNull);
    });

    test('does NOT fire on a pure-idle dwell (no real movement)', () {
      final samples = <TripSample>[
        for (var i = 0; i <= 5; i++)
          TripSample(
              timestamp: start.add(Duration(minutes: i)),
              speedKmh: 0,
              rpm: 800),
      ];
      // Distance summary says 5 km, but the samples never moved.
      expect(rule.evaluate(ctx(summary(distanceKm: 5), samples), l), isNull);
    });

    test('does NOT fire on a too-short trip', () {
      expect(
        rule.evaluate(ctx(summary(distanceKm: 1.0), calmCruiseSamples()), l),
        isNull,
      );
    });
  });

  group('countHarshEvents helper (#2287)', () {
    test('counts each harsh accel + decel crossing', () {
      final samples = <TripSample>[
        TripSample(timestamp: start, speedKmh: 0, rpm: 1000),
        // harsh accel
        TripSample(
            timestamp: start.add(const Duration(seconds: 1)),
            speedKmh: 40,
            rpm: 3000),
        // harsh brake
        TripSample(
            timestamp: start.add(const Duration(seconds: 2)),
            speedKmh: 5,
            rpm: 1200),
      ];
      expect(countHarshEvents(samples), 2);
    });

    test('zero for a calm cruise', () {
      expect(countHarshEvents(calmCruiseSamples()), 0);
    });
  });
}
