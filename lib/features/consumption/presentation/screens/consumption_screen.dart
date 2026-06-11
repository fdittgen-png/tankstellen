// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/tab_switcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/exporters/backup/full_backup_exporter.dart';
import '../../providers/charging_logs_provider.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/charging_tab.dart';
import '../widgets/consumption_app_bar_actions.dart';
import '../widgets/fuel_tab.dart';
import '../widgets/trajets_record_fab.dart';
import '../widgets/trajets_tab.dart';
import 'add_charging_log_screen.dart';

/// Which slice of the consumption feature a [ConsumptionScreen] renders.
///
/// #1901 — Carburant and Trajets are now separate bottom-bar
/// destinations (each its own router branch) rather than two tabs of a
/// single screen, so the screen is parameterised by section instead of
/// hosting an in-screen tab bar.
enum ConsumptionSection { fuel, trajets }

/// Lists logged fill-ups (and EV charging sessions) or OBD2 trips,
/// depending on [section].
///
/// - **[ConsumptionSection.fuel]** — the fill-up list with its CSV
///   export + stats card. For a vehicle that can charge (hybrid / EV)
///   a compact Fuel / Charging switcher is shown so the user picks
///   either energy form; a pure-combustion vehicle just sees fuel.
/// - **[ConsumptionSection.trajets]** — OBD2 trip history, with its
///   own "Start recording" CTA in the tab header.
class ConsumptionScreen extends ConsumerStatefulWidget {
  /// Which section to render. Defaults to [ConsumptionSection.fuel] so
  /// the bare `/consumption-tab` route keeps its historical behaviour.
  final ConsumptionSection section;

  const ConsumptionScreen({
    super.key,
    this.section = ConsumptionSection.fuel,
  });

  /// Test-only override for the backup exporter wired into the AppBar
  /// download button (#1317). Lets widget tests assert the export
  /// flow is invoked without driving the real `share_plus` plugin.
  ///
  /// Production keeps this null and the screen instantiates a fresh
  /// [FullBackupExporter] on tap.
  @visibleForTesting
  static FullBackupExporter? debugExporterOverride;

  @override
  ConsumerState<ConsumptionScreen> createState() =>
      _ConsumptionScreenState();
}

class _ConsumptionScreenState extends ConsumerState<ConsumptionScreen>
    with TickerProviderStateMixin {
  // Fuel / Charging sub-switcher controller, lazily created in `build`.
  // Only relevant for [ConsumptionSection.fuel] on a vehicle that can
  // charge; null otherwise. Recreated when the Charging slot appears /
  // disappears (a TabController's `length` must match its tab count).
  TabController? _tabController;

  /// Whether the Charging slot should appear for the given vehicle.
  ///
  /// - ICE (`VehicleType.combustion`) → false
  /// - Hybrid / EV → true
  /// - No active vehicle → true (keep current behaviour; the
  ///   no-vehicle onboarding flow lives in a separate issue).
  static bool _shouldShowCharging(VehicleProfile? vehicle) {
    if (vehicle == null) return true;
    return vehicle.isEv;
  }

  /// Ensure a 2-tab (Fuel / Charging) controller exists, or tear it
  /// down when charging is not applicable.
  void _ensureFuelChargingController({required bool showCharging}) {
    if (!showCharging) {
      _tabController?.dispose();
      _tabController = null;
      return;
    }
    if (_tabController != null && _tabController!.length == 2) return;
    final controller = TabController(length: 2, vsync: this);
    controller.addListener(() {
      // The FAB label changes with the sub-tab, so rebuild on change.
      if (!mounted) return;
      setState(() {});
    });
    _tabController?.dispose();
    _tabController = controller;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// #2223 — the vehicles entry point, relocated from the trailing
  /// actions to the app-bar leading slot so the car icon reads as part
  /// of the title. Shared by every [ConsumptionSection] so the Trajets
  /// and Carburant tabs stay visually consistent. Keeps the original
  /// `open_vehicles` key, tooltip and `/vehicles` target (#1946).
  Widget _vehiclesLeading(AppLocalizations? l) => IconButton(
        key: const Key('open_vehicles'),
        tooltip: l?.vehiclesMenuTitle ?? 'My vehicles',
        icon: const Icon(Icons.directions_car_outlined),
        onPressed: () => context.push(RoutePaths.vehicles),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // #815 — surface the η_v calibration outcome as a one-shot
    // snackbar when the fill-up save path learns a new value for the
    // active vehicle. Listening here keeps the snackbar visible after
    // the fill-up form pops, which is the screen the user sees.
    ref.listen(lastVeLearnResultProvider, (previous, next) {
      if (next == null) return;
      final vehicles = ref.read(vehicleProfileListProvider);
      final vehicle =
          vehicles.where((v) => v.id == next.vehicleId).firstOrNull;
      final name = vehicle?.name ?? '';
      final percent = next.accuracyImprovementPct.round().toString();
      final msg = l?.veCalibratedTitle(name, percent) ??
          'Consumption calibration updated for $name — '
              'accuracy improved by $percent%';
      SnackBarHelper.showSuccess(context, msg);
      // Clear so a rebuild doesn't re-fire the snackbar.
      ref.read(lastVeLearnResultProvider.notifier).set(null);
    });

    return switch (widget.section) {
      ConsumptionSection.trajets => _buildTrajets(context, l),
      ConsumptionSection.fuel => _buildFuel(context, l),
    };
  }

  /// #1901 — the Trajets destination: OBD2 trip history. #2494 — the
  /// "Start / Resume recording" CTA now floats in the Scaffold FAB slot
  /// ([TrajetsRecordFab]) over the list, matching the Carburant tab,
  /// instead of the old hand-rolled in-body overlay.
  ///
  /// #2374 — computes the same vehicle-filtered trip IDs that [TrajetsTab]
  /// renders, so the AppBar map action opens [TrajetsMapScreen] with exactly
  /// the visible set of trips.
  Widget _buildTrajets(BuildContext context, AppLocalizations? l) {
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final allTrips = ref.watch(tripHistoryListProvider);
    // Mirror TrajetsTab's filter: when a vehicle is active, show only that
    // vehicle's trips (plus untagged legacy trips); otherwise show all.
    final vehicleId = activeVehicle?.id;
    final tripIds = (vehicleId == null
            ? allTrips
            : allTrips.where(
                (t) => t.vehicleId == null || t.vehicleId == vehicleId))
        .map((t) => t.id)
        .toList(growable: false);
    return PageScaffold(
      title: l?.trajetsTabLabel ?? 'Trips',
      leading: _vehiclesLeading(l),
      bodyPadding: EdgeInsets.zero,
      actions: [ConsumptionAppBarActions(tripIds: tripIds)],
      floatingActionButton: const TrajetsRecordFab(),
      body: TrajetsTab(vehicleId: vehicleId),
    );
  }

  /// #1901 — the Carburant destination: the fill-up list, plus a Fuel /
  /// Charging switcher for a vehicle that can charge.
  Widget _buildFuel(BuildContext context, AppLocalizations? l) {
    final fillUps = ref.watch(fillUpListProvider);
    final chargingLogsAsync = ref.watch(chargingLogsProvider);
    final stats = ref.watch(consumptionStatsProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final showCharging = _shouldShowCharging(activeVehicle);
    _ensureFuelChargingController(showCharging: showCharging);

    final fuelView = FuelTab(fillUps: fillUps, stats: stats, l: l);

    // Pure-combustion vehicle: no Charging slot — render fuel directly,
    // no switcher, and the add-fill-up FAB.
    if (!showCharging) {
      return PageScaffold(
        title: l?.consumptionTabFuel ?? 'Fuel',
        leading: _vehiclesLeading(l),
        bodyPadding: EdgeInsets.zero,
        actions: const [ConsumptionAppBarActions()],
        floatingActionButton: _addFillUpFab(context, l),
        body: fuelView,
      );
    }

    // Hybrid / EV: a compact Fuel / Charging switcher — the user picks
    // which energy form to view (#1901).
    final controller = _tabController!;
    final isCharging = controller.index == 1;
    return PageScaffold(
      title: l?.consumptionTabFuel ?? 'Fuel',
      leading: _vehiclesLeading(l),
      bodyPadding: EdgeInsets.zero,
      actions: const [ConsumptionAppBarActions()],
      floatingActionButton: isCharging
          ? _addChargingFab(context, l)
          : _addFillUpFab(context, l),
      body: Column(
        children: [
          TabSwitcher(
            controller: controller,
            tabs: [
              TabSwitcherEntry(
                label: l?.consumptionTabFuel ?? 'Fuel',
                icon: Icons.local_gas_station_outlined,
              ),
              TabSwitcherEntry(
                label: l?.consumptionTabCharging ?? 'Charging',
                icon: Icons.ev_station_outlined,
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                fuelView,
                ChargingTab(async: chargingLogsAsync, l: l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addFillUpFab(BuildContext context, AppLocalizations? l) =>
      FloatingActionButton.extended(
        key: const Key('fab_add_fillup'),
        onPressed: () => unawaited(context.push(RoutePaths.pickStationForFillUp)),
        icon: const Icon(Icons.add),
        label: Text(l?.addFillUp ?? 'Add fill-up'),
      );

  Widget _addChargingFab(BuildContext context, AppLocalizations? l) =>
      FloatingActionButton.extended(
        key: const Key('fab_add_charging'),
        onPressed: () async {
          await Navigator.of(context).push<bool?>(
            MaterialPageRoute(
              builder: (_) => const AddChargingLogScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l?.addChargingLog ?? 'Log charging'),
      );
}
