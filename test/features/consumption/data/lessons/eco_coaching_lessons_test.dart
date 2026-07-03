// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/lessons/driving_lesson_registry.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/coasting_recognition_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/upshift_cruise_rule.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

/// #3432 (epic #3416) — the per-event attribution lessons integrate
/// with the existing registry: new ids fire alongside the migrated
/// rules with correctly-quantified litres and the right polarity.
void main() {
  final AppLocalizations l = AppLocalizationsEn();
  final start = DateTime.utc(2026, 7, 1, 8);

  const summary = TripSummary(
    distanceKm: 20,
    maxRpm: 3200,
    highRpmSeconds: 0,
    idleSeconds: 0,
    harshBrakes: 0,
    harshAccelerations: 0,
    fuelLitersConsumed: 1.5,
    distanceSource: 'gps',
  );

  TripSample s(
    int second, {
    required double speed,
    double? rpm,
    double? rate,
    double? pedal,
  }) =>
      TripSample(
        timestamp: start.add(Duration(seconds: second)),
        speedKmh: speed,
        rpm: rpm,
        fuelRateLPerHour: rate,
        pedalPercent: pedal,
      );

  group('upshiftCruise lesson (#3432)', () {
    test('fires on sustained steady high-RPM cruising with the estimated '
        'saving as its litres', () {
      // 10 min at 3000 RPM / 80 km/h / 8 L/h → saving = 8 × 25 % ×
      // 600 s / 3600 = 0.333 L → formatted "0.3".
      final samples = [
        for (var i = 0; i <= 600; i++)
          s(i, speed: 80, rpm: 3000, rate: 8, pedal: 20),
      ];
      final lessons =
          DrivingLessonRegistry.standard().evaluate(summary, samples, l);
      final lesson =
          lessons.firstWhere((e) => e.id == upshiftCruiseLessonId);
      expect(lesson.metricValue, closeTo(8 * 0.25 * 600 / 3600, 1e-6));
      expect(lesson.title, contains('shifting up earlier could save 0.3 L'));
      expect(lesson.trailing, '+0.3 L');
      expect(lesson.polarity, LessonPolarity.negative);
    });

    test('does NOT fire on a low-RPM cruise', () {
      final samples = [
        for (var i = 0; i <= 120; i++)
          s(i, speed: 80, rpm: 2000, rate: 6, pedal: 20),
      ];
      final lessons =
          DrivingLessonRegistry.standard().evaluate(summary, samples, l);
      expect(
          lessons.map((e) => e.id), isNot(contains(upshiftCruiseLessonId)));
    });
  });

  group('coastingFuelCut lesson (#3432)', () {
    test('fires as a POSITIVE lesson with the litres-saved badge', () {
      // 400 s of fuel-cut coasting → saved = 0.6 L/h × 400 s ≈ 0.067 L
      // → formatted "0.1". Interleave cruise so the trip is realistic.
      final samples = [
        for (var i = 0; i <= 20; i++)
          s(i, speed: 80, rpm: 2200, rate: 6, pedal: 15),
        for (var i = 21; i <= 421; i++)
          s(i, speed: 70, rpm: 2000, rate: 0.0, pedal: 0),
        for (var i = 422; i <= 440; i++)
          s(i, speed: 60, rpm: 1800, rate: 5, pedal: 15),
      ];
      final lessons =
          DrivingLessonRegistry.standard().evaluate(summary, samples, l);
      final lesson =
          lessons.firstWhere((e) => e.id == coastingFuelCutLessonId);
      expect(lesson.polarity, LessonPolarity.positive);
      expect(lesson.metricValue, closeTo(0.6 * 401 / 3600, 1e-3));
      expect(lesson.trailing, '−0.1 L');
      expect(lesson.title, contains('saved about 0.1 L'));
    });

    test('never fires without a measured fuel-rate signal (GPS-only)', () {
      final samples = [
        for (var i = 0; i <= 600; i++) s(i, speed: 70),
      ];
      final lessons =
          DrivingLessonRegistry.standard().evaluate(summary, samples, l);
      expect(
          lessons.map((e) => e.id), isNot(contains(coastingFuelCutLessonId)));
    });

    test('praise ranks below every waste lesson but above the generic '
        'smooth-driving praise', () {
      // A trip with both a real waste lesson (idling) and the coasting
      // praise: the idle cost must outrank the praise.
      final samples = [
        // 10 min idle at 0.9 L/h → 0.15 L wasted.
        for (var i = 0; i <= 600; i++) s(i, speed: 0, rpm: 800, rate: 0.9),
        // 400 s fuel-cut coast.
        for (var i = 601; i <= 1001; i++)
          s(i, speed: 70, rpm: 2000, rate: 0.0, pedal: 0),
      ];
      final lessons =
          DrivingLessonRegistry.standard().evaluate(summary, samples, l);
      final ids = lessons.map((e) => e.id).toList();
      expect(ids, contains(coastingFuelCutLessonId));
      expect(ids.indexOf('idling'),
          lessThan(ids.indexOf(coastingFuelCutLessonId)));
    });
  });
}
