// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Account info card showing UUID and server URL.
class AccountInfoCard extends StatelessWidget {
  final SyncConfig syncConfig;

  const AccountInfoCard({super.key, required this.syncConfig});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.account, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InfoRow(
              label: l.anonymousUuid,
              value: syncConfig.userId ?? 'Unknown',
            ),
            InfoRow(
              label: l.server,
              value: syncConfig.supabaseUrl ?? 'Unknown',
            ),
          ],
        ),
      ),
    );
  }
}

/// Data summary card showing counts of synced items.
class SyncedDataCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const SyncedDataCard({super.key, required this.data});

  int _countItems() {
    int count = 0;
    for (final value in data.values) {
      if (value is List) count += value.length;
    }
    return count;
  }

  String _estimateSize() {
    final json = const JsonEncoder().convert(data);
    final bytes = utf8.encode(json).length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.syncedData, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InfoRow(
              label: l.favorites,
              value: '${(data['favorites'] as List?)?.length ?? 0}',
            ),
            InfoRow(
              label: l.priceAlerts,
              value: '${(data['alerts'] as List?)?.length ?? 0}',
            ),
            InfoRow(
              label: l.pushTokens,
              value: '${(data['push_tokens'] as List?)?.length ?? 0}',
            ),
            InfoRow(
              label: l.priceReports,
              value: '${(data['reports'] as List?)?.length ?? 0}',
            ),
            // #2107 — `trip_summaries` is the canonical row-per-trip
            // count; `trip_details` rolls into Total items / Estimated
            // size below via the generic `_countItems` / `_estimateSize`
            // walk over `data.values`, but the user-facing Trips row
            // only shows the summary count (one per trip).
            InfoRow(
              label: l.syncedTrips,
              value: '${(data['trip_summaries'] as List?)?.length ?? 0}',
            ),
            const Divider(height: 24),
            InfoRow(label: l.totalItems, value: '${_countItems()}'),
            InfoRow(label: l.estimatedSize, value: _estimateSize()),
          ],
        ),
      ),
    );
  }
}

/// Data action buttons: sync, view JSON, export, delete, disconnect.
class DataActionButtons extends StatelessWidget {
  final bool loading;
  final VoidCallback onSync;
  final VoidCallback onViewRawJson;
  final VoidCallback onExportJson;
  final VoidCallback onDeleteAll;
  final VoidCallback onForgetAllTrips;
  final VoidCallback onDisconnect;

  const DataActionButtons({
    super.key,
    required this.loading,
    required this.onSync,
    required this.onViewRawJson,
    required this.onExportJson,
    required this.onDeleteAll,
    required this.onForgetAllTrips,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onSync,
          icon: const Icon(Icons.sync),
          label: Text(l.syncNow),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onViewRawJson,
          icon: const Icon(Icons.code),
          label: Text(l.viewRawJson),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onExportJson,
          icon: const Icon(Icons.copy),
          label: Text(l.exportJson),
        ),
        const SizedBox(height: 24),

        // Destructive actions. Available in every mode, including community
        // (#3081): each synced table's RLS is `FOR ALL USING (user_id =
        // auth.uid())`, so a user can only ever delete their *own* rows —
        // deleting your private data never touches the shared community DB's
        // other users. A confirmation dialog still gates each action.
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: DarkModeColors.error(context),
          ),
          onPressed: onDeleteAll,
          icon: const Icon(Icons.delete_forever),
          label: Text(l.deleteAllServerData),
        ),
        const SizedBox(height: 8),
        // #1541 — narrower destructive action: wipes only the
        // synced trip history (both `trip_summaries` and
        // `trip_details`) without touching the user's other
        // server-side data. Outlined rather than filled so it
        // visually defers to the broader "Delete all server data"
        // above it.
        OutlinedButton.icon(
          key: const Key('forget_all_synced_trips_button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DarkModeColors.error(context),
          ),
          onPressed: onForgetAllTrips,
          icon: const Icon(Icons.history_toggle_off),
          label: Text(l.forgetAllSyncedTripsButton),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(Icons.link_off),
          label: Text(l.disconnectTankSync),
        ),
      ],
    );
  }
}

/// A label-value row used in info cards.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
