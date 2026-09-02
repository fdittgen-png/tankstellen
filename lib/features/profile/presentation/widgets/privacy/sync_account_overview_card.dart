// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/sync/sync_provider.dart';
import '../../../../../core/theme/dark_mode_colors.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../sync/api.dart' show baselineSyncEnabledProvider;
import 'privacy_status_text.dart';

/// The plain-language TankSync overview (#3911, Epic #3907): status,
/// mode (with what it means), account kind, the full user id with a
/// copy action, the database host, and the learned-vehicle-profiles
/// switch. Every value sits on its own line under its label, so nothing
/// truncates — the former dashboard card ellipsised the id and the URL.
class SyncAccountOverviewCard extends ConsumerWidget {
  const SyncAccountOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = ref.watch(syncStateProvider);
    final connected = sync.isConfigured;
    final userId = sync.userId;
    final url = sync.supabaseUrl;
    return SectionCard(
      key: const Key('syncAccountOverviewCard'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ValueTile(
            key: const Key('syncOverviewStatus'),
            icon: connected ? Icons.cloud_done : Icons.cloud_off,
            iconColor: connected
                ? DarkModeColors.success(context)
                : theme.colorScheme.onSurfaceVariant,
            label: l.privacySyncStatusLabel,
            value: connected
                ? l.configTankSyncConnected
                : l.configTankSyncDisabled,
          ),
          if (connected) ...[
            _ValueTile(
              key: const Key('syncOverviewMode'),
              icon: Icons.sync,
              label: l.privacySyncMode,
              value: PrivacyStatusText.modeLine(l, sync.mode),
            ),
            _ValueTile(
              key: const Key('syncOverviewAccount'),
              icon: sync.hasEmail ? Icons.email_outlined : Icons.person_outline,
              label: l.privacySyncAccountLabel,
              value: sync.hasEmail
                  ? l.privacySyncAccountEmail(sync.userEmail!)
                  : l.privacySyncAccountAnonymous,
            ),
            if (userId != null)
              _ValueTile(
                key: const Key('syncOverviewUserId'),
                icon: Icons.perm_identity,
                label: l.privacySyncUserId,
                value: userId,
                monospace: true,
                trailing: IconButton(
                  key: const Key('syncOverviewCopyUserId'),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: l.privacyCopyUserId,
                  onPressed: () => _copyUserId(context, userId),
                ),
              ),
            if (url != null)
              _ValueTile(
                key: const Key('syncOverviewHost'),
                icon: Icons.dns_outlined,
                label: l.privacySyncDatabaseHost,
                value: PrivacyStatusText.databaseHost(url),
                monospace: true,
              ),
            // #780 phase 3 — opt-in toggle for per-vehicle baseline sync.
            // Default false; flips to true only when the user enables it.
            SwitchListTile(
              key: const Key('syncBaselinesToggle'),
              secondary: const Icon(Icons.directions_car_outlined, size: 20),
              value: ref.watch(baselineSyncEnabledProvider),
              title: Text(l.syncBaselinesToggleTitle),
              subtitle: Text(l.syncBaselinesToggleSubtitle,
                  style: theme.textTheme.bodySmall),
              onChanged: (v) =>
                  ref.read(baselineSyncEnabledProvider.notifier).set(v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l.privacySyncDescription,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copyUserId(BuildContext context, String userId) async {
    final l = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
    SnackBarHelper.showSuccess(context, l.privacyUserIdCopied);
  }
}

/// Label above, value below on its own line (wrapping), optional
/// trailing action — the two-line shape that never ellipsises.
class _ValueTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final bool monospace;
  final Widget? trailing;

  const _ValueTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.monospace = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        label,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: monospace ? 'monospace' : null,
          fontFeatures: monospace
              ? const [FontFeature.tabularFigures()]
              : null,
        ),
      ),
      trailing: trailing,
    );
  }
}
