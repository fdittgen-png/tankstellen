// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'sync_mode_card.dart';

/// First step of the TankSync setup wizard — lets the user pick between the
/// public Tankstellen Community database, a private Supabase instance, or
/// joining an existing group/family database.
///
/// Behaviour-only widget: stateless, all decisions delegated to callbacks.
///
/// #3871 (Epic #3865, GDPR) — every card carries a compact "controller
/// notice" underneath saying WHO is responsible for the data in that mode
/// (privacy policy v3 Section 2), and the step links to the policy, so
/// the choice is informed at the point it is made.
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
    final communityNotice = l10n.syncModeCommunityControllerNotice(
      AppConstants.dataControllerName,
    );
    final privateTitle = l10n.syncModePrivateTitle;
    final privateSubtitle = l10n.syncModePrivateSubtitle;
    final privatePrivacy = l10n.syncPrivacyPrivate;
    final privateNotice = l10n.syncModePrivateControllerNotice;
    final groupTitle = l10n.syncModeGroupTitle;
    final groupSubtitle = l10n.syncModeGroupSubtitle;
    final groupPrivacy = l10n.syncPrivacyGroup;
    final groupNotice = l10n.syncModeJoinControllerNotice;

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
          label: '$communityTitle, $communityPrivacy. $communitySubtitle. '
              '$communityNotice',
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
        _ControllerNotice(
          key: const Key('sync_mode_community_controller_notice'),
          icon: Icons.admin_panel_settings_outlined,
          text: communityNotice,
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '$privateTitle, $privatePrivacy. $privateSubtitle. '
              '$privateNotice',
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
        _ControllerNotice(
          key: const Key('sync_mode_private_controller_notice'),
          icon: Icons.person_outline,
          text: privateNotice,
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '$groupTitle, $groupPrivacy. $groupSubtitle. $groupNotice',
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
        _ControllerNotice(
          key: const Key('sync_mode_join_controller_notice'),
          icon: Icons.supervisor_account_outlined,
          text: groupNotice,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            key: const Key('sync_mode_privacy_policy_link'),
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.privacy_tip_outlined, size: 16),
            label: Text(l10n.privacyPolicy),
          ),
        ),
        const SizedBox(height: 8),
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

/// One compact "who is the controller" line under a mode card (#3871):
/// a small icon plus wrapping bodySmall text in the muted on-surface
/// colour, so it reads as a footnote to the card above it.
class _ControllerNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ControllerNotice({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: muted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
