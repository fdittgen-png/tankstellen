// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../sync/presentation/widgets/qr_share_widget.dart';
import 'tank_sync_delete_data_tile.dart';
import 'tank_sync_relink_tile.dart';
import 'tank_sync_schema_outdated_tile.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Displays TankSync cloud sync status and actions.
///
/// When connected, shows mode, auth actions, data management, and
/// danger-zone options (disconnect / delete account). When disconnected,
/// shows an invitation to set up cloud sync.
class TankSyncSection extends ConsumerWidget {
  const TankSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConfig = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: syncConfig.isConfigured
              ? _buildConnected(context, ref, syncConfig, theme)
              : _buildDisconnected(context, AppLocalizations.of(context)),
        ),
      ),
    );
  }

  List<Widget> _buildConnected(
    BuildContext context,
    WidgetRef ref,
    SyncConfig syncConfig,
    ThemeData theme,
  ) {
    final l = AppLocalizations.of(context);
    final consent = ref.watch(gdprConsentProvider);
    return [
      // #3449 — zero-height unless the launch identity guard flagged a
      // stored identity with no session (re-link guidance + start-fresh).
      const TankSyncRelinkTile(),
      // #3560 — zero-height unless the self-host schema is outdated (drift
      // hit this session, or the recorded schema version is behind).
      const TankSyncSchemaOutdatedTile(),
      ListTile(
        leading: Icon(Icons.cloud_done, color: DarkModeColors.success(context)),
        title: Text(syncConfig.modeName),
        subtitle: Text(
          syncConfig.hasEmail
              ? syncConfig.userEmail!
              : 'Anonymous \u00b7 ${syncConfig.userId?.substring(0, 8) ?? ""}...',
        ),
      ),
      if (!syncConfig.hasEmail)
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: Text(l.switchToEmail),
          subtitle: Text(l.switchToEmailSubtitle),
          onTap: () => context.push(RoutePaths.auth),
        )
      else
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l.switchToAnonymousAction),
          subtitle: Text(l.switchToAnonymousSubtitle),
          onTap: () => _confirmSwitchToAnonymous(context, ref),
        ),
      const Divider(indent: 16, endIndent: 16),
      // #1665/#3448 — trajet sync. Recorded trips upload/pull whenever
      // Cloud Sync consent AND this toggle are on: an anonymous UUID is a
      // full identity (its rows are RLS-scoped exactly like an email
      // account's), so the former email requirement was dropped. The
      // anonymous hint explains that email is what makes the data
      // reachable from OTHER devices.
      SwitchListTile(
        key: const Key('tripsSyncToggle'),
        secondary: const Icon(Icons.route_outlined),
        title: Text(l.consentSyncTripsTitle),
        subtitle: Text(
          !consent.cloudSync
              ? (l.consentSyncTripsDisabledHint)
              : !syncConfig.hasEmail
              ? (l.consentSyncTripsAnonymousHint)
              : (l.consentSyncTripsSubtitle),
        ),
        value: consent.syncTrips,
        onChanged: consent.cloudSync
            ? (v) => ref
                  .read(gdprConsentProvider.notifier)
                  .save(
                    location: consent.location,
                    errorReporting: consent.errorReporting,
                    cloudSync: consent.cloudSync,
                    vinOnlineDecode: consent.vinOnlineDecode,
                    syncTrips: v,
                  )
            : null,
      ),
      const Divider(indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(l.viewMyData),
        onTap: () => context.push(RoutePaths.dataTransparency),
      ),
      ListTile(
        leading: const Icon(Icons.link),
        title: Text(l.linkDevice),
        onTap: () => context.push(RoutePaths.linkDevice),
      ),
      // #3453 — per-category server-side deletion; anonymous-capable
      // (RLS scopes to own rows) and available in every mode, community
      // included.
      const TankSyncDeleteDataTile(),
      if (syncConfig.mode != SyncMode.community)
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: Text(l.shareDatabase),
          onTap: () => _showQrShare(context),
        ),
      const Divider(indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l.disconnectAction),
        subtitle: Text(l.disconnectSubtitle),
        onTap: () => _confirmDisconnect(context, ref),
      ),
      if (syncConfig.mode != SyncMode.community)
        ListTile(
          leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
          title: Text(
            l.deleteAccountAction,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: Text(l.deleteAccountSubtitle),
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
    ];
  }

  List<Widget> _buildDisconnected(BuildContext context, AppLocalizations l) {
    return [
      ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(l.localOnly),
        subtitle: Text(l.localOnlySubtitle),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FilledButton.icon(
          onPressed: () => context.push(RoutePaths.syncSetup),
          icon: const Icon(Icons.cloud_upload),
          label: Text(l.setupCloudSync),
        ),
      ),
    ];
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error),
        title: Text(l.disconnectTitle),
        content: Text(l.disconnectBody),
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
            child: Text(l.disconnectAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // #3159 — captured before the dialog await would also work, but the
      // simplest safe shape mirrors the sibling confirmations: only touch
      // the WidgetRef while the element is still mounted.
      if (!context.mounted) return;
      await ref.read(syncStateProvider.notifier).disconnect();
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber,
          color: Theme.of(ctx).colorScheme.error,
          size: 48,
        ),
        title: Text(l.deleteAccountTitle),
        content: Text(l.deleteAccountBody),
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
            child: Text(l.deleteEverything),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(syncStateProvider.notifier).deleteAccount();
      if (context.mounted) {
        SnackBarHelper.show(
          context,
          AppLocalizations.of(context).accountDeleted,
        );
      }
    }
  }

  Future<void> _confirmSwitchToAnonymous(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.swap_horiz, size: 48),
        title: Text(l.switchToAnonymousTitle),
        content: Text(l.switchToAnonymousBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.switchAction),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(syncStateProvider.notifier).switchToAnonymous();
        if (context.mounted) {
          SnackBarHelper.show(
            context,
            AppLocalizations.of(context).switchedToAnonymous,
          );
        }
      } catch (e, st) {
        // #2146 — route to errorLogger so the failure lands on the
        // exportable log (the snackbar is transient).
        unawaited(
          errorLogger.log(
            ErrorLayer.sync,
            e,
            st,
            context: const {'where': 'TankSyncSection: switchToAnonymous'},
          ),
        );
        if (context.mounted) {
          SnackBarHelper.showError(
            context,
            AppLocalizations.of(context).failedToSwitch(e.toString()),
          );
        }
      }
    }
  }

  void _showQrShare(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const QrShareWidget(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(ctx).close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
