import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/consumption_stats_card.dart';
import '../widgets/fill_up_card.dart';

/// Lists all logged fill-ups with a summary stats card at the top.
class ConsumptionScreen extends ConsumerWidget {
  const ConsumptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final stats = ref.watch(consumptionStatsProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.consumptionLogTitle ?? 'Fuel consumption'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const Key('open_carbon_dashboard'),
            tooltip: l?.carbonDashboardTitle ?? 'Carbon dashboard',
            icon: const Icon(Icons.eco_outlined),
            onPressed: () => context.push('/carbon'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/consumption/add'),
        icon: const Icon(Icons.add),
        label: Text(l?.addFillUp ?? 'Add fill-up'),
      ),
      body: fillUps.isEmpty
          ? EmptyState(
              icon: Icons.local_gas_station_outlined,
              title: l?.noFillUpsTitle ?? 'No fill-ups yet',
              subtitle: l?.noFillUpsSubtitle ??
                  'Log your first fill-up to start tracking consumption.',
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                top: 8,
                bottom: 96 + MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount: fillUps.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ConsumptionStatsCard(stats: stats);
                }
                final fillUp = fillUps[index - 1];
                return Dismissible(
                  key: ValueKey(fillUp.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(fillUpListProvider.notifier)
                        .remove(fillUp.id);
                  },
                  child: FillUpCard(fillUp: fillUp),
                );
              },
            ),
    );
  }
}
