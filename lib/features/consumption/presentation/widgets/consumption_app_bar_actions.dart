// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../fill_ups/api.dart';
import '../../../trips/api.dart';
import '../screens/consumption_screen.dart';
import '../../../obd2/api.dart';

/// Navigation targets the overflow kebab dispatches via its single
/// `onSelected` path (#2756). Export / Carbon run from each item's own
/// `onTap` (so the route push happens while the menu route is still on
/// the stack), leaving only the app-global Settings entry to `onSelected`.
enum _OverflowAction { settings }

/// Trailing app-bar actions for the consumption destinations (#2756).
///
/// Material 3 caps a top app bar at ~3 trailing actions before the
/// title starts truncating; the old `_appBarActions` emitted 4–5
/// (OBD2 chip + export + carbon[gated] + Settings, plus the map on
/// Trajets) which clipped "Carburant" to "Car…". This widget keeps only
/// the OBD2 chip (and, on Trajets, the map shortcut) as primary actions
/// and collapses everything else into a single `more_vert` overflow
/// kebab so the title always has room.
///
/// Visible trailing actions:
///   1. [Obd2StatusChip] — self-hides when no adapter is connected.
///   2. Map shortcut — **Trajets only** (`tripIds != null`), opening
///      [TrajetsMapScreen] for the visible trips.
///   3. A single overflow kebab holding Export backup, Restore backup,
///      the gated Carbon dashboard, a divider, then Settings.
///
/// `tripIds == null` ⇒ Carburant (no map shortcut); a non-null list ⇒
/// Trajets (map shortcut shown, routing to those trips).
///
/// Rendered as a single [Row] so the screen can drop it straight into
/// `PageScaffold(actions: [ConsumptionAppBarActions(...)])` and have the
/// gated Carbon item rebuild reactively with `enabledFeaturesProvider`.
class ConsumptionAppBarActions extends ConsumerWidget {
  /// The visible Trajets' ids, forwarded to [TrajetsMapScreen] by the
  /// map shortcut. `null` selects the Carburant layout (no map action).
  final List<String>? tripIds;

  const ConsumptionAppBarActions({super.key, this.tripIds});

  /// Run the full XML-in-ZIP backup export pipeline (#1317) through the
  /// shared [BackupExportFlow] (#3884 — one implementation for this menu
  /// and Settings → Backup & restore), preserving the
  /// [ConsumptionScreen.debugExporterOverride] test seam so the export
  /// widget tests keep driving a recording exporter.
  Future<void> _runBackupExport(BuildContext context, WidgetRef ref) async {
    await BackupExportFlow.run(
      context,
      ref,
      // The export test seam still lives on ConsumptionScreen so the
      // existing `ConsumptionScreen.debugExporterOverride = …` widget
      // tests keep driving a recording exporter through this extracted
      // action widget (#2756).
      // ignore: invalid_use_of_visible_for_testing_member
      exporter: ConsumptionScreen.debugExporterOverride,
      where: 'ConsumptionAppBarActions._runBackupExport failed',
    );
  }

  void _onSelected(BuildContext context, _OverflowAction action) {
    switch (action) {
      case _OverflowAction.settings:
        context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final carbonEnabled = ref
        .watch(enabledFeaturesProvider)
        .contains(Feature.carbonDashboard);
    final ids = tripIds;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // #797 phase 3 — title-bar chip announcing "OBD2 connected".
        const Obd2StatusChip(),
        // #2030 — the Trajets map shortcut stays a primary (visible)
        // action; Carburant has no map so the list is null there.
        if (ids != null)
          IconButton(
            key: const Key('trajets_view_all_on_map'),
            tooltip: l.trajetsViewAllOnMap,
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TrajetsMapScreen(tripIds: ids),
                  ),
                ),
              );
            },
          ),
        PopupMenuButton<_OverflowAction>(
          key: const Key('consumption_overflow_menu'),
          icon: const Icon(Icons.more_vert),
          tooltip: l.moreActionsTooltip,
          onSelected: (action) => _onSelected(context, action),
          // The outer `context` (not the menu's) is captured by every
          // `onTap` below: PopupMenuItem.onTap fires after the menu
          // route has popped, so the menu's own context is already
          // defunct for navigation / SnackBars.
          itemBuilder: (_) => [
            PopupMenuItem<_OverflowAction>(
              key: const Key('export_backup'),
              onTap: () => unawaited(_runBackupExport(context, ref)),
              child: _MenuRow(
                icon: Icons.download_outlined,
                label: l.exportBackupMenuLabel,
              ),
            ),
            // #2571 — full-backup restore. The flow (pick .zip →
            // merge/replace confirm → import → feedback) lives in
            // [BackupRestoreFlow].
            PopupMenuItem<_OverflowAction>(
              key: const Key('restore_backup'),
              onTap: () => unawaited(BackupRestoreFlow.run(context, ref)),
              child: _MenuRow(
                icon: Icons.restore_outlined,
                label: l.restoreBackupMenuLabel,
              ),
            ),
            if (carbonEnabled)
              PopupMenuItem<_OverflowAction>(
                key: const Key('open_carbon_dashboard'),
                onTap: () => context.push(RoutePaths.carbon),
                child: _MenuRow(
                  icon: Icons.eco_outlined,
                  label: l.carbonDashboardMenuLabel,
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem<_OverflowAction>(
              value: _OverflowAction.settings,
              child: _MenuRow(
                icon: Icons.settings_outlined,
                label: l.settingsMenuLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A leading-icon + label row for an overflow [PopupMenuItem], so the
/// menu reads like the actions it replaced (each carried an icon in the
/// old trailing layout).
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        // A PopupMenuItem bounds its child to ~256 dp; let a long label
        // (e.g. the German "Sicherung wiederherstellen" or the en_XA
        // pseudo-locale) shrink + ellipsize rather than overflow.
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
