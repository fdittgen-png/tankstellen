// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/data_transparency_provider.dart';

/// #3868 (Epic #3865) — the user's own community contributions with a
/// per-row delete. Price reports (free text, readable by every signed-in
/// user in Sparkilo Community) and content reports could only ever be
/// removed by deleting the whole account; RLS permitted the row delete
/// all along — the UI was missing.
class MyCommunityReportsCard extends ConsumerWidget {
  const MyCommunityReportsCard({super.key, required this.data});

  /// The `UserDataSync.fetchAll` map.
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rows = <_ReportRow>[
      for (final r in (data['price_reports'] as List? ?? const []))
        if (r is Map)
          _ReportRow(
            table: 'price_reports',
            id: r['id'],
            headline: '${r['station_id'] ?? ''} · ${r['fuel_type'] ?? ''}',
            detail: '${r['correction_text'] ?? r['reported_price'] ?? ''}',
          ),
      for (final r in (data['content_reports'] as List? ?? const []))
        if (r is Map)
          _ReportRow(
            table: 'content_reports',
            id: r['id'],
            headline: '${r['target_kind'] ?? ''} · ${r['target_id'] ?? ''}',
            detail: '${r['reason'] ?? ''}',
          ),
    ];
    return Card(
      key: const Key('myCommunityReportsCard'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.myCommunityReportsTitle, style: theme.textTheme.titleSmall),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.myCommunityReportsEmpty,
                    style: theme.textTheme.bodySmall),
              ),
            for (final row in rows)
              ListTile(
                key: Key('report-${row.table}-${row.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(row.headline, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(row.detail, maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: l.deleteReportTooltip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: row.id == null
                      ? null
                      : () => _delete(context, ref, row),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, _ReportRow row) async {
    final ok = await ref
        .read(dataTransparencyControllerProvider.notifier)
        .deleteOwnRow(table: row.table, idColumn: 'id', id: row.id!);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    if (ok) {
      SnackBarHelper.showSuccess(context, l.reportDeleted);
    } else {
      SnackBarHelper.showError(context, l.reportDeleteFailed);
    }
  }
}

class _ReportRow {
  const _ReportRow({
    required this.table,
    required this.id,
    required this.headline,
    required this.detail,
  });
  final String table;
  final Object? id;
  final String headline;
  final String detail;
}
