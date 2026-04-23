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
import '../../../station_detail/presentation/widgets/log_charging_bottom_sheet.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/csv_exporter.dart';
import '../../providers/charging_logs_provider.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/charging_log_card.dart';
import '../widgets/charging_stats_card.dart';
import '../widgets/consumption_stats_card.dart';
import '../widgets/fill_up_card.dart';
import '../widgets/obd2_status_chip.dart';

/// Which segment of the consumption screen is currently active —
/// fuel fill-ups (default) or EV charging sessions (#582 phase 2).
enum ConsumptionTab { fuel, charging }

/// Lists all logged fill-ups with a summary stats card at the top.
///
/// #582 phase 2 adds a Fuel ↔ Charging segmented toggle at the top of
/// the body so EV owners can inspect their charging history alongside
/// the fuel list without losing the existing fuel-only flow. The
/// toggle is purely screen-scoped state (StatefulWidget) — we never
/// need to persist the user's last-viewed tab because the fuel side
/// is the canonical default: a returning hybrid driver most commonly
/// wants to see fuel first.
class ConsumptionScreen extends ConsumerStatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  ConsumerState<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends ConsumerState<ConsumptionScreen> {
  ConsumptionTab _tab = ConsumptionTab.fuel;

  @override
  Widget build(BuildContext context) {
    final fillUps = ref.watch(fillUpListProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final l = AppLocalizations.of(context);

    // #815 — surface the η_v calibration outcome as a one-shot
    // snackbar when the fill-up save path learns a new value for the
    // active vehicle. Listening here (rather than in the fill-up
    // screen) keeps the snackbar visible after the fill-up form
    // pops, which is the screen the user actually sees.
    ref.listen(lastVeLearnResultProvider, (previous, next) {
      if (next == null) return;
      final vehicles = ref.read(vehicleProfileListProvider);
      final vehicle = vehicles
          .where((v) => v.id == next.vehicleId)
          .firstOrNull;
      final name = vehicle?.name ?? '';
      final percent = next.accuracyImprovementPct.round().toString();
      final msg = l?.veCalibratedTitle(name, percent) ??
          'Consumption calibration updated for $name — '
              'accuracy improved by $percent%';
      SnackBarHelper.showSuccess(context, msg);
      // Clear so a rebuild doesn't re-fire the snackbar on the next
      // unrelated rebuild (e.g. the user deleting a fill-up).
      ref.read(lastVeLearnResultProvider.notifier).set(null);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.consumptionLogTitle ?? 'Fuel consumption'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          // #797 phase 3 — title-bar chip announcing "OBD2 connected"
          // when the pinned adapter is currently linked. Hides
          // itself otherwise so unpaired users see no chrome.
          const Obd2StatusChip(),
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
      floatingActionButton: _tab == ConsumptionTab.fuel
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/consumption/pick-station'),
              icon: const Icon(Icons.add),
              label: Text(l?.addFillUp ?? 'Add fill-up'),
            )
          : FloatingActionButton.extended(
              key: const Key('add_charging_log'),
              onPressed: () =>
                  LogChargingBottomSheet.show(context),
              icon: const Icon(Icons.add),
              label: Text(l?.chargingLogAddTitle ?? 'Log charging'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<ConsumptionTab>(
              key: const Key('consumption_tab_toggle'),
              segments: [
                ButtonSegment(
                  value: ConsumptionTab.fuel,
                  icon: const Icon(Icons.local_gas_station_outlined),
                  label: Text(l?.consumptionTabFuel ?? 'Fuel'),
                ),
                ButtonSegment(
                  value: ConsumptionTab.charging,
                  icon: const Icon(Icons.ev_station_outlined),
                  label: Text(l?.consumptionTabCharging ?? 'Charging'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (sel) =>
                  setState(() => _tab = sel.first),
            ),
          ),
          Expanded(
            child: _tab == ConsumptionTab.fuel
                ? _FuelTabBody()
                : const _ChargingTabBody(),
          ),
        ],
      ),
    );
  }
}

/// Fuel-side body extracted so the screen's `build` stays focused on
/// routing the segmented toggle. Contains the help banner, badge
/// shelf, stats card, and the fill-up list — identical to the pre-#582
/// layout.
class _FuelTabBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fillUps = ref.watch(fillUpListProvider);
    final stats = ref.watch(consumptionStatsProvider);
    final l = AppLocalizations.of(context);

    if (fillUps.isEmpty) {
      return EmptyState(
        icon: Icons.local_gas_station_outlined,
        title: l?.noFillUpsTitle ?? 'No fill-ups yet',
        subtitle: l?.noFillUpsSubtitle ??
            'Log your first fill-up to start tracking consumption.',
      );
    }

    return ListView.builder(
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
    );
  }
}

/// Charging-side body for the active vehicle — mirrors [_FuelTabBody]
/// shape so the two feel like the same product. Empty state + stats
/// card + list-of-cards, newest-first. Unlike the fuel side, there is
/// no in-screen "Add" FAB — charging sessions are logged from the EV
/// station detail screen (#582 phase 2 scope).
class _ChargingTabBody extends ConsumerWidget {
  const _ChargingTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final active = ref.watch(activeVehicleProfileProvider);
    // Show the logs belonging to the active vehicle when one is set;
    // fall back to "every log in the box" for users who haven't yet
    // configured a vehicle profile. Matches the read-side of the
    // bottom sheet's save path, which falls back to `vehicleId = ''`
    // when no vehicle is active.
    final logsAsync = active != null
        ? ref.watch(chargingLogsForVehicleProvider(active.id))
        : ref.watch(chargingLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (logs) {
        if (logs.isEmpty) {
          return EmptyState(
            icon: Icons.ev_station_outlined,
            title: l?.chargingLogEmpty ??
                'No charging sessions yet. '
                    'Log one from the EV station detail screen.',
          );
        }
        // Display newest-first to match the fuel side's "recent at the
        // top" feel. The store returns oldest-first.
        final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
        return ListView.builder(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 96 + MediaQuery.of(context).viewPadding.bottom,
          ),
          itemCount: sorted.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const ChargingStatsCard();
            }
            final log = sorted[index - 1];
            return Dismissible(
              key: ValueKey('charging_log_${log.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                ref.read(chargingLogsProvider.notifier).remove(log.id);
              },
              child: ChargingLogCard(
                key: ValueKey('charging_log_card_${log.id}'),
                log: log,
                // Tap-to-edit is reserved for a phase-2 follow-up; no
                // navigation target exists yet so the card is
                // intentionally non-tappable.
              ),
            );
          },
        );
      },
    );
  }
}
