// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';

/// Lesson id for the sharp-cornering coaching line. Stable, non-localized.
const String sharpCorneringLessonId = 'sharpCornering';

/// Sharp-cornering lesson (#2793). Cornering is detectable ONLY from the phone
/// IMU (lateral accel + yaw) — neither the GPS speed derivative nor OBD2 sees
/// it — so [TripSummary.sharpCornerCount] (#2760) was captured + persisted but
/// had no downstream consumer at all until this rule.
///
/// Fires when the IMU detected at least one sharp-cornering episode. Impact =
/// the episode count for severity ranking. Negative polarity (waste).
class SharpCorneringRule implements DrivingLessonRule {
  const SharpCorneringRule();

  @override
  String get id => sharpCorneringLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final count = context.summary.sharpCornerCount;
    if (count <= 0) return null;
    return DrivingLesson(
      id: id,
      impact: count.toDouble(),
      metricValue: count.toDouble(),
      title: l.lessonSharpCornering(count.toString()),
      advice: l.lessonAdviceSharpCornering,
    );
  }
}
