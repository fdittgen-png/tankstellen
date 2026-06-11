// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/profile_provider.dart';

/// Configuration verification card.
///
/// Displays a summary of active profile settings, API keys, cloud sync
/// status, and a privacy summary. Detailed data counts are in the
/// Privacy Dashboard instead.
class ConfigVerificationWidget extends ConsumerWidget {
  const ConfigVerificationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final apiKeys = ref.read(apiKeyStorageProvider);
    final syncConfig = ref.watch(syncStateProvider);
    final profile = ref.watch(activeProfileProvider);
    // #521 — hasApiKey is always true now (community default always
    // available). We render one of two states based on hasCustomApiKey
    // instead: user-configured key vs shipped default.
    final hasCustomApiKey = apiKeys.hasCustomApiKey();
    final isEmail = syncConfig.hasEmail;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, l.configProfileSection),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.person,
              label: l.configActiveProfile,
              value: profile?.name ?? (l.configNone),
              status: profile != null ? _Status.ok : _Status.warning,
            ),
            _ConfigRow(
              icon: Icons.local_gas_station,
              label: l.configPreferredFuel,
              value: profile?.preferredFuelType.displayName ?? '\u2014',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.language,
              label: l.configCountry,
              value: profile?.countryCode?.toUpperCase() ?? 'Auto',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.route,
              label: l.configRouteSegment,
              value: '${profile?.routeSegmentKm.round() ?? 50} km',
              status: _Status.ok,
            ),

            const Divider(height: 24),
            _sectionTitle(theme, l.configApiKeysSection),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.key,
              label: l.configTankerkoenigKey,
              // #521 — never render "Not set (demo mode)": the bundled
              // community key means the app always has a working key.
              // The row now distinguishes user-set (Configurée / green)
              // from the community default (same status — real data,
              // just not the user's own key).
              value: hasCustomApiKey
                  ? (l.configApiKeyConfigured)
                  : (l.configApiKeyCommunity),
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.ev_station,
              label: l.configEvKey,
              value: apiKeys.hasCustomEvApiKey()
                  ? (l.configEvKeyCustom)
                  : (l.configEvKeyShared),
              status: _Status.ok,
            ),

            const Divider(height: 24),
            _sectionTitle(theme, l.configCloudSyncSection),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.cloud,
              label: 'TankSync',
              value: syncConfig.isConfigured
                  ? (l.configTankSyncConnected)
                  : (l.configTankSyncDisabled),
              status: syncConfig.isConfigured ? _Status.ok : _Status.neutral,
            ),
            if (syncConfig.isConfigured) ...[
              _ConfigRow(
                icon: Icons.security,
                label: l.configAuthMode,
                value: isEmail ? (l.configAuthEmail) : (l.configAuthAnonymous),
                status: isEmail ? _Status.ok : _Status.warning,
              ),
              _ConfigRow(
                icon: Icons.dns,
                label: l.configDatabase,
                value: syncConfig.supabaseUrl ?? '\u2014',
                status: _Status.ok,
                // A Supabase URL is long enough to wrap "Database" onto two
                // lines and clip the host in the inline layout, so stack the
                // value under the label rather than crowding it on the right.
                stacked: true,
              ),
            ],

            const Divider(height: 24),
            _buildPrivacySummary(context, theme, syncConfig, isEmail),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPrivacySummary(
    BuildContext context,
    ThemeData theme,
    dynamic syncConfig,
    bool isEmail,
  ) {
    final l = AppLocalizations.of(context);
    final authNote = isEmail
        ? (l.configAuthNoteEmail)
        : (l.configAuthNoteAnonymous);
    final summaryBody = syncConfig.isConfigured as bool
        ? (l.configPrivacySummarySynced(authNote))
        : (l.configPrivacySummaryLocal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l.configPrivacySummary,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summaryBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

enum _Status { ok, warning, neutral }

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _Status status;

  /// When true the value is rendered on its own line BELOW the label
  /// instead of inline on the right. Used for long values (e.g. a
  /// Supabase URL) that would otherwise wrap the label to two lines and
  /// clip in the inline layout (#2490).
  final bool stacked;

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
    this.status = _Status.neutral,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (status) {
      _Status.ok => DarkModeColors.success(context),
      _Status.warning => DarkModeColors.warning(context),
      _Status.neutral => theme.colorScheme.onSurfaceVariant,
    };
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: statusColor,
    );

    if (stacked) {
      // Label-over-value: a long value (URL) gets the full row width on
      // its own line and ellipsises rather than wrapping the label.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: statusColor),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                value,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 8),
          // Constrain the value so a long one ellipsises instead of
          // pushing the label into a two-line clip (#2490).
          Flexible(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
