// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/fuel_event_attribution.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the high-RPM-cruise upshift saving. Stable,
/// non-localized (GPX extension attribute + insight tile key).
const String upshiftCruiseLessonId = 'upshiftCruise';

/// Litres below which the lesson is noise — canonical with the
/// analyzer's `_noiseFloorLiters`.
const double kUpshiftCruiseNoiseFloorLiters = 0.05;

/// High-RPM **cruising** upshift lesson (#3432, epic #3416 task 7).
///
/// Fires when the per-event fuel attribution found steady-speed
/// cruising at ≥ ~2800 RPM — i.e. windows where an earlier upshift was
/// actually available — and estimates the litres it would have saved
/// (rate-delta heuristic, see `fuel_event_attribution.dart`).
///
/// Deliberately NARROWER than `HighRpmRule` ('highRpm' — total time
/// over 3000 RPM, accelerating or not): this one only counts steady
/// cruise windows, so its advice ("shift up earlier when cruising") is
/// directly actionable where the general lesson is descriptive. The
/// two can co-fire on the same trip; they rank independently by their
/// own litres.
///
/// Own O(n) pass over the samples (the `HighSpeedBandRule` precedent) —
/// the attribution detector is pure and cheap at trip sizes.
class UpshiftCruiseRule implements DrivingLessonRule {
  const UpshiftCruiseRule();

  @override
  String get id => upshiftCruiseLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final attribution = FuelAttribution.fromSamples(context.samples);
    final liters = attribution.highRpmCruiseLiters;
    if (liters < kUpshiftCruiseNoiseFloorLiters) return null;

    final litersText = formatLessonLiters(liters);
    final pct = formatLessonPercent(
        attribution.percentOfTrip(FuelEventType.highRpmCruise));
    return DrivingLesson(
      id: id,
      impact: liters,
      metricValue: liters,
      title: l.insightUpshiftCruise(pct, litersText),
      advice: l.lessonAdviceUpshiftCruise,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersWasted(litersText),
    );
  }
}
