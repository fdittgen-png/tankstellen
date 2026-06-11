// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/sync/schema_verifier.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Schema verification step: shows table status and migration SQL.
class WizardSchemaStep extends StatelessWidget {
  final Map<String, bool>? schemaStatus;
  final String? migrationSql;

  /// #2929 — every required table exists, but the database's recorded
  /// schema version is older than this build expects. The self-hoster must
  /// re-run the setup SQL or newer synced features break silently.
  final bool schemaOutdated;
  final VoidCallback onRecheck;
  final VoidCallback onDone;

  const WizardSchemaStep({
    super.key,
    required this.schemaStatus,
    required this.migrationSql,
    required this.onRecheck,
    required this.onDone,
    this.schemaOutdated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (schemaStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tablesReady = SchemaVerifier.requiredTables.every(
      (t) => schemaStatus![t] == true,
    );
    // Outdated schema must be treated like "not ready": the wizard still
    // needs the self-hoster to re-run the SQL before sync is safe.
    final allReady = tablesReady && !schemaOutdated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          allReady ? Icons.check_circle : Icons.warning_amber,
          size: 48,
          color: allReady
              ? DarkModeColors.success(context)
              : DarkModeColors.warning(context),
        ),
        const SizedBox(height: 16),
        Text(
          allReady ? (l10n.syncDatabaseReady) : (l10n.syncDatabaseNeedsSetup),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (tablesReady && schemaOutdated) ...[
          const SizedBox(height: 8),
          Text(
            l10n.syncSchemaOutdated,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DarkModeColors.warning(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),

        // Table status list
        for (final table in [
          ...SchemaVerifier.requiredTables,
          ...SchemaVerifier.optionalTables,
        ])
          ListTile(
            dense: true,
            leading: Icon(
              schemaStatus![table] == true ? Icons.check_circle : Icons.cancel,
              color: schemaStatus![table] == true
                  ? DarkModeColors.success(context)
                  : DarkModeColors.error(context),
              size: 18,
            ),
            title: Text(table, style: theme.textTheme.bodySmall),
            trailing: Text(
              schemaStatus![table] == true
                  ? (l10n.syncTableStatusOk)
                  : (l10n.syncTableStatusMissing),
              style: TextStyle(
                fontSize: 11,
                color: schemaStatus![table] == true
                    ? DarkModeColors.success(context)
                    : DarkModeColors.error(context),
              ),
            ),
          ),

        if (!allReady) ...[
          const SizedBox(height: 16),
          Text(
            l10n.syncSqlEditorInstructions,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              unawaited(
                Clipboard.setData(ClipboardData(text: migrationSql ?? '')),
              );
              SnackBarHelper.show(context, l10n.sqlCopied);
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.syncCopySqlButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRecheck,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.syncRecheckSchemaButton),
          ),
        ],

        if (allReady) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: onDone, child: Text(l10n.syncDoneButton)),
        ],
      ],
    );
  }
}
