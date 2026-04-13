import 'package:flutter/material.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../l10n/app_localizations.dart';
import 'sync_mode_card.dart';

/// First step of the TankSync setup wizard — lets the user pick between the
/// public Tankstellen Community database, a private Supabase instance, or
/// joining an existing group/family database.
///
/// Behaviour-only widget: stateless, all decisions delegated to callbacks.
class SyncModeStep extends StatelessWidget {
  final ValueChanged<SyncMode> onSelectMode;
  final VoidCallback onStayOffline;

  const SyncModeStep({
    super.key,
    required this.onSelectMode,
    required this.onStayOffline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n?.syncHowToSyncQuestion ?? 'How would you like to sync?',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n?.syncOfflineDescription ??
              'Your app works fully offline. Cloud sync is optional.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Semantics(
          label:
              'Tankstellen Community, shared. Share favorites and ratings with all users.',
          button: true,
          child: SyncModeCard(
            icon: Icons.public,
            title: l10n?.syncModeCommunityTitle ?? 'Tankstellen Community',
            subtitle: l10n?.syncModeCommunitySubtitle ??
                'Share favorites & ratings with all users',
            privacyLabel: l10n?.syncPrivacyShared ?? 'Shared',
            privacyColor: Colors.green,
            onTap: () => onSelectMode(SyncMode.community),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label:
              'Private Database, private. Your own Supabase, full data control.',
          button: true,
          child: SyncModeCard(
            icon: Icons.lock_outline,
            title: l10n?.syncModePrivateTitle ?? 'Private Database',
            subtitle: l10n?.syncModePrivateSubtitle ??
                'Your own Supabase — full data control',
            privacyLabel: l10n?.syncPrivacyPrivate ?? 'Private',
            privacyColor: Colors.blue,
            onTap: () => onSelectMode(SyncMode.private),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label:
              'Join a Group, group access. Family or friends shared database.',
          button: true,
          child: SyncModeCard(
            icon: Icons.group_outlined,
            title: l10n?.syncModeGroupTitle ?? 'Join a Group',
            subtitle: l10n?.syncModeGroupSubtitle ??
                'Family or friends shared database',
            privacyLabel: l10n?.syncPrivacyGroup ?? 'Group',
            privacyColor: Colors.orange,
            onTap: () => onSelectMode(SyncMode.joinExisting),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: onStayOffline,
            icon: const Icon(Icons.signal_wifi_off, size: 16),
            label: Text(l10n?.syncStayOfflineButton ?? 'Stay offline'),
          ),
        ),
      ],
    );
  }
}
