import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/providers/consumption_providers.dart';
import '../../domain/monthly_summary.dart';
import '../widgets/charts_tab.dart';

/// Carbon dashboard: monthly charts derived from the existing
/// [fillUpListProvider] — no new storage or providers.
class CarbonDashboardScreen extends ConsumerWidget {
  const CarbonDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final l = AppLocalizations.of(context);

    final summaries = MonthlyAggregator.byMonth(fillUps);
    final last12 = MonthlyAggregator.lastN(summaries, 12);
    final totalCo2 = MonthlyAggregator.totalCo2(summaries);
    final totalCost = MonthlyAggregator.totalCost(summaries);

    final Widget body = fillUps.isEmpty
        ? EmptyState(
            icon: Icons.eco_outlined,
            title: l?.carbonEmptyTitle ?? 'No data yet',
            subtitle: l?.carbonEmptySubtitle ??
                'Log fill-ups to see your carbon dashboard.',
          )
        : ChartsTab(
            summaries: last12,
            totalCost: totalCost,
            totalCo2: totalCo2,
          );

    return PageScaffold(
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
  }
}
