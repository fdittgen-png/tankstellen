import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../providers/profile_provider.dart';

/// Configuration and privacy verification card.
///
/// Displays a summary of active profile settings, API keys, cloud sync
/// status, and data privacy information so the user can audit what is
/// stored and where.
class ConfigVerificationWidget extends ConsumerWidget {
  const ConfigVerificationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storage = ref.read(hiveStorageProvider);
    final syncConfig = ref.watch(syncStateProvider);
    final profile = ref.watch(activeProfileProvider);
    final hasApiKey = storage.hasApiKey();
    final isEmail = syncConfig.hasEmail;
    final favCount = storage.getFavoriteIds().length;
    final alertCount = storage.alertCount;
    final ignoredCount = storage.getIgnoredIds().length;
    final ratingsCount = storage.getRatings().length;
    final ratingMode = profile?.ratingMode ?? 'local';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(theme, 'Profile'),
            const SizedBox(height: 8),
            _ConfigRow(icon: Icons.person, label: 'Active profile',
                value: profile?.name ?? 'None',
                status: profile != null ? _Status.ok : _Status.warning),
            _ConfigRow(icon: Icons.local_gas_station, label: 'Preferred fuel',
                value: profile?.preferredFuelType.displayName ?? '\u2014',
                status: _Status.ok),
            _ConfigRow(icon: Icons.language, label: 'Country',
                value: profile?.countryCode?.toUpperCase() ?? 'Auto',
                status: _Status.ok),
            _ConfigRow(icon: Icons.route, label: 'Route segment',
                value: '${profile?.routeSegmentKm.round() ?? 50} km',
                status: _Status.ok),

            const Divider(height: 24),
            _sectionTitle(theme, 'API Keys'),
            const SizedBox(height: 8),
            _ConfigRow(icon: Icons.key, label: 'Tankerkoenig API key',
                value: hasApiKey ? 'Configured' : 'Not set (demo mode)',
                status: hasApiKey ? _Status.ok : _Status.warning),
            _ConfigRow(icon: Icons.ev_station, label: 'EV charging API key',
                value: storage.hasCustomEvApiKey() ? 'Custom key' : 'Default (shared)',
                status: _Status.ok),

            const Divider(height: 24),
            _sectionTitle(theme, 'Cloud Sync'),
            const SizedBox(height: 8),
            _ConfigRow(icon: Icons.cloud, label: 'TankSync',
                value: syncConfig.isConfigured ? 'Connected' : 'Disabled',
                status: syncConfig.isConfigured ? _Status.ok : _Status.neutral),
            if (syncConfig.isConfigured) ...[
              _ConfigRow(icon: Icons.security, label: 'Auth mode',
                  value: isEmail ? 'Email (persistent)' : 'Anonymous (device-only)',
                  status: isEmail ? _Status.ok : _Status.warning),
              _ConfigRow(icon: Icons.dns, label: 'Database',
                  value: syncConfig.supabaseUrl ?? '\u2014',
                  status: _Status.ok),
            ],

            const Divider(height: 24),
            _sectionTitle(theme, 'Data & Privacy'),
            const SizedBox(height: 8),
            _ConfigRow(icon: Icons.star, label: 'Favorites',
                value: '$favCount stations',
                privacy: syncConfig.isConfigured ? 'Synced' : 'Local only'),
            _ConfigRow(icon: Icons.notifications, label: 'Alerts',
                value: '$alertCount configured',
                privacy: syncConfig.isConfigured ? 'Synced' : 'Local only'),
            _ConfigRow(icon: Icons.visibility_off, label: 'Ignored stations',
                value: '$ignoredCount hidden',
                privacy: syncConfig.isConfigured ? 'Synced' : 'Local only'),
            _ConfigRow(icon: Icons.star_rate, label: 'Ratings',
                value: '$ratingsCount rated',
                privacy: ratingMode == 'local'
                    ? 'Local only'
                    : ratingMode == 'private'
                        ? 'Private (synced)'
                        : 'Shared (public)'),
            _ConfigRow(icon: Icons.location_on, label: 'GPS position',
                value: storage.getSetting('user_position_lat') != null ? 'Stored' : 'Not stored',
                privacy: 'Local only (never synced)'),
            _ConfigRow(icon: Icons.key, label: 'API keys',
                value: hasApiKey ? 'Stored' : 'Not set',
                privacy: 'Encrypted (Keystore/Keychain)'),

            const Divider(height: 24),
            _buildPrivacySummary(theme, syncConfig, ratingMode, isEmail),
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
    ThemeData theme,
    dynamic syncConfig,
    String ratingMode,
    bool isEmail,
  ) {
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
              Text('Privacy summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            syncConfig.isConfigured
                ? '\u2022 Favorites, alerts, and ignored stations are synced to your private database\n'
                  '\u2022 Ratings are ${ratingMode == 'shared' ? 'shared with all users' : ratingMode == 'private' ? 'synced privately' : 'stored locally only'}\n'
                  '\u2022 GPS position and API keys never leave your device\n'
                  '\u2022 ${isEmail ? 'Email account enables cross-device access' : 'Anonymous account \u2014 data tied to this device'}'
                : '\u2022 All data is stored locally on this device only\n'
                  '\u2022 No data is sent to any server\n'
                  '\u2022 GPS position stored locally for search convenience\n'
                  '\u2022 API keys encrypted in device secure storage',
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
  final String? privacy;

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
    this.status = _Status.neutral,
    this.privacy,
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
          if (privacy != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(privacy!,
                  style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 6),
          ],
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
