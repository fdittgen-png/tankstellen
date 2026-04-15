import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/sync_provider.dart';
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
            _sectionTitle(theme, l?.configProfileSection ?? 'Profile'),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.person,
              label: l?.configActiveProfile ?? 'Active profile',
              value: profile?.name ?? (l?.configNone ?? 'None'),
              status: profile != null ? _Status.ok : _Status.warning,
            ),
            _ConfigRow(
              icon: Icons.local_gas_station,
              label: l?.configPreferredFuel ?? 'Preferred fuel',
              value: profile?.preferredFuelType.displayName ?? '\u2014',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.language,
              label: l?.configCountry ?? 'Country',
              value: profile?.countryCode?.toUpperCase() ?? 'Auto',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.route,
              label: l?.configRouteSegment ?? 'Route segment',
              value: '${profile?.routeSegmentKm.round() ?? 50} km',
              status: _Status.ok,
            ),

            const Divider(height: 24),
            _sectionTitle(theme, l?.configApiKeysSection ?? 'API keys'),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.key,
              label: l?.configTankerkoenigKey ?? 'Tankerkoenig API key',
              // #521 — never render "Not set (demo mode)": the bundled
              // community key means the app always has a working key.
              // The row now distinguishes user-set (Configurée / green)
              // from the community default (same status — real data,
              // just not the user's own key).
              value: hasCustomApiKey
                  ? (l?.configApiKeyConfigured ?? 'Configured')
                  : (l?.configApiKeyCommunity ?? 'Default (community key)'),
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.ev_station,
              label: l?.configEvKey ?? 'EV charging API key',
              value: apiKeys.hasCustomEvApiKey()
                  ? (l?.configEvKeyCustom ?? 'Custom key')
                  : (l?.configEvKeyShared ?? 'Default (shared)'),
              status: _Status.ok,
            ),

            const Divider(height: 24),
            _sectionTitle(theme, l?.configCloudSyncSection ?? 'Cloud Sync'),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.cloud,
              label: 'TankSync',
              value: syncConfig.isConfigured
                  ? (l?.configTankSyncConnected ?? 'Connected')
                  : (l?.configTankSyncDisabled ?? 'Disabled'),
              status:
                  syncConfig.isConfigured ? _Status.ok : _Status.neutral,
            ),
            if (syncConfig.isConfigured) ...[
              _ConfigRow(
                icon: Icons.security,
                label: l?.configAuthMode ?? 'Auth mode',
                value: isEmail
                    ? (l?.configAuthEmail ?? 'Email (persistent)')
                    : (l?.configAuthAnonymous ?? 'Anonymous (device-only)'),
                status: isEmail ? _Status.ok : _Status.warning,
              ),
              _ConfigRow(
                icon: Icons.dns,
                label: l?.configDatabase ?? 'Database',
                value: syncConfig.supabaseUrl ?? '\u2014',
                status: _Status.ok,
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
    return Text(title,
        style: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildPrivacySummary(
    BuildContext context,
    ThemeData theme,
    dynamic syncConfig,
    bool isEmail,
  ) {
    final l = AppLocalizations.of(context);
    final authNote = isEmail
        ? (l?.configAuthNoteEmail ??
            'Email account enables cross-device access')
        : (l?.configAuthNoteAnonymous ??
            'Anonymous account — data tied to this device');
    final summaryBody = syncConfig.isConfigured
        ? (l?.configPrivacySummarySynced(authNote) ??
            '• Favorites, alerts, and ignored stations are synced to your '
                'private database\n'
                '• GPS position and API keys never leave your device\n'
                '• $authNote')
        : (l?.configPrivacySummaryLocal ??
            '• All data is stored locally on this device only\n'
                '• No data is sent to any server\n'
                '• API keys encrypted in device secure storage');

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
                l?.configPrivacySummary ?? 'Privacy summary',
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

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
    this.status = _Status.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (status) {
      _Status.ok => Colors.green,
      _Status.warning => Colors.orange,
      _Status.neutral => theme.colorScheme.onSurfaceVariant,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
