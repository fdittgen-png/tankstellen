// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// #3449 — the relink-required guidance inside the TankSync settings
/// section.
///
/// Rendered only while `SyncConfig.relinkRequired` is set (the launch
/// identity guard found a stored `sync_user_id` with no live session and
/// refused to mint a fresh anonymous UUID over it). Two ways out:
///
///  * **Sign in** — the email auth screen re-links the same identity
///    (an email sign-in restores the account that owns the stored data);
///  * **Start fresh** — an explicit, confirmed choice to abandon the old
///    UUID: `switchToAnonymous()` signs in anonymously and adopts the new
///    id. This is exactly the silent behaviour the guard removed — now it
///    only ever happens knowingly.
///
/// Both paths construct a fresh `SyncConfig`, clearing the flag.
class TankSyncRelinkTile extends ConsumerWidget {
  const TankSyncRelinkTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncConfig = ref.watch(syncStateProvider);
    if (!syncConfig.relinkRequired) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          key: const Key('tankSyncRelinkTile'),
          leading: Icon(Icons.link_off, color: theme.colorScheme.error),
          title: Text(l.syncRelinkTitle),
          subtitle: Text(l.syncRelinkBody),
          isThreeLine: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.auth),
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l.syncRelinkSignInAction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmStartFresh(context, ref),
                  child: Text(l.syncRelinkStartFreshAction),
                ),
              ),
            ],
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
      ],
    );
  }

  Future<void> _confirmStartFresh(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error),
        title: Text(l.syncRelinkStartFreshTitle),
        content: Text(l.syncRelinkStartFreshBody),
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
            child: Text(l.syncRelinkStartFreshConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      // Knowingly abandon the old UUID: mint a new anonymous identity.
      await ref.read(syncStateProvider.notifier).switchToAnonymous();
      if (context.mounted) {
        SnackBarHelper.show(
          context,
          AppLocalizations.of(context).switchedToAnonymous,
        );
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'TankSyncRelinkTile: start fresh'}));
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          AppLocalizations.of(context).failedToSwitch(e.toString()),
        );
      }
    }
  }
}
