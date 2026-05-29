// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/lessons/driving_lesson_registry.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/hard_accel_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/high_rpm_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/high_speed_band_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/idling_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/low_gear_rule.dart';
import 'package:tankstellen/features/consumption/data/lessons/rules/smooth_driving_rule.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

/// Registry + rule coverage for the post-trip driving-lessons registry
/// (#2251).
///
/// Each rule must fire on its triggering metric and skip otherwise; the
/// registry must rank firing lessons by impact (low-gear above the
/// litres-wasted cost lines, cost lines by waste desc); and an
/// exhaustiveness test pins the registered rule set + a known trip's
/// expected lesson ids.
void main() {
  final AppLocalizations l = AppLocalizationsEn();
  final start = DateTime.utc(2026);

  TripSummary summary({double? secondsBelowOptimalGear}) => TripSummary(
        distanceKm: 5,
        maxRpm: 4000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        secondsBelowOptimalGear: secondsBelowOptimalGear,
      );

  // A 20-minute pure-idle trip — fires only the idling rule.
  List<TripSample> idleSamples() {
    final samples = <TripSample>[];
    for (var i = 0; i <= 20; i++) {
      samples.add(TripSample(
        timestamp: start.add(Duration(minutes: i)),
        speedKmh: 0,
        rpm: 800,
      ));
    }
    return samples;
  }

  // A sustained high-RPM cruise — fires only the high-RPM rule.
  List<TripSample> highRpmSamples() => <TripSample>[
        TripSample(
            timestamp: start, speedKmh: 80, rpm: 4000, fuelRateLPerHour: 12),
        TripSample(
            timestamp: start.add(const Duration(seconds: 600)),
            speedKmh: 80,
            rpm: 4000,
            fuelRateLPerHour: 12),
      ];

  // Five strong accelerations separated by cruising — fires only the
  // hard-accel rule.
  List<TripSample> hardAccelSamples() {
    var t = start;
    final samples = <TripSample>[];
    for (var i = 0; i < 5; i++) {
      samples.add(TripSample(timestamp: t, speedKmh: 0, rpm: 1000));
      t = t.add(const Duration(seconds: 2));
      samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 3000));
      t = t.add(const Duration(seconds: 10));
      samples.add(TripSample(timestamp: t, speedKmh: 50, rpm: 2000));
      t = t.add(const Duration(seconds: 1));
    }
    return samples;
  }

  group('registered rule set', () {
    test('standard registry registers the migrated rules + the #2287 '
        'analytics lessons, in declaration order', () {
      final reg = DrivingLessonRegistry.standard();
      expect(
        reg.rules.map((r) => r.id).toList(),
        [
          lowGearLessonId,
          highRpmLessonId,
          hardAccelLessonId,
          idlingLessonId,
          highSpeedBandLessonId,
          smoothDrivingLessonId,
        ],
      );
    });

    test('rule ids are unique (registry asserts)', () {
      // Constructing with a duplicate id trips the assert in debug.
      expect(
        () => DrivingLessonRegistry(const [IdlingRule(), IdlingRule()]),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('each rule fires on its metric and is skipped otherwise', () {
    test('idling rule fires on an idle trip, skipped on a high-RPM trip', () {
      final reg = DrivingLessonRegistry.standard();
      final onIdle = reg.evaluate(summary(), idleSamples(), l);
      expect(onIdle.map((e) => e.id), contains(idlingLessonId));

      final onHighRpm = reg.evaluate(summary(), highRpmSamples(), l);
      expect(onHighRpm.map((e) => e.id), isNot(contains(idlingLessonId)));
    });

    test('high-RPM rule fires on a high-RPM trip, skipped on an idle trip', () {
      final reg = DrivingLessonRegistry.standard();
      final onHighRpm = reg.evaluate(summary(), highRpmSamples(), l);
      expect(onHighRpm.map((e) => e.id), contains(highRpmLessonId));

      final onIdle = reg.evaluate(summary(), idleSamples(), l);
      expect(onIdle.map((e) => e.id), isNot(contains(highRpmLessonId)));
    });

    test('hard-accel rule fires on a hard-accel trip, skipped on idle', () {
      final reg = DrivingLessonRegistry.standard();
      final onHardAccel = reg.evaluate(summary(), hardAccelSamples(), l);
      expect(onHardAccel.map((e) => e.id), contains(hardAccelLessonId));

      final onIdle = reg.evaluate(summary(), idleSamples(), l);
      expect(onIdle.map((e) => e.id), isNot(contains(hardAccelLessonId)));
    });

    test('low-gear rule fires only when secondsBelowOptimalGear > 60', () {
      final reg = DrivingLessonRegistry.standard();

      // Below / at the boundary → no low-gear lesson.
      expect(
        reg.evaluate(summary(secondsBelowOptimalGear: 60), idleSamples(), l)
            .map((e) => e.id),
        isNot(contains(lowGearLessonId)),
      );
      // null → no low-gear lesson.
      expect(
        reg.evaluate(summary(), idleSamples(), l).map((e) => e.id),
        isNot(contains(lowGearLessonId)),
      );
      // Above → fires.
      final fired =
          reg.evaluate(summary(secondsBelowOptimalGear: 180), idleSamples(), l);
      final lowGear = fired.firstWhere((e) => e.id == lowGearLessonId);
      expect(lowGear.title, 'Labouring in low gear (3 min)');
      expect(lowGear.metricValue, 180);
      // No subtitle / trailing — matches the legacy gear-coaching row.
      expect(lowGear.subtitle, isNull);
      expect(lowGear.trailing, isNull);
    });
  });

  group('ranking by impact', () {
    test('low-gear lesson is ranked above the litres-wasted cost lines', () {
      final reg = DrivingLessonRegistry.standard();
      final lessons = reg.evaluate(
        summary(secondsBelowOptimalGear: 180),
        idleSamples(),
        l,
      );
      expect(lessons.first.id, lowGearLessonId);
      // Idling cost line follows.
      expect(lessons.map((e) => e.id), contains(idlingLessonId));
    });

    test('cost lines are ranked by litres wasted descending', () {
      // High-RPM (~1.6 L over the trip) dominates idling (~0.2 L). A
      // trip carrying both must order high-RPM before idling.
      final reg = DrivingLessonRegistry.standard();
      final samples = <TripSample>[
        TripSample(
            timestamp: start, speedKmh: 80, rpm: 4000, fuelRateLPerHour: 12),
        TripSample(
            timestamp: start.add(const Duration(seconds: 300)),
            speedKmh: 80,
            rpm: 4000,
            fuelRateLPerHour: 12),
        TripSample(
            timestamp: start.add(const Duration(seconds: 1200)),
            speedKmh: 0,
            rpm: 800),
        TripSample(
            timestamp: start.add(const Duration(seconds: 2400)),
            speedKmh: 0,
            rpm: 800),
      ];

      final lessons = reg.evaluate(summary(), samples, l);
      final ids = lessons.map((e) => e.id).toList();
      expect(ids.indexOf(highRpmLessonId),
          lessThan(ids.indexOf(idlingLessonId)));
      // Impact is monotonically non-increasing.
      for (var i = 1; i < lessons.length; i++) {
        expect(lessons[i - 1].impact,
            greaterThanOrEqualTo(lessons[i].impact));
      }
    });
  });

  group('exhaustiveness — known trips yield the expected lesson set', () {
    test('pure-idle trip → exactly [idling]', () {
      final reg = DrivingLessonRegistry.standard();
      final lessons = reg.evaluate(summary(), idleSamples(), l);
      expect(lessons.map((e) => e.id).toList(), [idlingLessonId]);
    });

    test('clean short cruise + no low gear → no waste lessons, only the '
        'smooth-driving praise (#2287)', () {
      final reg = DrivingLessonRegistry.standard();
      final samples = <TripSample>[
        TripSample(
            timestamp: start, speedKmh: 50, rpm: 2000, fuelRateLPerHour: 5),
        TripSample(
            timestamp: start.add(const Duration(seconds: 5)),
            speedKmh: 51,
            rpm: 2000,
            fuelRateLPerHour: 5),
        TripSample(
            timestamp: start.add(const Duration(seconds: 10)),
            speedKmh: 50,
            rpm: 2000,
            fuelRateLPerHour: 5),
      ];
      final lessons = reg.evaluate(summary(), samples, l);
      // A clean cruise IS smooth driving — the only lesson is the praise.
      expect(lessons.map((e) => e.id).toList(), [smoothDrivingLessonId]);
    });

    test('idle trip with low gear → [lowGear, idling] in that order', () {
      final reg = DrivingLessonRegistry.standard();
      final lessons = reg.evaluate(
        summary(secondsBelowOptimalGear: 120),
        idleSamples(),
        l,
      );
      expect(lessons.map((e) => e.id).toList(), [lowGearLessonId, idlingLessonId]);
    });
  });

  group('migrated cost-line lessons re-state the legacy card copy', () {
    test('idling lesson carries the legacy title / subtitle / trailing', () {
      final reg = DrivingLessonRegistry.standard();
      final lessons = reg.evaluate(summary(), idleSamples(), l);
      final idling = lessons.firstWhere((e) => e.id == idlingLessonId);
      // 20 min idle at 0.6 L/h ≈ 0.2 L, 100 % of the trip.
      expect(idling.title, 'Idling (100% of trip): wasted 0.2 L');
      expect(idling.subtitle, '100% of trip');
      expect(idling.trailing, '+0.2 L');
      expect(idling.advice, isNotEmpty);
    });

    test('hard-accel lesson carries the event-count headline', () {
      final reg = DrivingLessonRegistry.standard();
      final lessons = reg.evaluate(summary(), hardAccelSamples(), l);
      final hardAccel = lessons.firstWhere((e) => e.id == hardAccelLessonId);
      // 5 events × 0.05 L = 0.25 L → one-decimal "0.3" (rounds up).
      expect(hardAccel.title, '5 hard accelerations: wasted 0.3 L');
      expect(hardAccel.trailing, '+0.3 L');
    });
  });
}
