import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../domain/milestone.dart';
import '../../domain/monthly_summary.dart';
import '../widgets/fuel_vs_ev_card.dart';
import '../widgets/milestones_card.dart';
import '../widgets/monthly_bar_chart.dart';

/// Carbon dashboard: tabbed view of monthly charts (#180) and
/// gamified achievements (#181). Data is derived entirely from the
/// existing [fillUpListProvider] — no new storage or providers.
class CarbonDashboardScreen extends ConsumerWidget {
  const CarbonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final summaries = MonthlyAggregator.byMonth(fillUps);
    final last12 = MonthlyAggregator.lastN(summaries, 12);
    final milestones = MilestoneEngine.evaluate(fillUps);
    final distanceKm = MilestoneEngine.distanceFromOdometer(fillUps);
    final totalCo2 = MonthlyAggregator.totalCo2(summaries);
    final totalCost = MonthlyAggregator.totalCost(summaries);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l?.carbonDashboardTitle ?? 'Carbon dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          bottomOpacity: 1,
          bottom: TabBar(
            tabs: [
              Tab(text: l?.carbonTabCharts ?? 'Charts'),
              Tab(text: l?.carbonTabAchievements ?? 'Achievements'),
            ],
          ),
        ),
        body: fillUps.isEmpty
            ? EmptyState(
                icon: Icons.eco_outlined,
                title: l?.carbonEmptyTitle ?? 'No data yet',
                subtitle: l?.carbonEmptySubtitle ??
                    'Log fill-ups to see your carbon dashboard.',
              )
            : TabBarView(
                children: [
                  _ChartsTab(
                    summaries: last12,
                    totalCost: totalCost,
                    totalCo2: totalCo2,
                  ),
                  _AchievementsTab(
                    milestones: milestones,
                    fuelCo2Kg: totalCo2,
                    distanceKm: distanceKm,
                    theme: theme,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  final List<MonthlySummary> summaries;
  final double totalCost;
  final double totalCo2;

  const _ChartsTab({
    required this.summaries,
    required this.totalCost,
    required this.totalCo2,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        _SummaryRow(totalCost: totalCost, totalCo2: totalCo2),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l?.monthlyCostsTitle ?? 'Monthly costs',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                MonthlyBarChart(
                  key: const Key('monthly_cost_chart'),
                  summaries: summaries,
                  valueOf: (s) => s.totalCost,
                  color: theme.colorScheme.primary,
                  unitLabel: '€',
                ),
              ],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l?.monthlyEmissionsTitle ?? 'Monthly CO2 emissions',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                MonthlyBarChart(
                  key: const Key('monthly_emissions_chart'),
                  summaries: summaries,
                  valueOf: (s) => s.totalCo2Kg,
                  color: theme.colorScheme.tertiary,
                  unitLabel: 'kg',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
          child: Card(
            margin: const EdgeInsets.only(left: 16, right: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.carbonSummaryTotalCost ?? 'Total cost',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${totalCost.toStringAsFixed(0)} €',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 8, right: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
