// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';

/// Lesson id for the hard-braking coaching line. Stable, non-localized.
const String hardBrakeLessonId = 'hardBrake';

/// Hard-braking lesson (#2793). The companion to [HardAccelRule]: there is a
/// hard-acceleration lesson but, before this, no hard-braking one — even though
/// the phone IMU detects braking episodes on a GPS-only (dongle-less) trip.
///
/// Fires when the IMU detected at least one hard-braking episode
/// ([TripSummary.imuHardBrakeCount] > 0 — non-zero only on a GPS-only trip
/// whose inertial sensor ran). Impact = the episode count so it ranks among
/// the cost lines by severity. Negative polarity (waste), so the card paints it
/// with the warning tint, not the praise green (#2791).
class HardBrakeRule implements DrivingLessonRule {
  const HardBrakeRule();

  @override
  String get id => hardBrakeLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final count = context.summary.imuHardBrakeCount;
    if (count <= 0) return null;
    return DrivingLesson(
      id: id,
      impact: count.toDouble(),
      metricValue: count.toDouble(),
      title: l.lessonHardBrake(count.toString()),
      advice: l.lessonAdviceHardBrake,
    );
  }
}
