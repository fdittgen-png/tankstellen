// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/money_tally.dart';
import '../../../../core/services/co2_calculator.dart';
import '../../../../core/utils/comparison_labels.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trips/api.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/monthly_summary.dart';
import 'monthly_bar_chart.dart';
import 'speed_consumption_card.dart';
import 'trip_length_breakdown_card.dart';
import '../../../../core/utils/unit_formatter.dart';

/// Charts tab of the carbon dashboard. Renders the summary row,
/// trip-length breakdown, speed-consumption histogram, and the two
/// monthly bar charts (cost + CO2 emissions).
///
/// Extracted from `carbon_dashboard_screen.dart` to keep the screen
/// file under the 300-LOC target (Refs #563).
class ChartsTab extends ConsumerWidget {
  final List<MonthlySummary> summaries;

  /// Null when the history spans several currencies (#4437 E).
  final double? totalCost;
  final double totalCo2;

  /// The per-fill spend [totalCost] came from — names the currency and,
  /// when there is no single total, says why (#4437 / #4406).
  final MoneyTally spend;

  const ChartsTab({
    super.key,
    required this.summaries,
    required this.totalCost,
    required this.totalCo2,
    this.spend = MoneyTally.empty,
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
    // #3741/#3882 — only the trips that STORE samples, only their speed
    // + fuel-rate columns, decoded and folded on a worker isolate.
    final speedBins =
        ref.watch(speedConsumptionBinsProvider(activeVehicle?.id));

    return ListView(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        _SummaryRow(totalCost: totalCost, totalCo2: totalCo2, spend: spend),
        const SizedBox(height: 8),
        if (!breakdown.isEmpty)
          TripLengthBreakdownCard(
            breakdown: breakdown,
            overallAvgLPer100Km: overallAvg,
            l: l,
            theme: theme,
          ),
        // While the worker runs, no card: an empty histogram would claim
        // "not enough data" about trips it has not read yet.
        if (speedBins.value case final bins?)
          SpeedConsumptionCard(
            bins: bins,
            overallAvgLPer100Km: overallAvg,
            l: l,
            theme: theme,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SectionCard(
            title: l.monthlyCostsTitle,
            child: MonthlyBarChart(
              key: const Key('monthly_cost_chart'),
              // #4437 — a month with no single cost is left out, never
              // plotted as zero or as a cross-currency sum.
              summaries: [
                for (final s in summaries)
                  if (s.totalCost != null) s,
              ],
              valueOf: (s) => s.totalCost!,
              color: theme.colorScheme.primary,
              unitLabel: _symbolOf(spend),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SectionCard(
            title: l.monthlyEmissionsTitle,
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

/// The symbol [spend]'s single denomination is shown with — the active
/// one for an all-unknown (legacy) or mixed history.
String _symbolOf(MoneyTally spend) {
  final code = spend.soleCurrency;
  return (code == null || code == kUnknownCurrency)
      ? PriceFormatter.currency
      : PriceFormatter.symbolForCurrency(code);
}

class _SummaryRow extends StatelessWidget {
  final double? totalCost;
  final double totalCo2;
  final MoneyTally spend;

  const _SummaryRow({
    required this.totalCost,
    required this.totalCo2,
    required this.spend,
  });

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
                    l.carbonSummaryTotalCost,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalCost == null
                        ? '—'
                        : '${UnitFormatter.formatDecimal(totalCost, fractionDigits: 0)} ${_symbolOf(spend)}',
                    style: theme.textTheme.titleLarge,
                  ),
                  // #4406 — a withheld total says why, in one line.
                  if (totalCost == null &&
                      spendWithheldLabel(l, spend) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      spendWithheldLabel(l, spend)!,
                      key: const Key('carbon_spend_withheld'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                    l.carbonSummaryTotalCo2,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${UnitFormatter.formatDecimal(totalCo2, fractionDigits: 0)} kg',
                    style: theme.textTheme.titleLarge,
                  ),
                  // #4392 — a CO2e figure never appears without the
                  // boundary it was computed over and the table it came
                  // from. `Co2Calculator`'s constants are the
                  // well-to-wheel totals of ADEME Base Carbone; the
                  // scope word is translated, the publication name is
                  // a proper noun.
                  const SizedBox(height: 4),
                  Text(
                    l.carbonCo2ScopeWellToWheel,
                    key: const Key('carbon_co2_scope'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l.carbonCo2FactorSource(Co2Calculator.factorCitation),
                    key: const Key('carbon_co2_factor_source'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
