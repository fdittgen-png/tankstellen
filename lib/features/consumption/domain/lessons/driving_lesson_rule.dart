// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../l10n/app_localizations.dart';
import '../driving_insight.dart';
import '../driving_score.dart';
import '../trip_recorder.dart';
import 'driving_lesson.dart';

/// Pre-computed inputs shared across every [DrivingLessonRule] for a
/// single trip evaluation (#2251).
///
/// The legacy cost-line analyzer (`analyzeTrip`) does ONE O(n) pass
/// that produces all three behaviour categories at once, ranked by
/// waste. To migrate those into independent rules WITHOUT either
/// re-running that pass per rule or perturbing the numbers, the registry
/// runs the analyzer once and hands the resulting [insights] to the
/// rules through this context. A cost-line rule then simply looks up its
/// own [DrivingInsight] by label key and re-expresses it as a
/// [DrivingLesson] — guaranteeing the migrated lessons are bit-for-bit
/// the same coaching the card showed before.
///
/// Metric-only rules (e.g. low-gear) read [summary] directly and ignore
/// [insights]. The [score] is threaded through for future rules
/// (the OBD2-audit lessons in epic #2231) that key off the composite
/// driving score; the migrated rules don't need it.
class LessonContext {
  /// Trip-level aggregate metrics (idle/high-RPM seconds, cold-start,
  /// seconds-below-optimal-gear, …).
  final TripSummary summary;

  /// The raw per-tick samples for the trip, timestamp order not
  /// guaranteed — rules that iterate must sort defensively (the
  /// migrated cost lines delegate to [insights] so they don't).
  final List<TripSample> samples;

  /// Composite 0..100 driving score for the trip. Provided for rules
  /// that coach off the score directly; the migrated cost-line / gear
  /// rules don't read it.
  final DrivingScore score;

  /// The legacy analyzer's ranked cost lines for this trip. Cost-line
  /// rules read their own entry from here so the migrated lessons match
  /// the pre-#2251 behaviour exactly. Empty for trips the analyzer
  /// found nothing in (the empty-state path).
  final List<DrivingInsight> insights;

  const LessonContext({
    required this.summary,
    required this.samples,
    required this.score,
    required this.insights,
  });

  /// The cost line with the given [labelKey], or null when the analyzer
  /// did not surface that category for this trip. Used by cost-line
  /// rules to find their migrated metric.
  DrivingInsight? insightFor(String labelKey) {
    for (final insight in insights) {
      if (insight.labelKey == labelKey) return insight;
    }
    return null;
  }
}

/// Strategy interface — one self-contained post-trip coaching rule
/// (#2251).
///
/// Each rule inspects a trip and returns a [DrivingLesson] when its
/// triggering metric fires, or `null` when it does not. Adding a new
/// post-trip lesson is implementing this interface in its own file and
/// registering the instance in `DrivingLessonRegistry.standard` — no
/// edits to the calculator, the card, or the GPX exporter.
///
/// The [evaluate] signature matches the issue spec — `(summary,
/// samples, score, l)` — with the pre-computed analyzer output threaded
/// in via [context] so the migrated rules stay behaviour-preserving and
/// the registry pays the O(n) analyzer cost once, not once per rule.
abstract interface class DrivingLessonRule {
  /// Stable id of the lesson this rule emits (matches
  /// [DrivingLesson.id]). Exposed so the registry can assert
  /// id-uniqueness and tests can enumerate the registered rules.
  String get id;

  /// Evaluate the trip. Returns the firing [DrivingLesson], or `null`
  /// when this rule's metric did not trip for this trip.
  ///
  /// [l] resolves the localized title + advice — the rule bakes NO
  /// English literal; it pulls every user-facing string from
  /// [AppLocalizations].
  DrivingLesson? evaluate(LessonContext context, AppLocalizations l);
}
