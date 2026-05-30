// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../core/theme/dark_mode_colors.dart';
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

    final communityTitle =
        l10n?.syncModeCommunityTitle ?? 'Sparkilo Community';
    final communitySubtitle = l10n?.syncModeCommunitySubtitle ??
        'Share favorites & ratings with all users';
    final communityPrivacy = l10n?.syncPrivacyShared ?? 'Shared';
    final privateTitle = l10n?.syncModePrivateTitle ?? 'Private Database';
    final privateSubtitle = l10n?.syncModePrivateSubtitle ??
        'Your own Supabase — full data control';
    final privatePrivacy = l10n?.syncPrivacyPrivate ?? 'Private';
    final groupTitle = l10n?.syncModeGroupTitle ?? 'Join a Group';
    final groupSubtitle =
        l10n?.syncModeGroupSubtitle ?? 'Family or friends shared database';
    final groupPrivacy = l10n?.syncPrivacyGroup ?? 'Group';

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
          label: '$communityTitle, $communityPrivacy. $communitySubtitle',
          button: true,
          child: SyncModeCard(
            icon: Icons.public,
            title: communityTitle,
            subtitle: communitySubtitle,
            privacyLabel: communityPrivacy,
            privacyColor: DarkModeColors.success(context),
            onTap: () => onSelectMode(SyncMode.community),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '$privateTitle, $privatePrivacy. $privateSubtitle',
          button: true,
          child: SyncModeCard(
            icon: Icons.lock_outline,
            title: privateTitle,
            subtitle: privateSubtitle,
            privacyLabel: privatePrivacy,
            privacyColor: Colors.blue,
            onTap: () => onSelectMode(SyncMode.private),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '$groupTitle, $groupPrivacy. $groupSubtitle',
          button: true,
          child: SyncModeCard(
            icon: Icons.group_outlined,
            title: groupTitle,
            subtitle: groupSubtitle,
            privacyLabel: groupPrivacy,
            privacyColor: DarkModeColors.warning(context),
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
