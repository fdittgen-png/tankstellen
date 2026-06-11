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

    final communityTitle = l10n.syncModeCommunityTitle;
    final communitySubtitle = l10n.syncModeCommunitySubtitle;
    final communityPrivacy = l10n.syncPrivacyShared;
    final privateTitle = l10n.syncModePrivateTitle;
    final privateSubtitle = l10n.syncModePrivateSubtitle;
    final privatePrivacy = l10n.syncPrivacyPrivate;
    final groupTitle = l10n.syncModeGroupTitle;
    final groupSubtitle = l10n.syncModeGroupSubtitle;
    final groupPrivacy = l10n.syncPrivacyGroup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.syncHowToSyncQuestion,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.syncOfflineDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
            label: Text(l10n.syncStayOfflineButton),
          ),
        ),
      ],
    );
  }
}
