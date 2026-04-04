import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/sync/sync_config.dart';

/// Account info card showing UUID and server URL.
class AccountInfoCard extends StatelessWidget {
  final SyncConfig syncConfig;

  const AccountInfoCard({super.key, required this.syncConfig});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InfoRow(label: 'Anonymous UUID', value: syncConfig.userId ?? 'Unknown'),
            InfoRow(label: 'Server', value: syncConfig.supabaseUrl ?? 'Unknown'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Synced data', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            InfoRow(label: 'Favorites', value: '${(data['favorites'] as List?)?.length ?? 0}'),
            InfoRow(label: 'Alerts', value: '${(data['alerts'] as List?)?.length ?? 0}'),
            InfoRow(label: 'Push tokens', value: '${(data['push_tokens'] as List?)?.length ?? 0}'),
            InfoRow(label: 'Price reports', value: '${(data['reports'] as List?)?.length ?? 0}'),
            const Divider(height: 24),
            InfoRow(label: 'Total items', value: '${_countItems()}'),
            InfoRow(label: 'Estimated size', value: _estimateSize()),
          ],
        ),
      ),
    );
  }
}

/// Data action buttons: sync, view JSON, export, delete, disconnect.
class DataActionButtons extends StatelessWidget {
  final bool loading;
  final SyncMode mode;
  final VoidCallback onSync;
  final VoidCallback onViewRawJson;
  final VoidCallback onExportJson;
  final VoidCallback onDeleteAll;
  final VoidCallback onDisconnect;

  const DataActionButtons({
    super.key,
    required this.loading,
    required this.mode,
    required this.onSync,
    required this.onViewRawJson,
    required this.onExportJson,
    required this.onDeleteAll,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onSync,
          icon: const Icon(Icons.sync),
          label: const Text('Sync now'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onViewRawJson,
          icon: const Icon(Icons.code),
          label: const Text('View raw data as JSON'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onExportJson,
          icon: const Icon(Icons.copy),
          label: const Text('Export as JSON (clipboard)'),
        ),
        const SizedBox(height: 24),

        // Destructive actions -- disabled for community mode
        if (mode == SyncMode.community) ...[
          const Card(
            color: Color(0xFFFFF3E0),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data deletion is not available in community '
                      'mode. Disconnect first, or use a private database.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: onDeleteAll,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete all server data'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(Icons.link_off),
          label: const Text('Disconnect TankSync'),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
