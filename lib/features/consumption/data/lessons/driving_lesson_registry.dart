// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_insight.dart';
import '../../domain/driving_score.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/lessons/driving_lesson_rule.dart';
import '../../domain/trip_recorder.dart';
import '../driving_insights_analyzer.dart';
import '../driving_score_calculator.dart';
import 'rules/climbing_cost_rule.dart';
import 'rules/combustion_health_rule.dart';
import 'rules/full_throttle_rule.dart';
import 'rules/hard_accel_rule.dart';
import 'rules/hard_brake_rule.dart';
import 'rules/high_rpm_rule.dart';
import 'rules/high_speed_band_rule.dart';
import 'rules/idling_rule.dart';
import 'rules/lambda_enrichment_rule.dart';
import 'rules/low_gear_rule.dart';
import 'rules/restart_cost_rule.dart';
import 'rules/sharp_cornering_rule.dart';
import 'rules/smooth_driving_rule.dart';

/// Holds the post-trip [DrivingLessonRule]s and turns a trip into its
/// ranked list of firing [DrivingLesson]s (#2251).
///
/// This is the single plug-in point the issue/epic asks for: the
/// trip-detail Insights card and the GPX exporter both render the output
/// of [evaluate]. Adding a lesson = add a rule file + one entry in
/// [standard] — no edits to the calculator, the card, or the exporter.
///
/// The registry runs the legacy cost-line analyzer (`analyzeTrip`) and
/// the composite score calculator ONCE, packs them into a
/// [LessonContext], and feeds every rule the same context — so the
/// migrated cost-line lessons are bit-for-bit the coaching the old card
/// showed, and the O(n) passes are paid once rather than per rule.
class DrivingLessonRegistry {
  /// The registered rules, in declaration order. Two rules may not share
  /// an [DrivingLessonRule.id] — the constructor asserts uniqueness so a
  /// duplicate is caught in debug/test rather than silently shadowing a
  /// lesson in the GPX export.
  final List<DrivingLessonRule> rules;

  DrivingLessonRegistry(this.rules)
      : assert(
          rules.map((r) => r.id).toSet().length == rules.length,
          'DrivingLessonRule ids must be unique',
        );

  /// The production registry — every post-trip lesson the trip-detail
  /// Insights group + the GPX export surface:
  ///   * [LowGearRule]       — labouring in too-low a gear (> 60 s) (#2251);
  ///   * [HighRpmRule]       — time over 3000 RPM (#2251);
  ///   * [HardAccelRule]     — hard-acceleration events (#2251);
  ///   * [IdlingRule]        — engine-on-stationary waste (#2251);
  ///   * [HighSpeedBandRule] — drag-dominated high-speed penalty (#2287);
  ///   * [FullThrottleRule]   — time at full throttle / pedal (#2461);
  ///   * [LambdaEnrichmentRule] — rich-mixture (λ < 1) fuel waste (#2461);
  ///   * [CombustionHealthRule] — heuristic mixture-health note from
  ///     sustained fuel trims + commanded enrichment (#2931);
  ///   * [SmoothDrivingRule] — positive reinforcement (#2287).
  ///
  /// Declaration order is the tie-break for equal-impact lessons (see
  /// [evaluate]); the low-gear rule is first so it keeps its
  /// rendered-above-cost-lines position, and the smooth-driving praise is
  /// last so it never outranks an actual waste lesson. The combustion-
  /// health heuristic sits just before the praise — a neutral health note
  /// that ranks below every quantified-waste lesson but above pure praise.
  factory DrivingLessonRegistry.standard() => DrivingLessonRegistry(const [
        LowGearRule(),
        HighRpmRule(),
        HardAccelRule(),
        IdlingRule(),
        HighSpeedBandRule(),
        FullThrottleRule(),
        LambdaEnrichmentRule(),
        ClimbingCostRule(),
        RestartCostRule(),
        HardBrakeRule(),
        SharpCorneringRule(),
        CombustionHealthRule(),
        SmoothDrivingRule(),
      ]);

  /// Evaluate every rule against the trip and return the firing lessons
  /// ranked by [DrivingLesson.impact] descending. Ties keep registration
  /// order (stable) so the output is deterministic.
  ///
  /// [score] / [insights] are optional — when omitted they are computed
  /// from [samples] (`computeDrivingScore` / `analyzeTrip`), so callers
  /// that don't already hold them (the GPX exporter) don't have to. The
  /// trip-detail body already caches both across rebuilds and passes
  /// them in to avoid re-running the O(n) passes on every locale / theme
  /// tick.
  List<DrivingLesson> evaluate(
    TripSummary summary,
    List<TripSample> samples,
    AppLocalizations l, {
    DrivingScore? score,
    List<DrivingInsight>? insights,
  }) {
    return evaluateContext(
      LessonContext(
        summary: summary,
        samples: samples,
        // #3368 — a virtual dead-reckoning trip's quantised speed manufactures
        // phantom harsh events; suppress them in the fallback score + insights.
        score: score ??
            computeDrivingScore(samples,
                suppressSpeedHarsh: summary.isVirtualSource),
        insights: insights ??
            analyzeTrip(samples, suppressSpeedHarsh: summary.isVirtualSource),
      ),
      l,
    );
  }

  /// Run every rule against an already-built [context] and return the
  /// firing lessons ranked by impact descending (ties → registration
  /// order, stable). The lower-level entry point for callers that
  /// already hold the analyzer output + score and want to avoid
  /// recomputing them.
  List<DrivingLesson> evaluateContext(
    LessonContext context,
    AppLocalizations l,
  ) {
    // Collect firing lessons, tagging each with its rule index so the
    // sort can break ties by registration order (Dart's List.sort is
    // not guaranteed stable).
    final fired = <(int, DrivingLesson)>[];
    for (var i = 0; i < rules.length; i++) {
      final lesson = rules[i].evaluate(context, l);
      if (lesson != null) fired.add((i, lesson));
    }

    fired.sort((a, b) {
      final byImpact = b.$2.impact.compareTo(a.$2.impact);
      if (byImpact != 0) return byImpact;
      return a.$1.compareTo(b.$1);
    });

    return fired.map((e) => e.$2).toList(growable: false);
  }
}
