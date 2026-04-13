import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../sync/presentation/widgets/qr_share_widget.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
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
    return [
      ListTile(
        leading: const Icon(Icons.cloud_done, color: Colors.green),
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
          title: Text(l?.switchToEmail ?? 'Switch to email'),
          subtitle: Text(l?.switchToEmailSubtitle ?? 'Keep data, add sign-in from other devices'),
          onTap: () => context.push('/auth'),
        )
      else
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(l?.switchToAnonymousAction ?? 'Switch to anonymous'),
          subtitle: Text(l?.switchToAnonymousSubtitle ?? 'Keep local data, use new anonymous session'),
          onTap: () => _confirmSwitchToAnonymous(context, ref),
        ),
      const Divider(indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(l?.viewMyData ?? 'View my data'),
        onTap: () => context.push('/data-transparency'),
      ),
      ListTile(
        leading: const Icon(Icons.link),
        title: Text(l?.linkDevice ?? 'Link device'),
        onTap: () => context.push('/link-device'),
      ),
      if (syncConfig.mode != SyncMode.community)
        ListTile(
          leading: const Icon(Icons.qr_code),
          title: Text(l?.shareDatabase ?? 'Share database'),
          onTap: () => _showQrShare(context),
        ),
      const Divider(indent: 16, endIndent: 16),
      ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l?.disconnectAction ?? 'Disconnect'),
        subtitle: Text(l?.disconnectSubtitle ?? 'Stop syncing (local data kept)'),
        onTap: () => _confirmDisconnect(context, ref),
      ),
      if (syncConfig.mode != SyncMode.community)
        ListTile(
          leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
          title: Text(l?.deleteAccountAction ?? 'Delete account',
              style: TextStyle(color: theme.colorScheme.error)),
          subtitle: Text(l?.deleteAccountSubtitle ?? 'Remove all server data permanently'),
          onTap: () => _confirmDeleteAccount(context, ref),
        ),
    ];
  }

  List<Widget> _buildDisconnected(BuildContext context, AppLocalizations? l) {
    return [
      ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(l?.localOnly ?? 'Local only'),
        subtitle: Text(l?.localOnlySubtitle ??
            'Optional: sync favorites, alerts, and ratings across devices'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FilledButton.icon(
          onPressed: () => context.push('/sync-setup'),
          icon: const Icon(Icons.cloud_upload),
          label: Text(l?.setupCloudSync ?? 'Set up cloud sync'),
        ),
      ),
    ];
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber,
            color: Theme.of(ctx).colorScheme.error),
        title: Text(l?.disconnectTitle ?? 'Disconnect TankSync?'),
        content: Text(l?.disconnectBody ??
          'Cloud sync will be disabled. Your local data (favorites, alerts, history) '
          'is preserved on this device. Server data is not deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l?.cancel ?? 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l?.disconnectAction ?? 'Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(syncStateProvider.notifier).disconnect();
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber,
            color: Theme.of(ctx).colorScheme.error, size: 48),
        title: Text(l?.deleteAccountTitle ?? 'Delete account?'),
        content: Text(l?.deleteAccountBody ??
          'This permanently deletes all your data from the server '
          '(favorites, alerts, ratings, routes). '
          'Local data on this device is preserved.\n\n'
          'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l?.cancel ?? 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l?.deleteEverything ?? 'Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(syncStateProvider.notifier).deleteAccount();
      if (context.mounted) {
        SnackBarHelper.show(context, AppLocalizations.of(context)?.accountDeleted ?? 'Account deleted. Local data preserved.');
      }
    }
  }

  Future<void> _confirmSwitchToAnonymous(
      BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.swap_horiz, size: 48),
        title: Text(l?.switchToAnonymousTitle ?? 'Switch to anonymous?'),
        content: Text(l?.switchToAnonymousBody ??
          'You will be signed out of your email account and continue '
          'with a new anonymous session.\n\n'
          'Your local data (favorites, alerts) is kept on this device '
          'and will be synced to the new anonymous account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l?.switchAction ?? 'Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(syncStateProvider.notifier).switchToAnonymous();
        if (context.mounted) {
          SnackBarHelper.show(context, AppLocalizations.of(context)?.switchedToAnonymous ?? 'Switched to anonymous session');
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showError(context, AppLocalizations.of(context)?.failedToSwitch(e.toString()) ?? 'Failed to switch: $e');
        }
      }
    }
  }

  void _showQrShare(BuildContext context) {
    showDialog(
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
                child: Text(AppLocalizations.of(ctx)?.close ?? 'Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
