// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/fuel_event_attribution.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the fuel-cut coasting praise. Stable, non-localized.
const String coastingFuelCutLessonId = 'coastingFuelCut';

/// Saved litres below which the praise stays silent — canonical with
/// the analyzer's `_noiseFloorLiters`.
const double kCoastingNoiseFloorLiters = 0.05;

/// Fuel-cut coasting recognition lesson (#3432, epic #3416 task 7) —
/// a POSITIVE lesson alongside `SmoothDrivingRule`.
///
/// Fires when the per-event fuel attribution recognised genuine
/// deceleration-fuel-cut phases (measured rate ≈ 0 while moving) and
/// the estimated saving vs an injected-idle counterfactual clears the
/// noise floor. Requires a measured fuel-rate PID by construction —
/// GPS-only trips never earn this praise (a fuel cut is unrecognisable
/// without the fuel signal), which keeps the badge honest.
///
/// Impact is a small fixed praise weight (marginally above the
/// smooth-driving praise so the *quantified* saving ranks first among
/// praise, but below every real waste lesson).
class CoastingRecognitionRule implements DrivingLessonRule {
  const CoastingRecognitionRule();

  /// Fixed low ranking weight — praise never outranks a waste lesson.
  static const double _praiseImpact = 0.002;

  @override
  String get id => coastingFuelCutLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final attribution = FuelAttribution.fromSamples(context.samples);
    final saved = attribution.coastingSavedLiters;
    if (saved < kCoastingNoiseFloorLiters) return null;

    final litersText = formatLessonLiters(saved);
    final pct =
        formatLessonPercent(attribution.percentOfTrip(FuelEventType.coasting));
    return DrivingLesson(
      id: id,
      impact: _praiseImpact,
      metricValue: saved,
      title: l.insightCoastingFuelCut(pct, litersText),
      advice: l.lessonAdviceCoastingFuelCut,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: l.insightTrailingLitersSaved(litersText),
      // #2791 — praise, not waste: render green, not error-red.
      polarity: LessonPolarity.positive,
    );
  }
}
