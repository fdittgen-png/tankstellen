import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/data/trip_history_repository.dart';
import '../../../consumption/domain/services/speed_consumption_histogram.dart';
import '../../../consumption/domain/services/trip_length_aggregator.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../../consumption/providers/trip_history_provider.dart';
import '../../../profile/providers/gamification_enabled_provider.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/milestone.dart';
import '../../domain/monthly_summary.dart';
import '../widgets/fuel_vs_ev_card.dart';
import '../widgets/milestones_card.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/speed_consumption_card.dart';
import '../widgets/trip_length_breakdown_card.dart';

/// Carbon dashboard: tabbed view of monthly charts (#180) and
/// gamified achievements (#181). Data is derived entirely from the
/// existing [fillUpListProvider] — no new storage or providers.
///
/// #923 phase 3c — outer chrome migrated to [PageScaffold] and the
/// charts-tab cards to [SectionCard]. The in-tab `TabBar` primitive is
/// intentionally preserved as-is: the two tabs switch between Charts
/// and Achievements views, but swapping to [TabSwitcher] is a separate
/// presentation-layer PR to keep this diff focused on the
/// scaffold/card migration.
class CarbonDashboardScreen extends ConsumerWidget {
  const CarbonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // #1194 — gamification opt-out. When off, the dashboard collapses
    // to a single Charts pane (no TabBar, no Achievements tab) so the
    // user only sees pure data visualisation. The DefaultTabController
    // length must match the tab list exactly to avoid an index-range
    // error on rebuild.
    final showGamification = ref.watch(gamificationEnabledProvider);

    final summaries = MonthlyAggregator.byMonth(fillUps);
    final last12 = MonthlyAggregator.lastN(summaries, 12);
    final milestones = MilestoneEngine.evaluate(fillUps);
    final distanceKm = MilestoneEngine.distanceFromOdometer(fillUps);
    final totalCo2 = MonthlyAggregator.totalCo2(summaries);
    final totalCost = MonthlyAggregator.totalCost(summaries);

    final chartsTab = _ChartsTab(
      summaries: last12,
      totalCost: totalCost,
      totalCo2: totalCo2,
    );

    Widget body;
    if (fillUps.isEmpty) {
      body = EmptyState(
        icon: Icons.eco_outlined,
        title: l?.carbonEmptyTitle ?? 'No data yet',
        subtitle: l?.carbonEmptySubtitle ??
            'Log fill-ups to see your carbon dashboard.',
      );
    } else if (!showGamification) {
      // Single-pane mode — render the Charts tab directly without any
      // TabBar/TabBarView chrome.
      body = chartsTab;
    } else {
      body = Column(
        children: [
          Material(
            color: Colors.transparent,
            child: TabBar(
              tabs: [
                Tab(text: l?.carbonTabCharts ?? 'Charts'),
                Tab(text: l?.carbonTabAchievements ?? 'Achievements'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                chartsTab,
                _AchievementsTab(
                  milestones: milestones,
                  fuelCo2Kg: totalCo2,
                  distanceKm: distanceKm,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final scaffold = PageScaffold(
      title: l?.carbonDashboardTitle ?? 'Carbon dashboard',
      bannerIcon: Icons.eco_outlined,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      bodyPadding: EdgeInsets.zero,
      body: body,
    );

    // The TabController is only required when the TabBar/TabBarView
    // are mounted — wrapping the single-pane variant in a controller
    // would log a "controller has length 2 but only 1 tab" warning.
    if (!showGamification || fillUps.isEmpty) {
      return scaffold;
    }
    return DefaultTabController(length: 2, child: scaffold);
  }
}

class _ChartsTab extends ConsumerWidget {
  final List<MonthlySummary> summaries;
  final double totalCost;
  final double totalCo2;

  const _ChartsTab({
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

class _AchievementsTab extends StatelessWidget {
  final List<MilestoneProgress> milestones;
  final double fuelCo2Kg;
  final double distanceKm;
  final ThemeData theme;

  const _AchievementsTab({
    required this.milestones,
    required this.fuelCo2Kg,
    required this.distanceKm,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        MilestonesCard(progress: milestones),
        FuelVsEvCard(fuelCo2Kg: fuelCo2Kg, distanceKm: distanceKm),
      ],
    );
  }
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
