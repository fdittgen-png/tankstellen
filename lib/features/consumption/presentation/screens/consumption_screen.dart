import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/tab_switcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../achievements/presentation/widgets/badge_shelf.dart';
import '../../../ev/domain/entities/charging_log.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/csv_exporter.dart';
import '../../providers/charging_charts_provider.dart';
import '../../providers/charging_logs_provider.dart';
import '../../providers/consumption_providers.dart';
import '../widgets/charging_cost_trend_chart.dart';
import '../widgets/charging_efficiency_chart.dart';
import '../widgets/charging_log_card.dart';
import '../widgets/consumption_stats_card.dart';
import '../widgets/fill_up_card.dart';
import '../widgets/obd2_status_chip.dart';
import '../widgets/trajets_tab.dart';
import 'add_charging_log_screen.dart';

/// Lists all logged fill-ups and charging sessions.
///
/// Two-tab scaffold (#582 phase 2):
///   * **Fuel** — existing fill-up list with its CSV export + stats card.
///   * **Charging** — new EV charging logs backed by
///     [chargingLogsProvider]. Phase-3 will add per-vehicle charts
///     and the deep-link from the EV station detail screen.
///
/// The FAB rebinds to the active tab so the user always sees the
/// most obvious "log what I just did" action for the list they're
/// looking at — no hidden overflow menu entries.
class ConsumptionScreen extends ConsumerStatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  ConsumerState<ConsumptionScreen> createState() =>
      _ConsumptionScreenState();
}

class _ConsumptionScreenState extends ConsumerState<ConsumptionScreen>
    with TickerProviderStateMixin {
  // Lazily created in the first `build`. Recreated whenever the
  // active vehicle's powertrain flips the Charging tab on/off (#892):
  // TabController requires its `length` to match the TabBar's `tabs`
  // length exactly, so we tear down the old controller and instantiate
  // a fresh one with the new length (clamping the selected index so
  // the user doesn't land on a missing tab).
  TabController? _tabController;

  /// Whether the Charging tab should appear for the given vehicle.
  ///
  /// - ICE (`VehicleType.combustion`) → false
  /// - Hybrid / EV → true
  /// - No active vehicle → true (keep current behaviour; the
  ///   no-vehicle onboarding flow lives in a separate issue).
  static bool _shouldShowCharging(VehicleProfile? vehicle) {
    if (vehicle == null) return true;
    return vehicle.isEv;
  }

  void _ensureTabController({
    required bool showCharging,
    int? preferredIndex,
  }) {
    final newLength = showCharging ? 3 : 2;
    final previous = _tabController;
    if (previous != null && previous.length == newLength) {
      return;
    }

    // Clamp the previous index into the new controller's range so we
    // don't strand the user on a now-missing tab. When the Charging
    // tab vanishes while the user is on it, fall back to Trajets
    // (index 1) rather than Fuel — it's the closest neighbour in the
    // mental model of "what I was just looking at".
    final oldIndex = preferredIndex ?? previous?.index ?? 0;
    final int initialIndex;
    if (!showCharging && oldIndex >= newLength) {
      initialIndex = 1; // Trajets
    } else {
      initialIndex = oldIndex.clamp(0, newLength - 1);
    }

    final controller = TabController(
      length: newLength,
      vsync: this,
      initialIndex: initialIndex,
    );
    controller.addListener(() {
      // The FAB label changes when the tab changes, so trigger a
      // rebuild on every tab transition (indexIsChanging covers the
      // animated swipe case too).
      if (!mounted) return;
      setState(() {});
    });
    previous?.dispose();
    _tabController = controller;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fillUps = ref.watch(fillUpListProvider);
    final chargingLogsAsync = ref.watch(chargingLogsProvider);
    final stats = ref.watch(consumptionStatsProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final showCharging = _shouldShowCharging(activeVehicle);
    // Recreate the TabController when the tab-set cardinality
    // changes (#892). Doing this in build — rather than in initState
    // — lets us react to live vehicle switches without a ref.listen
    // round-trip, and keeps the controller's length always consistent
    // with the rendered Tab list (length mismatch throws at runtime).
    _ensureTabController(showCharging: showCharging);
    final tabController = _tabController!;
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

    // #889 — tabs are 0 Fuel, 1 Trajets, and (ICE vehicles excepted
    // per #892) 2 Charging. The FAB rebinds per-tab: Fuel ->
    // pick-station sheet, Trajets hides the FAB (the "Start
    // recording" CTA lives inside the tab header), Charging -> Add
    // charging log sheet.
    final tabIndex = tabController.index;
    final isFuelTab = tabIndex == 0;
    final isTrajetsTab = tabIndex == 1;
    final isChargingTab = showCharging && tabIndex == 2;

    return PageScaffold(
      title: l?.consumptionLogTitle ?? 'Fuel consumption',
      bodyPadding: EdgeInsets.zero,
      bottom: TabSwitcher(
        controller: tabController,
        tabs: [
          TabSwitcherEntry(
            label: l?.consumptionTabFuel ?? 'Fuel',
            icon: Icons.local_gas_station_outlined,
          ),
          TabSwitcherEntry(
            label: l?.trajetsTabLabel ?? 'Trips',
            icon: Icons.route_outlined,
          ),
          // #892 — Charging tab is hidden when the active vehicle
          // is a pure combustion engine. Hybrid and EV profiles
          // still see it; the no-vehicle case keeps the tab (a
          // dedicated onboarding story covers that path).
          if (showCharging)
            TabSwitcherEntry(
              label: l?.consumptionTabCharging ?? 'Charging',
              icon: Icons.ev_station_outlined,
            ),
        ],
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
      floatingActionButton: isTrajetsTab
          // Trajets tab hides the global FAB — the "Start recording"
          // CTA lives inside the tab header, mirroring the fuel-tab
          // add-fill-up and charging-tab log-charging patterns but
          // scoped to the list the user is looking at.
          ? null
          : FloatingActionButton.extended(
              key: Key(isFuelTab ? 'fab_add_fillup' : 'fab_add_charging'),
              onPressed: () async {
                if (isFuelTab) {
                  await context.push('/consumption/pick-station');
                } else if (isChargingTab) {
                  await Navigator.of(context).push<bool?>(
                    MaterialPageRoute(
                      builder: (_) => const AddChargingLogScreen(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: Text(
                isFuelTab
                    ? (l?.addFillUp ?? 'Add fill-up')
                    : (l?.addChargingLog ?? 'Log charging'),
              ),
            ),
      body: TabBarView(
        controller: tabController,
        children: [
          _FuelTab(fillUps: fillUps, stats: stats, l: l),
          TrajetsTab(vehicleId: activeVehicle?.id),
          // Charging view is only mounted when the active vehicle
          // can actually charge — hiding it for ICE profiles (#892)
          // removes a dead-end tap for combustion-only users without
          // touching `chargingLogsProvider`, so flipping back to a
          // hybrid/EV restores the logs exactly.
          if (showCharging) _ChargingTab(async: chargingLogsAsync, l: l),
        ],
      ),
    );
  }
}

/// Body of the Fuel tab — identical shape to the pre-phase-2
/// ConsumptionScreen body so the existing widget/export tests keep
/// passing with zero assertion churn.
class _FuelTab extends ConsumerWidget {
  final List<dynamic> fillUps;
  final dynamic stats;
  final AppLocalizations? l;

  const _FuelTab({
    required this.fillUps,
    required this.stats,
    required this.l,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ref.read(fillUpListProvider.notifier).remove(fillUp.id);
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

/// Body of the Charging tab — loads the charging-log list via
/// [chargingLogsProvider] and renders a [ChargingLogCard] per row.
///
/// The list is oldest-first from the store; we flip the order here
/// so the newest session appears at the top — matches the mental
/// model of "what I most recently logged" that the fuel list (sorted
/// newest-first by [fillUpListProvider]) already uses.
class _ChargingTab extends ConsumerWidget {
  final AsyncValue<List<ChargingLog>> async;
  final AppLocalizations? l;

  const _ChargingTab({required this.async, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load charging logs: $e'),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return EmptyState(
            key: const Key('charging_empty_state'),
            icon: Icons.ev_station_outlined,
            title: l?.noChargingLogsTitle ?? 'No charging logs yet',
            subtitle: l?.noChargingLogsSubtitle ??
                'Log your first charging session to start tracking '
                    'EUR/100 km and kWh/100 km.',
          );
        }
        final ordered = logs.reversed.toList(growable: false);
        return ListView.builder(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 96 + MediaQuery.of(context).viewPadding.bottom,
          ),
          itemCount: ordered.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Charts header — read the derived rollup providers so
              // they react to the same chargingLogsProvider we already
              // watched upstream.
              return const _ChargingChartsSection();
            }
            final log = ordered[index - 1];
            return Dismissible(
              key: ValueKey('charging-${log.id}'),
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
              child: ChargingLogCard(log: log),
            );
          },
        );
      },
    );
  }
}

/// Charts header rendered above the charging-log list (#582 phase 3).
///
/// Collapses nicely in landscape: both charts are fixed-height boxes
/// and sit inside the list's vertical scroll, so narrow widths just
/// squeeze the bars/points — they never clip.
class _ChargingChartsSection extends ConsumerWidget {
  const _ChargingChartsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cost = ref.watch(chargingMonthlyCostProvider);
    final efficiency = ref.watch(chargingMonthlyEfficiencyProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        key: const Key('charging_charts_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.chargingCostTrendTitle ?? 'Charging cost trend',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ChargingCostTrendChart(
                    key: const Key('charging_cost_trend_chart'),
                    monthlyCost: cost,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l?.chargingEfficiencyTitle ??
                        'Efficiency (kWh/100 km)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ChargingEfficiencyChart(
                    key: const Key('charging_efficiency_chart'),
                    monthlyEfficiency: efficiency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
