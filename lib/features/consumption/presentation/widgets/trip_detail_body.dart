import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import 'trip_detail_charts.dart';
import 'trip_summary_card.dart';

/// Scrollable body of the trip detail screen (#890): summary card
/// followed by speed / fuel-rate / RPM line charts.
///
/// Uses [SingleChildScrollView] + [Column] (not a [ListView]) so every
/// section stays in the widget tree — simplifies widget tests that
/// assert on the presence / absence of the RPM chart below the fold,
/// and keeps the screen compatible with [scrollUntilVisible] when the
/// profile is long enough to require actual scrolling.
class TripDetailBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // RPM section is hidden when every sample reports null (the car's
    // PID cache flagged RPM as unsupported). The summary card still
    // shows max-RPM for the trip because that's part of the stored
    // summary regardless of per-sample availability.
    final hasRpmSamples = samples.any((s) => s.rpm != null);

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
            entry: entry,
            vehicle: vehicle,
            samples: samples,
            isEv: isEv,
          ),
          const SizedBox(height: 8),
          _ChartSection(
            title: l?.trajetDetailChartSpeed ?? 'Speed (km/h)',
            chart: TripDetailSpeedChart(samples: samples),
          ),
          _ChartSection(
            title: l?.trajetDetailChartFuelRate ?? 'Fuel rate (L/h)',
            chart: TripDetailFuelRateChart(samples: samples),
          ),
          if (hasRpmSamples)
            _ChartSection(
              title: l?.trajetDetailChartRpm ?? 'RPM',
              chart: TripDetailRpmChart(samples: samples),
            ),
        ],
      ),
    );
  }
}

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
