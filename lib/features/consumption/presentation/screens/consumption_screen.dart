// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/settings_app_bar_action.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/tab_switcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/exporters/backup/full_backup_exporter.dart';
import '../../providers/charging_logs_provider.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/charging_tab.dart';
import '../widgets/fuel_tab.dart';
import '../widgets/obd2_status_chip.dart';
import '../widgets/trajets_tab.dart';
import 'add_charging_log_screen.dart';
import '../../../../core/logging/error_logger.dart';

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

  /// Run the full XML-in-ZIP backup export pipeline (#1317).
  ///
  /// Pulls the latest vehicles / fill-ups / trips / charging-log
  /// snapshots from the Riverpod graph, hands them to
  /// [FullBackupExporter], and surfaces a confirmation snackbar on
  /// success or a styled error snack on failure. The exporter itself
  /// owns the temp-file write + share-sheet handoff, so the screen
  /// stays purely orchestration.
  Future<void> _runBackupExport() async {
    final l = AppLocalizations.of(context);
    try {
      final vehicles = ref.read(vehicleProfileListProvider);
      final fillUps = ref.read(fillUpListProvider);
      final tripsRepo = ref.read(tripHistoryRepositoryProvider);
      final trips = tripsRepo?.loadAll() ?? const [];
      final chargingLogs =
          ref.read(chargingLogsProvider).asData?.value ?? const [];

      final exporter =
          ConsumptionScreen.debugExporterOverride ?? FullBackupExporter();
      final result = await exporter.export(
        vehicles: vehicles,
        fillUps: fillUps,
        trips: trips,
        chargingLogs: chargingLogs,
      );

      if (!mounted) return;
      // #2014 — when the exporter also wrote a copy to the device's
      // public Downloads folder, confirm with a folder-level snackbar.
      // The exact path / content URI varies per platform (MediaStore on
      // Android Q+) and is not useful for users to read — just point
      // them at "your Downloads folder". Falls back to the legacy
      // "Backup ready" snackbar when the save-to-Downloads step bailed.
      final message = (result.savedPath != null)
          ? (l?.savedToDownloadsFolder ?? 'Saved to your Downloads folder')
          : (l?.exportBackupReady ?? 'Backup ready — pick a destination');
      SnackBarHelper.showSuccess(context, message);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'ConsumptionScreen._runBackupExport failed'}));
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        l?.exportBackupFailed ?? 'Backup export failed — please try again',
      );
    }
  }

  /// AppBar actions shared by both sections (#1901): the OBD2 status
  /// chip, the backup export button, the gated Carbon dashboard entry
  /// point, and the Settings action.
  List<Widget> _appBarActions(AppLocalizations? l) => [
        // #797 phase 3 — title-bar chip announcing "OBD2 connected".
        const Obd2StatusChip(),
        IconButton(
          key: const Key('export_backup'),
          tooltip: l?.exportBackupTooltip ?? 'Export backup',
          icon: const Icon(Icons.download_outlined),
          onPressed: () => unawaited(_runBackupExport()),
        ),
        // #1613 — the Carbon dashboard entry point is gated on the
        // central Feature enum so it can be toggled per profile.
        if (ref
            .watch(enabledFeaturesProvider)
            .contains(Feature.carbonDashboard))
          IconButton(
            key: const Key('open_carbon_dashboard'),
            tooltip: l?.carbonDashboardTitle ?? 'Carbon dashboard',
            icon: const Icon(Icons.eco_outlined),
            onPressed: () => context.push('/carbon'),
          ),
        // #1946 — vehicle entry point in the consumption app bar.
        IconButton(
          key: const Key('open_vehicles'),
          tooltip: l?.vehiclesMenuTitle ?? 'My vehicles',
          icon: const Icon(Icons.directions_car_outlined),
          onPressed: () => context.push('/vehicles'),
        ),
        const SettingsAppBarAction(),
      ];

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

  /// #1901 — the Trajets destination: OBD2 trip history. No FAB (the
  /// "Start recording" CTA lives in the tab header) and no in-screen
  /// tab bar.
  Widget _buildTrajets(BuildContext context, AppLocalizations? l) {
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    return PageScaffold(
      title: l?.trajetsTabLabel ?? 'Trips',
      bodyPadding: EdgeInsets.zero,
      actions: _appBarActions(l),
      body: TrajetsTab(vehicleId: activeVehicle?.id),
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
        bodyPadding: EdgeInsets.zero,
        actions: _appBarActions(l),
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
      bodyPadding: EdgeInsets.zero,
      actions: _appBarActions(l),
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
        onPressed: () => unawaited(context.push('/consumption/pick-station')),
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
