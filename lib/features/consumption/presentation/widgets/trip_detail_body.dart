// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/gamification_enabled_provider.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/driving_insights_analyzer.dart';
import '../../data/driving_score_calculator.dart';
import '../../data/lessons/driving_lesson_registry.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/driving_insight.dart';
import '../../domain/driving_score.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/lessons/driving_lesson.dart';
import '../../domain/lessons/driving_lesson_rule.dart';
import '../../domain/services/throttle_rpm_histogram_calculator.dart';
import '../../domain/trip_recorder.dart';
import 'driving_analysis_trace_card.dart';
import 'driving_insights_card.dart';
import 'driving_score_card.dart';
import 'gps_diagnostics_card.dart';
import 'gps_efficiency_kpi_card.dart';
import 'gps_road_usage_card.dart';
import 'obd2_diagnostics_trip_card.dart';
import 'imu_accel_brake_card.dart';
import 'throttle_rpm_histogram_card.dart';
import 'trip_detail_charts.dart';
import 'trip_detail_charts_section.dart';
import 'trip_detail_to_trip_sample.dart';
import 'trip_path_map_card.dart';
import 'trip_summary_card.dart';

/// Scrollable body of the trip detail screen (#890): summary card
/// followed by the driving-insights cost-line card (#1041 phase 2)
/// and speed / fuel-rate / RPM line charts.
///
/// Uses [SingleChildScrollView] + [Column] (not a [ListView]) so every
/// section stays in the widget tree — simplifies widget tests that
/// assert on the presence / absence of the RPM chart below the fold,
/// and keeps the screen compatible with [scrollUntilVisible] when the
/// profile is long enough to require actual scrolling.
///
/// Stateful only so the [DrivingInsight] analysis is cached across
/// rebuilds (the parent rebuilds on every Riverpod tick from the trip
/// history list / vehicle providers). The analyzer is O(n) and
/// pure, but for a 60-min trip that's still ~3 600 samples — re-running
/// it on every theme switch / locale switch is wasteful.
class TripDetailBody extends ConsumerStatefulWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final List<TripDetailSample> samples;
  final bool isEv;

  /// Optional [RepaintBoundary] key supplied by the parent screen so
  /// the Share action (#1189) can rasterise the report into a PNG. The
  /// key is hooked into the [RepaintBoundary] that wraps the report
  /// content (Summary card + Insights cards + charts) — i.e. the
  /// widget subtree the user expects to share.
  final GlobalKey? shareBoundaryKey;

  const TripDetailBody({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.samples,
    required this.isEv,
    this.shareBoundaryKey,
  });

  @override
  ConsumerState<TripDetailBody> createState() => _TripDetailBodyState();
}

class _TripDetailBodyState extends ConsumerState<TripDetailBody> {
  /// Lazily-computed driving insights for the trip. Cached for the
  /// lifetime of this State so locale / theme rebuilds don't re-run
  /// the analyzer. The widget tree is rebuilt from scratch (new State)
  /// when the user navigates to a different trip — that's the natural
  /// invalidation boundary, no manual cache key needed.
  late final List<DrivingInsight> _insights = _computeInsights();

  /// Lazily-computed throttle / RPM time-share histogram (#1041 phase
  /// 3a). Cached alongside [_insights] for the same reason — the
  /// calculator is O(n), pure, and cheap, but a long trip ticks at
  /// ~1 Hz so re-running on every rebuild adds up.
  ///
  /// Persisted [TripSample]s carry both RPM and throttle % (#1261).
  /// Cars without PID 0x11 still emit null throttle on every sample —
  /// the calculator treats those nulls as "skip on the throttle axis"
  /// so the RPM bars render alone in that case.
  late final ThrottleRpmHistogram _histogram = _computeHistogram();

  /// Lazily-computed composite driving score (#1041 phase 5a — Card A).
  /// Cached alongside [_insights] and [_histogram] for the same
  /// reason — the calculator is O(n), pure, and cheap, but a long trip
  /// ticks at ~1 Hz so re-running on every locale / theme rebuild adds
  /// up. EV trips and empty trips return [DrivingScore.perfect] from
  /// the calculator; the parent gates rendering on the same conditions
  /// it uses for [DrivingInsightsCard] so the card is hidden in those
  /// cases.
  late final DrivingScore _score = _computeScore();

  /// The post-trip lesson registry (#2251). Stateless and cheap to
  /// construct; held for the lifetime of this State so `build` reuses
  /// the same instance across rebuilds. The card's lessons are resolved
  /// in `build` (they depend on the active locale) but off the cached
  /// [_insights] / [_score], so the O(n) analyzer / score passes don't
  /// re-run on a theme / locale tick.
  final DrivingLessonRegistry _lessonRegistry =
      DrivingLessonRegistry.standard();

  /// GPS-only efficiency features (#2697 P3) — null for OBD2/EV/empty.
  late final GpsDrivingFeatures? _gpsFeatures = GpsEfficiencyKpiCard
      .featuresFor(widget.samples.map(tripDetailToTripSample), isEv: widget.isEv);

  List<DrivingInsight> _computeInsights() {
    if (widget.samples.isEmpty) return const [];
    // Insights are only meaningful for combustion trips — EV trips
    // don't have RPM, hard-accel waste, or idling fuel cost in the
    // same sense. Phase 1's analyzer would still surface hard-accel
    // events for EVs, but framing it as "wasted L" would be wrong.
    // Skip the analysis for EVs entirely; phase 4 will revisit once
    // the kWh equivalent lands.
    if (widget.isEv) return const [];
    final tripSamples = widget.samples.map(tripDetailToTripSample).toList(
          growable: false,
        );
    return analyzeTrip(tripSamples);
  }

  DrivingScore _computeScore() {
    if (widget.samples.isEmpty) return DrivingScore.perfect;
    if (widget.isEv) return DrivingScore.perfect;
    final tripSamples = widget.samples.map(tripDetailToTripSample).toList(
          growable: false,
        );
    final summary = widget.entry.summary;
    // #2460 — thread the trip-end lugging metric stored on the summary
    // into the canonical score so the over-rev/shift family includes it
    // (the calculator can't recompute gear inference from samples alone).
    //
    // #2794 — for a GPS-only trip, score against the pipeline's RESOLVED harsh
    // counts (IMU-preferred when the inertial sensor was the better dongle-less
    // signal) instead of re-deriving from the noisy GPS speed derivative, so
    // the displayed score matches the figure the recorder intended.
    final gpsOnly = summary.kind == TripKind.gpsOnly;
    return computeDrivingScore(
      tripSamples,
      secondsBelowOptimalGear: summary.secondsBelowOptimalGear,
      hardAccelEventsOverride: gpsOnly ? summary.harshAccelerations : null,
      hardBrakeEventsOverride: gpsOnly ? summary.harshBrakes : null,
    );
  }

  ThrottleRpmHistogram _computeHistogram() {
    if (widget.samples.isEmpty) return ThrottleRpmHistogram.empty;
    // EV trips skip the histogram for the same reason they skip
    // [DrivingInsightsCard] — RPM doesn't model EV motor behaviour
    // and "throttle %" maps differently. Phase 4 will revisit.
    if (widget.isEv) return ThrottleRpmHistogram.empty;
    final histogramSamples = widget.samples
        .map(
          (s) => ThrottleRpmSample(
            timestamp: s.timestamp,
            // #1261: persisted samples now carry throttle %. Cars
            // without PID 0x11 still emit null and the calculator
            // treats nulls as "skip on the throttle axis" so the
            // RPM bars render alone for those trips.
            throttlePercent: s.throttlePercent,
            rpm: s.rpm,
          ),
        )
        .toList(growable: false);
    return calculateThrottleRpmHistogram(histogramSamples);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // #1194 — gamification opt-out gates the composite driving score
    // card. The underlying calculator still runs (cheap, pure) so
    // toggling back on instantly restores the score without a re-render.
    final showGamification = ref.watch(gamificationEnabledProvider);

    // Post-trip lessons (#2251) — resolved here because the localized
    // titles depend on the active locale, but built off the cached
    // [_insights] / [_score] (and the stored summary) so the O(n)
    // analyzer / score passes don't re-run on a theme / locale rebuild.
    // Empty for EV / empty trips on the same gating rule as the card
    // below, and the registry returns [] when no rule fires (the
    // empty-state path). `l == null` only in degenerate test harnesses;
    // fall back to no lessons rather than crash.
    final List<DrivingLesson> lessons =
        (l == null || widget.isEv || widget.samples.isEmpty)
            ? const []
            : _lessonRegistry.evaluateContext(
                LessonContext(
                  summary: widget.entry.summary,
                  samples: widget.samples.map(tripDetailToTripSample).toList(
                        growable: false,
                      ),
                  score: _score,
                  insights: _insights,
                ),
                l,
              );

    // Wrap the report content in a [RepaintBoundary] so the Share
    // action (#1189) can call `boundary.toImage(...)` to produce a PNG
    // for the OS share sheet. The boundary covers Summary + Insights
    // cards + charts — i.e. everything visible above the share button
    // (which lives on the AppBar, outside the scroll view).
    final reportContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripSummaryCard(
          entry: widget.entry,
          vehicle: widget.vehicle,
          samples: widget.samples,
          isEv: widget.isEv,
        ),
        const SizedBox(height: 8),
        // GPS path overlay (#1374 phase 2). Self-suppresses when the
        // trip carries no GPS samples — legacy trips, opted-out trips,
        // trips that never got a fix — so no parent-side gating is
        // needed and the layout stays unchanged for those trips.
        // Phase 3 will replace the single-colour polyline with a
        // per-segment heatmap.
        TripPathMapCard(samples: widget.samples),
        // Composite driving score (#1041 phase 5a — Card A). Sits at
        // the top of the Insights group: a single big 0..100 number
        // with a brief breakdown chip row beneath it. EV trips and
        // empty trips are skipped on the same gating rule as the
        // cost-line card below. #1194: also gated by gamification
        // toggle (the score is the most game-like trip element).
        if (showGamification && !widget.isEv && widget.samples.isNotEmpty)
          DrivingScoreCard(score: _score),
        // Driving insights — combustion trips only. EV trips skip
        // this card; phase 4 will land an EV-aware version. Since #2251
        // the card renders the registry's ranked lessons (high-RPM,
        // hard-accel, idling, and the low-gear coaching row) — the same
        // rows the inline analyzer + gear metric produced before.
        if (!widget.isEv && widget.samples.isNotEmpty)
          DrivingInsightsCard(lessons: lessons),
        // Throttle / RPM histogram (#1041 phase 3a — Card C). Slotted
        // right below the insights card so the user reads "what was
        // wasteful" then immediately sees "here's the engine
        // distribution that produced that".
        //
        // #2796 C7 — gated to OBD2/engine-signal trips only. On a GPS-only
        // trip (`_gpsFeatures != null`) throttle % and RPM are absent on
        // every sample, so the card could only ever render its "no samples"
        // empty state — dead UI. `_gpsFeatures != null` is the exact
        // complement [GpsEfficiencyKpiCard.featuresFor] already computed
        // (it returns features only when NO sample carried an engine RPM),
        // so the two cards are mutually exclusive without re-scanning the
        // samples. EV / empty trips still skip both.
        if (!widget.isEv && widget.samples.isNotEmpty && _gpsFeatures == null)
          ThrottleRpmHistogramCard(histogram: _histogram),
        // GPS-only efficiency KPIs (#2697 P3) — only for engine-signal-less trips.
        if (_gpsFeatures != null)
          GpsEfficiencyKpiCard(features: _gpsFeatures),
        // #2796 C7 — the GPS-only replacement for the throttle/RPM card: a
        // speed-only "how you used the road" panel (speed-band + movement-
        // phase shares + a positive coasting line). Same gate as the KPI
        // card above so the GPS-only trip gets the road-use view exactly
        // where the engine card would have sat for an OBD2 trip.
        if (_gpsFeatures != null) GpsRoadUsageCard(features: _gpsFeatures),
        // #2792 — dongle-less hard-accel/brake/sharp-corner counts the phone IMU
        // detected on a GPS-only trip (persisted but previously surfaced
        // nowhere). Shown only when at least one harsh event was recorded.
        if (ImuAccelBrakeCard.summaryFor(widget.entry.summary) != null)
          ImuAccelBrakeCard(summary: widget.entry.summary),
        // GPS sample diagnostics inspector (#1458 phase 2.5).
        // Read-only — rendered only when at least one diagnostic was
        // captured (legacy trips and flag-off trips skip this card so
        // their layout is unchanged). Phase 3 (Android foreground GPS
        // service) is conditional on what this card surfaces during
        // field testing.
        if (widget.entry.gpsSampleDiagnostics.isNotEmpty)
          GpsDiagnosticsCard(
            diagnostics: widget.entry.gpsSampleDiagnostics,
          ),
        // OBD2 communication-health diagnostics (#2470). Dev-only — the
        // card self-hides unless Feature.debugMode is on AND a session was
        // captured, the OBD2 analogue of the GPS card above.
        const Obd2DiagnosticsTripCard(),
        // Driving-analysis trace export (#2804). Dev-only — self-hides unless
        // Feature.debugMode is on. Exports this trip's KPIs / score / lessons
        // as an annotatable JSON so the maintainer can label real trips and
        // calibrate the GPS verdict thresholds (Epic #2789 C6).
        if (!widget.isEv && widget.samples.isNotEmpty)
          DrivingAnalysisTraceCard(
            summary: widget.entry.summary,
            score: _score,
            lessons: lessons,
            gpsFeatures: _gpsFeatures,
          ),
        // #1895 — the per-trip telemetry charts, folded into one
        // collapsed-by-default section. Extracted to its own widget (#2804)
        // so this file stays under the 400-line norm; each chart still
        // self-gates on its own non-null signal.
        TripDetailChartsSection(samples: widget.samples),
      ],
    );

    return SingleChildScrollView(
      key: const Key('trip_detail_scroll'),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: RepaintBoundary(
        key: widget.shareBoundaryKey,
        child: Material(
          // Painting the report into a PNG outside the screen's surface
          // strips the [Scaffold] background, so wrap the boundary in
          // a [Material] with the theme's surface colour. This keeps
          // the captured image readable when shared into a chat where
          // the receiver has a dark background.
          color: Theme.of(context).colorScheme.surface,
          child: reportContent,
        ),
      ),
    );
  }
}

