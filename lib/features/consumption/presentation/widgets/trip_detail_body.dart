import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/driving_insights_analyzer.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/driving_insight.dart';
import '../../domain/trip_recorder.dart';
import 'driving_insights_card.dart';
import 'trip_detail_charts.dart';
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
class TripDetailBody extends StatefulWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final List<TripDetailSample> samples;
  final bool isEv;

  const TripDetailBody({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.samples,
    required this.isEv,
  });

  @override
  State<TripDetailBody> createState() => _TripDetailBodyState();
}

class _TripDetailBodyState extends State<TripDetailBody> {
  /// Lazily-computed driving insights for the trip. Cached for the
  /// lifetime of this State so locale / theme rebuilds don't re-run
  /// the analyzer. The widget tree is rebuilt from scratch (new State)
  /// when the user navigates to a different trip — that's the natural
  /// invalidation boundary, no manual cache key needed.
  late final List<DrivingInsight> _insights = _computeInsights();

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // RPM section is hidden when every sample reports null (the car's
    // PID cache flagged RPM as unsupported). The summary card still
    // shows max-RPM for the trip because that's part of the stored
    // summary regardless of per-sample availability.
    final hasRpmSamples = widget.samples.any((s) => s.rpm != null);

    return SingleChildScrollView(
      key: const Key('trip_detail_scroll'),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TripSummaryCard(
            entry: widget.entry,
            vehicle: widget.vehicle,
            samples: widget.samples,
            isEv: widget.isEv,
          ),
          const SizedBox(height: 8),
          // Driving insights — combustion trips only. EV trips skip
          // this card; phase 4 will land an EV-aware version.
          if (!widget.isEv && widget.samples.isNotEmpty)
            DrivingInsightsCard(insights: _insights),
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
        ],
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
