import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../../profile/providers/gamification_enabled_provider.dart';
import '../../domain/milestone.dart';
import '../../domain/monthly_summary.dart';
import '../widgets/achievements_tab.dart';
import '../widgets/charts_tab.dart';

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
///
/// #563 — the two tab bodies live in their own widget files
/// (`widgets/charts_tab.dart`, `widgets/achievements_tab.dart`) so this
/// screen stays under the 300-LOC target.
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

    final chartsTab = ChartsTab(
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
                AchievementsTab(
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
