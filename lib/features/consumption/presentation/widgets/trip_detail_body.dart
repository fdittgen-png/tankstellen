import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../profile/providers/gamification_enabled_provider.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/driving_insights_analyzer.dart';
import '../../data/driving_score_calculator.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/driving_insight.dart';
import '../../domain/driving_score.dart';
import '../../domain/services/throttle_rpm_histogram_calculator.dart';
import '../../domain/trip_recorder.dart';
import 'driving_insights_card.dart';
import 'driving_score_card.dart';
import 'throttle_rpm_histogram_card.dart';
import 'trip_detail_charts.dart';
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

  List<DrivingInsight> _computeInsights() {
    if (widget.samples.isEmpty) return const [];
    // Insights are only meaningful for combustion trips — EV trips
    // don't have RPM, hard-accel waste, or idling fuel cost in the
    // same sense. Phase 1's analyzer would still surface hard-accel
    // events for EVs, but framing it as "wasted L" would be wrong.
    // Skip the analysis for EVs entirely; phase 4 will revisit once
    // the kWh equivalent lands.
    if (widget.isEv) return const [];
    final tripSamples = widget.samples.map(_toTripSample).toList(
          growable: false,
        );
    return analyzeTrip(tripSamples);
  }

  DrivingScore _computeScore() {
    if (widget.samples.isEmpty) return DrivingScore.perfect;
    if (widget.isEv) return DrivingScore.perfect;
    final tripSamples = widget.samples.map(_toTripSample).toList(
          growable: false,
        );
    return computeDrivingScore(tripSamples);
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

    // Engine-load section (#1262 phase 3) follows the same gating
    // rule as RPM: cars without PID 0x04 emit null on every sample
    // (legacy trips persisted before #1262 phase 1 also do), and we
    // silently skip the section header in that case rather than
    // rendering an empty card.
    final hasEngineLoadSamples =
        widget.samples.any((s) => s.engineLoadPercent != null);

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
        // this card; phase 4 will land an EV-aware version.
        //
        // #1263 phase 3: also pass the gear-coaching metric
        // (`secondsBelowOptimalGear`) so the card can render a
        // "Labouring in low gear (X min)" row when the metric > 60s.
        // Force null on EV trips defensively — the parent gate above
        // already hides the card for EVs, but null-passing keeps the
        // contract clean if that gate ever moves.
        if (!widget.isEv && widget.samples.isNotEmpty)
          DrivingInsightsCard(
            insights: _insights,
            secondsBelowOptimalGear: widget.isEv
                ? null
                : widget.entry.summary.secondsBelowOptimalGear,
          ),
        // Throttle / RPM histogram (#1041 phase 3a — Card C). Slotted
        // right below the insights card so the user reads "what was
        // wasteful" then immediately sees "here's the engine
        // distribution that produced that". Mirrors the EV-skip and
        // empty-samples-skip rules.
        if (!widget.isEv && widget.samples.isNotEmpty)
          ThrottleRpmHistogramCard(histogram: _histogram),
        _ChartSection(
          title: l?.trajetDetailChartSpeed ?? 'Speed (km/h)',
          chart: TripDetailSpeedChart(samples: widget.samples),
        ),
        _ChartSection(
          title: l?.trajetDetailChartFuelRate ?? 'Fuel rate (L/h)',
          chart: TripDetailFuelRateChart(samples: widget.samples),
        ),
        if (hasRpmSamples)
          _ChartSection(
            title: l?.trajetDetailChartRpm ?? 'RPM',
            chart: TripDetailRpmChart(samples: widget.samples),
          ),
        if (hasEngineLoadSamples)
          _ChartSection(
            title: l?.trajetDetailChartEngineLoad ?? 'Engine load (%)',
            chart: TripDetailEngineLoadChart(samples: widget.samples),
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

/// Convert a presentation-layer [TripDetailSample] into the domain
/// [TripSample] the analyzer consumes. Mirrors `_toDetailSample` in
/// `trip_detail_screen.dart` — kept inline here to keep the screen
/// boundary clean. The analyzer treats `rpm: null` as zero, which
/// matches "no engine reading available" semantically.
TripSample _toTripSample(TripDetailSample s) => TripSample(
      timestamp: s.timestamp,
      speedKmh: s.speedKmh,
      rpm: s.rpm ?? 0,
      fuelRateLPerHour: s.fuelRateLPerHour,
    );

class _ChartSection extends StatelessWidget {
  final String title;
  final Widget chart;

  const _ChartSection({required this.title, required this.chart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          chart,
        ],
      ),
    );
  }
}
