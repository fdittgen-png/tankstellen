import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/export/data_exporter.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/privacy_data_provider.dart';
import '../widgets/storage_bar.dart';

/// GDPR-compliant privacy dashboard showing all locally stored data
/// with options to export as JSON or delete everything.
///
/// Accessible from the profile/settings screen. Designed to give users
/// full transparency about what data the app stores on their device
/// and optionally in the cloud via TankSync.
class PrivacyDashboardScreen extends ConsumerStatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  ConsumerState<PrivacyDashboardScreen> createState() =>
      _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState
    extends ConsumerState<PrivacyDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(privacyDataProvider);
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.privacyDashboardTitle ?? 'Privacy Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy banner
          _PrivacyBanner(theme: theme, l: l),
          const SizedBox(height: 16),

          // Local data section
          _LocalDataCard(snapshot: snapshot, theme: theme, l: l),
          const SizedBox(height: 16),

          // Synced data section
          _SyncedDataCard(snapshot: snapshot, theme: theme, l: l),
          const SizedBox(height: 24),

          // Action buttons
          _ExportButton(onPressed: () => _exportData(context)),
          const SizedBox(height: 12),
          _ExportCsvButton(onPressed: () => _exportDataCsv(context)),
          const SizedBox(height: 12),
          _DeleteAllButton(onPressed: () => _deleteAllData(context)),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext ctx) async {
    final json = ref.read(exportPrivacyDataProvider);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.privacyExportSuccess ?? 'Data exported to clipboard',
    );
  }

  Future<void> _exportDataCsv(BuildContext ctx) async {
    final storage = ref.read(storageRepositoryProvider);
    final exporter = DataExporter(storage);
    final parts = exporter.exportAllAsCsv();
    final buf = StringBuffer();
    parts.forEach((name, csv) {
      buf
        ..writeln('# $name')
        ..writeln(csv);
    });
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.privacyExportCsvSuccess ?? 'CSV data exported to clipboard',
    );
  }

  Future<void> _deleteAllData(BuildContext ctx) async {
    final l = AppLocalizations.of(ctx);
    final theme = Theme.of(ctx);

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 48,
        ),
        title: Text(l?.privacyDeleteTitle ?? 'Delete all data?'),
        content: Text(
          l?.privacyDeleteBody ??
              'This will permanently delete:\n\n'
                  '- All favorites and station data\n'
                  '- All search profiles\n'
                  '- All price alerts\n'
                  '- All price history\n'
                  '- All cached data\n'
                  '- Your API key\n'
                  '- All app settings\n\n'
                  'The app will reset to its initial state. '
                  'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l?.privacyDeleteConfirm ?? 'Delete everything',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final storageMgmt = ref.read(storageManagementProvider);
    await storageMgmt.clearCache();
    await storageMgmt.clearPriceHistory();
    await storageMgmt.deleteApiKey();
    for (final boxName in ['settings', 'favorites', 'profiles']) {
      final box = Hive.box(boxName);
      await box.clear();
    }
    if (mounted) {
      context.go('/setup');
    }
  }
}

// ---------------------------------------------------------------------------
// Section widgets
// ---------------------------------------------------------------------------

class _PrivacyBanner extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations? l;

  const _PrivacyBanner({required this.theme, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: theme.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l?.privacyDashboardBanner ??
                  'Your data belongs to you. Here you can see everything this app stores, export it, or delete it.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalDataCard extends StatelessWidget {
  final PrivacyDataSnapshot snapshot;
  final ThemeData theme;
  final AppLocalizations? l;

  const _LocalDataCard({
    required this.snapshot,
    required this.theme,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l?.privacyLocalData ?? 'Data on this device',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DataRow(
              icon: Icons.favorite,
              label: l?.favorites ?? 'Favorites',
              value: '${snapshot.favoritesCount}',
            ),
            _DataRow(
              icon: Icons.visibility_off,
              label: l?.privacyIgnoredStations ?? 'Ignored stations',
              value: '${snapshot.ignoredCount}',
            ),
            _DataRow(
              icon: Icons.star,
              label: l?.privacyRatings ?? 'Station ratings',
              value: '${snapshot.ratingsCount}',
            ),
            _DataRow(
              icon: Icons.notifications,
              label: l?.priceAlerts ?? 'Price alerts',
              value: '${snapshot.alertsCount}',
            ),
            _DataRow(
              icon: Icons.show_chart,
              label: l?.privacyPriceHistory ?? 'Price history stations',
              value: '${snapshot.priceHistoryStationCount}',
            ),
            _DataRow(
              icon: Icons.person,
              label: l?.privacyProfiles ?? 'Search profiles',
              value: '${snapshot.profileCount}',
            ),
            _DataRow(
              icon: Icons.route,
              label: l?.privacyItineraries ?? 'Saved routes',
              value: '${snapshot.itineraryCount}',
            ),
            _DataRow(
              icon: Icons.cached,
              label: l?.privacyCacheEntries ?? 'Cache entries',
              value: '${snapshot.cacheEntryCount}',
            ),
            _DataRow(
              icon: Icons.key,
              label: l?.privacyApiKey ?? 'API key stored',
              value: snapshot.hasApiKey
                  ? (l?.yes ?? 'Yes')
                  : (l?.no ?? 'No'),
            ),
            _DataRow(
              icon: Icons.ev_station,
              label: l?.privacyEvApiKey ?? 'EV API key stored',
              value: snapshot.hasEvApiKey
                  ? (l?.yes ?? 'Yes')
                  : (l?.no ?? 'No'),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l?.privacyEstimatedSize ?? 'Estimated storage',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(snapshot.estimatedTotalBytes),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncedDataCard extends StatelessWidget {
  final PrivacyDataSnapshot snapshot;
  final ThemeData theme;
  final AppLocalizations? l;

  const _SyncedDataCard({
    required this.snapshot,
    required this.theme,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  l?.privacySyncedData ?? 'Cloud sync (TankSync)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!snapshot.syncEnabled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 20,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l?.privacySyncDisabled ??
                            'Cloud sync is disabled. All data stays on this device only.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _DataRow(
                icon: Icons.sync,
                label: l?.privacySyncMode ?? 'Sync mode',
                value: snapshot.syncMode ?? '-',
              ),
              _DataRow(
                icon: Icons.perm_identity,
                label: l?.privacySyncUserId ?? 'User ID',
                value: snapshot.syncUserId != null
                    ? '${snapshot.syncUserId!.substring(0, 8)}...'
                    : '-',
              ),
              const SizedBox(height: 8),
              Text(
                l?.privacySyncDescription ??
                    'When sync is enabled, favorites, alerts, ignored stations, and ratings are also stored on the TankSync server.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/data-transparency'),
                icon: const Icon(Icons.visibility, size: 18),
                label: Text(l?.privacyViewServerData ?? 'View server data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExportButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download),
        label: Text(l?.privacyExportButton ?? 'Export all data as JSON'),
      ),
    );
  }
}

class _ExportCsvButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExportCsvButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.table_chart),
        label: Text(l?.privacyExportCsvButton ?? 'Export all data as CSV'),
      ),
    );
  }
}

class _DeleteAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteAllButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
        ),
        icon: const Icon(Icons.delete_forever),
        label: Text(l?.privacyDeleteButton ?? 'Delete all data'),
      ),
    );
  }
}
