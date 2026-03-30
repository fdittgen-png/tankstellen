import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../sync/presentation/widgets/qr_share_widget.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/profile_repository.dart';
import '../../providers/profile_provider.dart';
import '../widgets/about_section.dart';
import '../widgets/api_key_section.dart';
import '../widgets/data_transparency_section.dart';
import '../widgets/profile_list_section.dart';
import '../widgets/storage_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.settings ?? 'Settings'),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Profiles
          const _SectionHeader(icon: Icons.person, title: 'Profile'),
          const SizedBox(height: 8),
          const ProfileListSection(),
          const SizedBox(height: 32),

          // Location
          const _SectionHeader(
              icon: Icons.my_location, title: 'Location'),
          const SizedBox(height: 8),
          _buildLocationSection(theme, activeProfile, l),
          const SizedBox(height: 32),

          // TankSync — foldable
          _FoldableSection(
            icon: Icons.cloud_outlined,
            title: 'TankSync',
            initiallyExpanded: true,
            child: _buildTankSyncSection(context, ref),
          ),
          const SizedBox(height: 8),

          // API Key — foldable
          _FoldableSection(
            icon: Icons.key,
            title: l?.apiKeySetup ?? 'API Key',
            child: const ApiKeySection(),
          ),
          const SizedBox(height: 8),

          // Data Transparency — foldable
          _FoldableSection(
            icon: Icons.visibility,
            title: l?.dataTransparency ?? 'Data transparency',
            child: const DataTransparencySection(),
          ),
          const SizedBox(height: 8),

          // Storage & Cache — foldable
          _FoldableSection(
            icon: Icons.storage,
            title: l?.storageAndCache ?? 'Storage & cache',
            child: const StorageSection(),
          ),
          const SizedBox(height: 32),

          // About
          _SectionHeader(
              icon: Icons.info_outline, title: l?.about ?? 'About'),
          const SizedBox(height: 8),
          const AboutSection(),
          const SizedBox(height: 32),

          // Configuration Verification
          const _SectionHeader(
            icon: Icons.verified_user,
            title: 'Configuration & Privacy',
          ),
          const SizedBox(height: 8),
          _buildConfigVerification(context, ref),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildTankSyncSection(BuildContext context, WidgetRef ref) {
    final syncConfig = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (syncConfig.isConfigured) ...[
              // ── Mode + connection status ──
              ListTile(
                leading: const Icon(Icons.cloud_done, color: Colors.green),
                title: Text(syncConfig.modeName),
                subtitle: Text(
                  syncConfig.hasEmail
                      ? syncConfig.userEmail!
                      : 'Anonymous · ${syncConfig.userId?.substring(0, 8) ?? ""}...',
                ),
              ),

              // ── Auth actions ──
              if (!syncConfig.hasEmail)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Upgrade to email'),
                  subtitle: const Text('Keep data, add sign-in from other devices'),
                  onTap: () => context.push('/auth'),
                ),

              const Divider(indent: 16, endIndent: 16),

              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View my data'),
                onTap: () => context.push('/data-transparency'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Link device'),
                onTap: () => context.push('/link-device'),
              ),
              if (syncConfig.mode != SyncMode.community)
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Share database'),
                  onTap: () => _showQrShare(context, ref),
                ),

              const Divider(indent: 16, endIndent: 16),

              // ── Danger zone ──
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Disconnect'),
                subtitle: const Text('Stop syncing (local data kept)'),
                onTap: () => _confirmDisconnect(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                title: Text('Delete account', style: TextStyle(color: theme.colorScheme.error)),
                subtitle: const Text('Remove all server data permanently'),
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ] else ...[
              // ── Not connected ──
              const ListTile(
                leading: Icon(Icons.cloud_off),
                title: Text('Local only'),
                subtitle: Text('Optional: sync favorites, alerts, and ratings across devices'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilledButton.icon(
                  onPressed: () => context.push('/sync-setup'),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Set up cloud sync'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigVerification(BuildContext context, WidgetRef ref) {
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
            // ── Profile Settings ──
            Text('Profile', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.person,
              label: 'Active profile',
              value: profile?.name ?? 'None',
              status: profile != null ? _Status.ok : _Status.warning,
            ),
            _ConfigRow(
              icon: Icons.local_gas_station,
              label: 'Preferred fuel',
              value: profile?.preferredFuelType.displayName ?? '—',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.language,
              label: 'Country',
              value: profile?.countryCode?.toUpperCase() ?? 'Auto',
              status: _Status.ok,
            ),
            _ConfigRow(
              icon: Icons.route,
              label: 'Route segment',
              value: '${profile?.routeSegmentKm.round() ?? 50} km',
              status: _Status.ok,
            ),

            const Divider(height: 24),

            // ── API Keys ──
            Text('API Keys', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.key,
              label: 'Tankerkoenig API key',
              value: hasApiKey ? 'Configured' : 'Not set (demo mode)',
              status: hasApiKey ? _Status.ok : _Status.warning,
            ),
            _ConfigRow(
              icon: Icons.ev_station,
              label: 'EV charging API key',
              value: storage.hasCustomEvApiKey() ? 'Custom key' : 'Default (shared)',
              status: _Status.ok,
            ),

            const Divider(height: 24),

            // ── Cloud Sync ──
            Text('Cloud Sync', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.cloud,
              label: 'TankSync',
              value: syncConfig.isConfigured ? 'Connected' : 'Disabled',
              status: syncConfig.isConfigured ? _Status.ok : _Status.neutral,
            ),
            if (syncConfig.isConfigured) ...[
              _ConfigRow(
                icon: Icons.security,
                label: 'Auth mode',
                value: isEmail ? 'Email (persistent)' : 'Anonymous (device-only)',
                status: isEmail ? _Status.ok : _Status.warning,
              ),
              _ConfigRow(
                icon: Icons.dns,
                label: 'Database',
                value: syncConfig.supabaseUrl ?? '—',
                status: _Status.ok,
              ),
            ],

            const Divider(height: 24),

            // ── Data & Privacy ──
            Text('Data & Privacy', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ConfigRow(
              icon: Icons.star,
              label: 'Favorites',
              value: '$favCount stations',
              privacy: syncConfig.isConfigured ? 'Synced' : 'Local only',
            ),
            _ConfigRow(
              icon: Icons.notifications,
              label: 'Alerts',
              value: '$alertCount configured',
              privacy: syncConfig.isConfigured ? 'Synced' : 'Local only',
            ),
            _ConfigRow(
              icon: Icons.visibility_off,
              label: 'Ignored stations',
              value: '$ignoredCount hidden',
              privacy: syncConfig.isConfigured ? 'Synced' : 'Local only',
            ),
            _ConfigRow(
              icon: Icons.star_rate,
              label: 'Ratings',
              value: '$ratingsCount rated',
              privacy: ratingMode == 'local'
                  ? 'Local only'
                  : ratingMode == 'private'
                      ? 'Private (synced)'
                      : 'Shared (public)',
            ),
            _ConfigRow(
              icon: Icons.location_on,
              label: 'GPS position',
              value: storage.getSetting('user_position_lat') != null ? 'Stored' : 'Not stored',
              privacy: 'Local only (never synced)',
            ),
            _ConfigRow(
              icon: Icons.key,
              label: 'API keys',
              value: hasApiKey ? 'Stored' : 'Not set',
              privacy: 'Encrypted (Keystore/Keychain)',
            ),

            const Divider(height: 24),

            // ── Summary ──
            Container(
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
                      Text('Privacy summary', style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    syncConfig.isConfigured
                        ? '• Favorites, alerts, and ignored stations are synced to your private database\n'
                          '• Ratings are ${ratingMode == 'shared' ? 'shared with all users' : ratingMode == 'private' ? 'synced privately' : 'stored locally only'}\n'
                          '• GPS position and API keys never leave your device\n'
                          '• ${isEmail ? 'Email account enables cross-device access' : 'Anonymous account — data tied to this device'}'
                        : '• All data is stored locally on this device only\n'
                          '• No data is sent to any server\n'
                          '• GPS position stored locally for search convenience\n'
                          '• API keys encrypted in device secure storage',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error),
        title: const Text('Disconnect TankSync?'),
        content: const Text(
          'Cloud sync will be disabled. Your local data (favorites, alerts, history) '
          'is preserved on this device. Server data is not deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(syncStateProvider.notifier).disconnect();
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Theme.of(ctx).colorScheme.error, size: 48),
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes all your data from the server '
          '(favorites, alerts, ratings, routes). '
          'Local data on this device is preserved.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(syncStateProvider.notifier).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted. Local data preserved.')),
        );
      }
    }
  }

  void _showQrShare(BuildContext context, WidgetRef ref) {
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
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection(
      ThemeData theme, dynamic activeProfile, AppLocalizations? l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              final userPos = ref.watch(userPositionProvider);
              if (userPos != null) {
                final diff = DateTime.now().difference(userPos.updatedAt);
                final age = diff.inMinutes < 60
                    ? '${diff.inMinutes} min'
                    : diff.inHours < 24
                        ? '${diff.inHours} h'
                        : '${diff.inDays} d';
                return Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${userPos.source} ($age)',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l?.delete ?? 'Clear GPS position'),
                            content: const Text(
                              'Clear the stored GPS position? '
                              'You can update it again at any time.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l?.cancel ?? 'Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l?.delete ?? 'Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref.read(userPositionProvider.notifier).clear();
                        }
                      },
                      tooltip: l?.delete ?? 'Clear',
                    ),
                  ],
                );
              }
              // GPS not configured — show tappable row to acquire
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      try {
                        await ref
                            .read(userPositionProvider.notifier)
                            .updateFromGps();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('GPS error: $e'),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.my_location,
                              size: 16,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to update GPS position',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GPS position is acquired automatically when you search. '
                    'You can also update it manually here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l?.autoUpdatePosition ?? 'Auto-update position',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                l?.autoUpdateDescription ??
                    'Refresh GPS position before each search',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: activeProfile?.autoUpdatePosition ?? false,
              onChanged: (value) {
                if (activeProfile != null) {
                  final updated =
                      activeProfile.copyWith(autoUpdatePosition: value);
                  ref.read(profileRepositoryProvider).updateProfile(updated);
                  ref.invalidate(allProfilesProvider);
                  ref.invalidate(activeProfileProvider);
                }
              },
            ),
            const Divider(),
            Builder(builder: (context) {
              final storage = ref.read(hiveStorageProvider);
              final autoSwitch = storage
                      .getSetting(StorageKeys.autoSwitchProfile) as bool? ??
                  false;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l?.autoSwitchProfile ?? 'Auto-switch profile',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  l?.autoSwitchDescription ??
                      'Automatically switch profile when crossing borders',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: autoSwitch,
                onChanged: (value) {
                  ref.read(hiveStorageProvider).putSetting(
                        StorageKeys.autoSwitchProfile,
                        value,
                      );
                  setState(() {});
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// A foldable/unfoldable settings section with icon, title, and expandable content.
class _FoldableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _FoldableSection({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [child],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

enum _Status { ok, warning, neutral }

/// A single row in the configuration verification card.
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
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          if (privacy != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(privacy!, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)),
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
