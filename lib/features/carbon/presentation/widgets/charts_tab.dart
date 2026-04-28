import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/data/trip_history_repository.dart';
import '../../../consumption/domain/services/speed_consumption_histogram.dart';
import '../../../consumption/domain/services/trip_length_aggregator.dart';
import '../../../consumption/providers/trip_history_provider.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/monthly_summary.dart';
import 'monthly_bar_chart.dart';
import 'speed_consumption_card.dart';
import 'trip_length_breakdown_card.dart';

/// Charts tab of the carbon dashboard. Renders the summary row,
/// trip-length breakdown, speed-consumption histogram, and the two
/// monthly bar charts (cost + CO2 emissions).
///
/// Extracted from `carbon_dashboard_screen.dart` to keep the screen
/// file under the 300-LOC target (Refs #563).
class ChartsTab extends ConsumerWidget {
  final List<MonthlySummary> summaries;
  final double totalCost;
  final double totalCo2;

  const ChartsTab({
    super.key,
    required this.summaries,
    required this.totalCost,
    required this.totalCo2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // #1191 — fold trip-history into the three length buckets, filtered
    // to the active vehicle (legacy null-vehicleId trips are included
    // per the trajets-tab convention). Computing the overall avg from
    // the SAME filtered list keeps the per-tile arrows consistent with
    // the headline figure on the dashboard.
    final trips = ref.watch(tripHistoryListProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final breakdown = aggregateByTripLength(
      trips,
      vehicleId: activeVehicle?.id,
    );
    final overallAvg = _overallAvgLPer100Km(trips, activeVehicle?.id);

    // #1192 — speed-vs-consumption histogram, fed by per-second OBD2
    // samples on each TripHistoryEntry. Same vehicle-id filter as the
    // trip-length card so the two histograms describe the same data
    // slice — and so the reference line on the speed card matches the
    // overall avg already computed above.
    final filteredTrips = _filterTrips(trips, activeVehicle?.id);
    final speedBins = aggregateSpeedConsumption(
      filteredTrips.expand((entry) => entry.samples),
    );

    return ListView(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        _SummaryRow(totalCost: totalCost, totalCo2: totalCo2),
        const SizedBox(height: 8),
        if (l != null && !breakdown.isEmpty)
          TripLengthBreakdownCard(
            breakdown: breakdown,
            overallAvgLPer100Km: overallAvg,
            l: l,
            theme: theme,
          ),
        if (l != null)
          SpeedConsumptionCard(
            bins: speedBins,
            overallAvgLPer100Km: overallAvg,
            l: l,
            theme: theme,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SectionCard(
            title: l?.monthlyCostsTitle ?? 'Monthly costs',
            child: MonthlyBarChart(
              key: const Key('monthly_cost_chart'),
              summaries: summaries,
              valueOf: (s) => s.totalCost,
              color: theme.colorScheme.primary,
              unitLabel: PriceFormatter.currency,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SectionCard(
            title: l?.monthlyEmissionsTitle ?? 'Monthly CO2 emissions',
            child: MonthlyBarChart(
              key: const Key('monthly_emissions_chart'),
              summaries: summaries,
              valueOf: (s) => s.totalCo2Kg,
              color: theme.colorScheme.tertiary,
              unitLabel: 'kg',
            ),
          ),
        ),
      ],
    );
  }
}

/// Compute the overall average L/100 km across the same filtered trip
/// list the [TripLengthBreakdown] was built from. Returns null when no
/// trip in the filtered set has both a non-null `fuelLitersConsumed`
/// and a positive distance — the per-tile arrows are suppressed in
/// that case. Mirrors the same vehicle-id filter as
/// [aggregateByTripLength] so the figure stays consistent with the
/// breakdown the user sees right next to it.
double? _overallAvgLPer100Km(
  Iterable<TripHistoryEntry> trips,
  String? vehicleId,
) {
  double totalDistanceKm = 0;
  double totalLitres = 0;
  for (final entry in trips) {
    if (vehicleId != null &&
        entry.vehicleId != null &&
        entry.vehicleId != vehicleId) {
      continue;
    }
    final litres = entry.summary.fuelLitersConsumed;
    if (litres == null) continue;
    totalDistanceKm += entry.summary.distanceKm;
    totalLitres += litres;
  }
  if (totalDistanceKm <= 0) return null;
  return (totalLitres / totalDistanceKm) * 100.0;
}

/// Filter [trips] to those that match [vehicleId] (or carry a legacy
/// null vehicleId — same convention used by the trajets tab and
/// [aggregateByTripLength]). Returns the filtered list eagerly so the
/// caller can `.expand` over it twice without re-running the predicate
/// per pass — a small but noticeable saving on long trip lists where
/// each entry carries hundreds of samples.
List<TripHistoryEntry> _filterTrips(
  Iterable<TripHistoryEntry> trips,
  String? vehicleId,
) {
  if (vehicleId == null) return trips.toList(growable: false);
  return trips
      .where((entry) =>
          entry.vehicleId == null || entry.vehicleId == vehicleId)
      .toList(growable: false);
}

class _SummaryRow extends StatelessWidget {
  final double totalCost;
  final double totalCo2;

  const _SummaryRow({required this.totalCost, required this.totalCo2});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.carbonSummaryTotalCost ?? 'Total cost',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalCost.toStringAsFixed(0)} ${PriceFormatter.currency}',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 16),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.carbonSummaryTotalCo2 ?? 'Total CO2',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalCo2.toStringAsFixed(0)} kg',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
