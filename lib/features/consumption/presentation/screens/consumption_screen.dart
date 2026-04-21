import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../achievements/presentation/widgets/badge_shelf.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/csv_exporter.dart';
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
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
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
            key: const Key('export_csv'),
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: fillUps.isEmpty
                ? null
                : () async {
                    final csv = ConsumptionCsvExporter.toCsv(fillUps);
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (!context.mounted) return;
                    SnackBarHelper.show(
                      context,
                      'CSV copied to clipboard — paste into a spreadsheet',
                    );
                  },
          ),
          IconButton(
            key: const Key('open_carbon_dashboard'),
            tooltip: l?.carbonDashboardTitle ?? 'Carbon dashboard',
            icon: const Icon(Icons.eco_outlined),
            onPressed: () => context.push('/carbon'),
          ),
          IconButton(
            key: const Key('open_trip_history'),
            tooltip: l?.tripHistoryTitle ?? 'Trip history',
            icon: const Icon(Icons.route_outlined),
            onPressed: () => context.push('/trip-history'),
          ),
          // Shortcut to edit the active vehicle — the primary
          // "subject" the consumption log belongs to (#702). Hidden
          // when no vehicle is configured; the fill-up FAB's empty
          // state already surfaces the Add-vehicle CTA in that case.
          if (activeVehicle != null)
            IconButton(
              key: const Key('open_active_vehicle'),
              tooltip: l?.vehicleEditTitle ?? 'Edit vehicle',
              icon: const Icon(Icons.directions_car_outlined),
              onPressed: () => context.push(
                '/vehicles/edit',
                extra: activeVehicle.id,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/consumption/pick-station'),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      HelpBanner(
                        storageKey: StorageKeys.helpBannerConsumption,
                        icon: Icons.tips_and_updates_outlined,
                        message: l?.helpBannerConsumption ??
                            'Log every fill-up to track your real-world '
                                'consumption and CO₂ footprint. Swipe left '
                                'to delete an entry.',
                      ),
                      const BadgeShelf(),
                      ConsumptionStatsCard(stats: stats),
                    ],
                  );
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
                  child: FillUpCard(
                    fillUp: fillUp,
                    ecoScore: ref.watch(ecoScoreForFillUpProvider(fillUp.id)),
                  ),
                );
              },
            ),
    );
  }
}
