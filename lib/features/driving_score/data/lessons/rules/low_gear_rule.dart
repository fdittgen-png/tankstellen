// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';

/// Lesson id for the low-gear coaching row. Stable, non-localized.
const String lowGearLessonId = 'lowGear';

/// Impact weight for the low-gear lesson (#2251). Fixed and large so the
/// registry always ranks it ABOVE the litres-wasted cost lines —
/// mirroring the legacy card, which rendered the gear-coaching row above
/// the cost-line tiles. The cost lines' impact is litres wasted (a small
/// number, < ~2 L on realistic trips), so 1000 keeps the gear lesson on
/// top without coupling to any litre figure.
const double _lowGearImpact = 1000.0;

/// Low-gear lesson (#2251 — migrated from the gear-coaching row on the
/// driving-insights card, #1263 phase 3).
///
/// Fires when `TripSummary.secondsBelowOptimalGear` is non-null and
/// strictly greater than 60 — the exact `> 60` gate the legacy
/// `_LowGearTile` used. The minute count uses the same
/// `max(1, round(seconds / 60))` formatting so the headline is
/// identical. The lesson carries no litres figure (the legacy row had no
/// trailing badge), so [metricValue] is the seconds-below-optimal-gear
/// metric itself.
class LowGearRule implements DrivingLessonRule {
  const LowGearRule();

  @override
  String get id => lowGearLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final seconds = context.summary.secondsBelowOptimalGear;
    if (seconds == null || seconds <= 60) return null;

    // `max(1, round(seconds / 60))` — never display "0 minutes". The
    // `> 60` gate already guarantees round() >= 1; clamp defensively.
    final minutes = math.max(1, (seconds / 60).round()).toString();
    return DrivingLesson(
      id: id,
      impact: _lowGearImpact,
      metricValue: seconds,
      title: l.insightLowGear(minutes),
      advice: l.lessonAdviceLowGear,
    );
  }
}
