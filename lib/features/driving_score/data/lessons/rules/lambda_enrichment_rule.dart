// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/lessons/driving_lesson.dart';
import '../../../domain/lessons/driving_lesson_rule.dart';
import '../lesson_format.dart';

/// Lesson id for the λ-enrichment cost line (#2461). Stable, non-localized.
const String lambdaEnrichmentLessonId = 'lambdaEnrichment';

/// λ-enrichment coaching lesson (#2461 — surfaces the
/// `insightLambdaEnrichment` cost line).
///
/// Fires when the analyzer saw the ECU command a mixture richer than
/// stoichiometric (λ < 1, PID 0x44) for long enough that the extra fuel
/// over a stoich counterfactual cleared the noise floor. Enrichment is
/// triggered by heavy, sustained load (flooring it / long climbs), so the
/// advice points at the underlying driving rather than the symptom.
class LambdaEnrichmentRule implements DrivingLessonRule {
  const LambdaEnrichmentRule();

  @override
  String get id => lambdaEnrichmentLessonId;

  @override
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l) {
    final insight = context.insightFor('insightLambdaEnrichment');
    if (insight == null) return null;

    final pct = formatLessonPercent(insight.percentOfTrip);
    return DrivingLesson(
      id: id,
      impact: insight.percentOfTrip,
      metricValue: (insight.metadata['lambdaEnrichSeconds'] ?? 0).toDouble(),
      title: l.insightLambdaEnrichmentShare(pct),
      advice: l.lessonAdviceLambdaEnrichment,
      subtitle: l.insightSubtitlePctOfTrip(pct),
      trailing: approxLitersTrailing(insight, l), // #4221
    );
  }
}
