// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_provider.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/sync/trips_sync.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/data_transparency_provider.dart';
import '../widgets/data_transparency_cards.dart';

/// Shows all data stored on the server for the current user.
class DataTransparencyScreen extends ConsumerWidget {
  const DataTransparencyScreen({super.key});

  String _prettyJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> _showRawJson(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final json = _prettyJson(data);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).rawDataJson),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    await Clipboard.setData(ClipboardData(text: _prettyJson(data)));
    if (!context.mounted) return;
    SnackBarHelper.show(context, AppLocalizations.of(context).jsonCopied);
  }

  Future<void> _forceSyncAndReload(BuildContext context, WidgetRef ref) async {
    await ref
        .read(dataTransparencyControllerProvider.notifier)
        .forceSyncAndReload();
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(
      context,
      AppLocalizations.of(context).syncCompleted,
    );
  }

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteServerDataConfirm),
        content: Text(AppLocalizations.of(context).deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DarkModeColors.error(context),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).deleteEverything),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(dataTransparencyControllerProvider.notifier).deleteAllData();
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(
      context,
      AppLocalizations.of(context).allDataDeleted,
    );
  }

  Future<void> _forgetAllTrips(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.forgetAllSyncedTripsConfirmTitle),
        content: Text(l.forgetAllSyncedTripsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('forget_all_synced_trips_confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: DarkModeColors.error(context),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.forgetAllSyncedTripsConfirmAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await TripsSync.forgetAllForUser();
    // Re-run the transparency fetch so the synced-data card reflects
    // the empty server-side state without forcing the user to pull-
    // to-refresh.
    await ref
        .read(dataTransparencyControllerProvider.notifier)
        .forceSyncAndReload();
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, l.forgetAllSyncedTripsSuccess);
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).disconnectTitle),
        content: Text(AppLocalizations.of(context).disconnectBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).disconnectAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(syncStateProvider.notifier).disconnect();
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConfig = ref.watch(syncStateProvider);
    final uiState = ref.watch(dataTransparencyControllerProvider);
    final theme = Theme.of(context);

    return PageScaffold(
      title: AppLocalizations.of(context).myServerData,
      bodyPadding: EdgeInsets.zero,
      body: uiState.loading
          ? const Center(child: CircularProgressIndicator())
          : uiState.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  uiState.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AccountInfoCard(syncConfig: syncConfig),
                const SizedBox(height: 12),
                if (uiState.data != null) ...[
                  SyncedDataCard(data: uiState.data!),
                  const SizedBox(height: 16),
                  DataActionButtons(
                    loading: uiState.loading,
                    onSync: () => _forceSyncAndReload(context, ref),
                    onViewRawJson: () => _showRawJson(context, uiState.data!),
                    onExportJson: () => _exportJson(context, uiState.data!),
                    onDeleteAll: () => _deleteAllData(context, ref),
                    onForgetAllTrips: () => _forgetAllTrips(context, ref),
                    onDisconnect: () => _disconnect(context, ref),
                  ),
                ],
              ],
            ),
    );
  }
}
