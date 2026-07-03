// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/synced_data_deletion.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// #3453 — "delete my synced data" inside the TankSync settings section.
///
/// Per-category (trips, vehicles, fill-ups) or everything; works for
/// ANONYMOUS users (RLS + the user-scoped transport confine the wipe to
/// the caller's own rows, community database included — cf. #3081).
///
/// Decision (per the issue): the wipe is **server-side ONLY** — data
/// stored locally on this device is kept, and the confirmation dialog
/// copy says so explicitly. Tombstones written by the wipe make other
/// devices drop their copies on their next pull instead of resurrecting
/// them (#3078). The identity stays usable afterwards, including after
/// "everything".
class TankSyncDeleteDataTile extends ConsumerWidget {
  const TankSyncDeleteDataTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ListTile(
      key: const Key('tankSyncDeleteDataTile'),
      leading: const Icon(Icons.delete_sweep_outlined),
      title: Text(l.syncDeleteDataTitle),
      subtitle: Text(l.syncDeleteDataSubtitle),
      onTap: () => _pickAndDelete(context),
    );
  }

  String _categoryLabel(AppLocalizations l, SyncedDataCategory category) =>
      switch (category) {
        SyncedDataCategory.trips => l.syncDeleteDataCategoryTrips,
        SyncedDataCategory.vehicles => l.syncDeleteDataCategoryVehicles,
        SyncedDataCategory.fillUps => l.syncDeleteDataCategoryFillUps,
        SyncedDataCategory.everything => l.syncDeleteDataCategoryEverything,
      };

  Future<void> _pickAndDelete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final category = await showDialog<SyncedDataCategory>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.syncDeleteDataPickTitle),
        children: [
          for (final c in SyncedDataCategory.values)
            SimpleDialogOption(
              key: Key('syncDeleteDataOption_${c.name}'),
              onPressed: () => Navigator.pop(ctx, c),
              child: Text(
                _categoryLabel(l, c),
                style: c == SyncedDataCategory.everything
                    ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (category == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error),
        title: Text(l.syncDeleteDataConfirmTitle(_categoryLabel(l, category))),
        // The server-side-only decision, spelled out where it matters:
        // this device's local data is kept; other devices drop their
        // copies on their next sync.
        content: Text(l.syncDeleteDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.syncDeleteDataConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await SyncedDataDeletion.delete(category);
    if (!context.mounted) return;
    if (ok) {
      SnackBarHelper.show(
        context,
        AppLocalizations.of(context).syncDeleteDataDone,
      );
    } else {
      SnackBarHelper.showError(
        context,
        AppLocalizations.of(context).syncDeleteDataFailed,
      );
    }
  }
}
