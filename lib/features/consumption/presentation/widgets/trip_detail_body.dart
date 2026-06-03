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
import 'driving_insights_card.dart';
import 'driving_score_card.dart';
import 'gps_diagnostics_card.dart';
import 'gps_efficiency_kpi_card.dart';
import 'obd2_diagnostics_trip_card.dart';
import 'imu_accel_brake_card.dart';
import 'throttle_rpm_histogram_card.dart';
import 'trip_chart_section.dart';
import 'trip_detail_charts.dart';
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

    // RPM section is hidden when every sample reports null (the car's
    // PID cache flagged RPM as unsupported). The summary card still
    // shows max-RPM for the trip because that's part of the stored
    // summary regardless of per-sample availability.
    final hasRpmSamples = widget.samples.any((s) => s.rpm != null);

    // Fuel-rate section (#2490) follows the same gating rule as RPM /
    // engine-load: when neither the MEASURED `fuelRateLPerHour` nor the
    // GPS-physics ESTIMATED series (#2431) has a single non-null sample,
    // [TripDetailFuelRateChart] would render its 140 px "Keine
    // Messwerte" empty card. Gate the section here so it disappears
    // entirely instead — mirroring the chart's own self-suppression
    // predicate so the section and the chart agree.
    final hasFuelRateSamples = widget.samples.any(
      (s) =>
          s.fuelRateLPerHour != null || s.estimatedFuelRateLPerHour != null,
    );

    // Engine-load section (#1262 phase 3) follows the same gating
    // rule as RPM: cars without PID 0x04 emit null on every sample
    // (legacy trips persisted before #1262 phase 1 also do), and we
    // silently skip the section header in that case rather than
    // rendering an empty card.
    final hasEngineLoadSamples =
        widget.samples.any((s) => s.engineLoadPercent != null);

    // #2461 — the new driving-signal chart sections follow the same
    // if-any-non-null gate as RPM / engine-load. Throttle/pedal renders
    // when EITHER pedal (PID 0x49-0x4B) or throttle (PID 0x11) is
    // present; coolant / altitude / λ each gate on their own signal.
    // Cars (and legacy trips) without the PID emit null on every sample,
    // so the section header is silently skipped.
    final hasThrottleSamples = widget.samples.any(
      (s) => s.pedalPercent != null || s.throttlePercent != null,
    );
    final hasCoolantSamples =
        widget.samples.any((s) => s.coolantTempC != null);
    final hasAltitudeSamples =
        widget.samples.any((s) => s.altitudeM != null);
    final hasLambdaSamples = widget.samples.any((s) => s.lambda != null);

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
        // distribution that produced that". Mirrors the EV-skip and
        // empty-samples-skip rules.
        if (!widget.isEv && widget.samples.isNotEmpty)
          ThrottleRpmHistogramCard(histogram: _histogram),
        // GPS-only efficiency KPIs (#2697 P3) — only for engine-signal-less trips.
        if (_gpsFeatures != null)
          GpsEfficiencyKpiCard(features: _gpsFeatures),
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
        // #1895 — the per-trip telemetry charts are folded into one
        // collapsible section, collapsed by default, so the summary
        // and insight cards above stay the focus on open. maintainState
        // keeps the chart widgets in the tree while collapsed — the
        // Share-to-PNG boundary and the widget tests both rely on every
        // section being present regardless of fold state.
        Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l?.trajetDetailChartsSection ?? 'Charts'),
            initiallyExpanded: false,
            maintainState: true,
            shape: const Border(),
            collapsedShape: const Border(),
            childrenPadding: const EdgeInsets.only(bottom: 4),
            children: [
              TripChartSection(
                title: l?.trajetDetailChartSpeed ?? 'Speed (km/h)',
                chart: TripDetailSpeedChart(samples: widget.samples),
              ),
              if (hasFuelRateSamples)
                TripChartSection(
                  title: l?.trajetDetailChartFuelRate ?? 'Fuel rate (L/h)',
                  chart: TripDetailFuelRateChart(samples: widget.samples),
                ),
              if (hasRpmSamples)
                TripChartSection(
                  title: l?.trajetDetailChartRpm ?? 'RPM',
                  chart: TripDetailRpmChart(samples: widget.samples),
                ),
              if (hasEngineLoadSamples)
                TripChartSection(
                  title: l?.trajetDetailChartEngineLoad ?? 'Engine load (%)',
                  chart: TripDetailEngineLoadChart(samples: widget.samples),
                ),
              // #2461 — driving-signal charts, each gated on its own
              // if-any-non-null signal (mirrors RPM / engine-load).
              if (hasThrottleSamples)
                TripChartSection(
                  title: l?.trajetDetailChartThrottle ?? 'Throttle / pedal (%)',
                  chart: TripDetailThrottleChart(samples: widget.samples),
                ),
              if (hasCoolantSamples)
                TripChartSection(
                  title: l?.trajetDetailChartCoolant ?? 'Coolant (°C)',
                  chart: TripDetailCoolantChart(samples: widget.samples),
                ),
              if (hasAltitudeSamples)
                TripChartSection(
                  title: l?.trajetDetailChartAltitude ?? 'Altitude (m)',
                  chart: TripDetailAltitudeChart(samples: widget.samples),
                ),
              if (hasLambdaSamples)
                TripChartSection(
                  title: l?.trajetDetailChartLambda ?? 'Commanded λ',
                  chart: TripDetailLambdaChart(samples: widget.samples),
                ),
            ],
          ),
        ),
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

