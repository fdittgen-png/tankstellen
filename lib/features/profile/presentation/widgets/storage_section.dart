import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../l10n/app_localizations.dart';
import 'storage_bar.dart';

class StorageSection extends ConsumerStatefulWidget {
  const StorageSection({super.key});

  @override
  ConsumerState<StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<StorageSection> {
  @override
  Widget build(BuildContext context) {
    final storage = ref.read(hiveStorageProvider);
    final stats = storage.storageStats;
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.storageUsage ?? 'Storage',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StorageBar(
              segments: [
                StorageSegment(
                  l?.settingsLabel ?? 'Settings',
                  stats.settings,
                  theme.colorScheme.primary,
                ),
                StorageSegment(
                  '${l?.profile ?? "Profile"} (${storage.profileCount})',
                  stats.profiles,
                  theme.colorScheme.secondary,
                ),
                StorageSegment(
                  '${l?.favorites ?? "Favorites"} (${storage.favoriteCount})',
                  stats.favorites,
                  theme.colorScheme.tertiary,
                ),
                StorageSegment(
                  'Cache (${storage.cacheEntryCount} ${l?.entries ?? "entries"})',
                  stats.cache,
                  theme.colorScheme.error.withValues(alpha: 0.7),
                ),
                StorageSegment(
                  'Price History (${storage.priceHistoryEntryCount})',
                  stats.priceHistory,
                  Colors.orange.withValues(alpha: 0.7),
                ),
              ],
              totalBytes: stats.total,
              theme: theme,
            ),
            const SizedBox(height: 16),
            StorageDetailRow(
              label: l?.settingsLabel ?? 'Settings',
              detail: l?.settingsStorageDetail ?? 'API key, active profile',
              bytes: stats.settings,
              color: theme.colorScheme.primary,
            ),
            StorageDetailRow(
              label: 'Profile',
              detail:
                  '${storage.profileCount} ${l?.profilesStored ?? 'profiles'}',
              bytes: stats.profiles,
              color: theme.colorScheme.secondary,
            ),
            StorageDetailRow(
              label: l?.favorites ?? 'Favorites',
              detail:
                  '${storage.favoriteCount} ${l?.stationsMarked ?? 'stations'}',
              bytes: stats.favorites,
              color: theme.colorScheme.tertiary,
            ),
            StorageDetailRow(
              label: 'Cache',
              detail:
                  '${storage.cacheEntryCount} ${l?.cachedResponses ?? 'cached'}',
              bytes: stats.cache,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
            ),
            StorageDetailRow(
              label: 'Price History',
              detail:
                  '${storage.priceHistoryEntryCount} stations tracked',
              bytes: stats.priceHistory,
              color: Colors.orange.withValues(alpha: 0.7),
            ),
            StorageDetailRow(
              label: l?.priceAlerts ?? 'Alerts',
              detail: '${storage.alertCount} configured',
              bytes: stats.alerts,
              color: Colors.amber.withValues(alpha: 0.7),
            ),
            StorageDetailRow(
              label: 'Ignored',
              detail: '${storage.getIgnoredIds().length} stations hidden',
              bytes: storage.getIgnoredIds().length * 64,
              color: Colors.grey,
            ),
            StorageDetailRow(
              label: 'Ratings',
              detail: '${storage.getRatings().length} stations rated',
              bytes: storage.getRatings().length * 64,
              color: Colors.amber,
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l?.total ?? 'Total',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(stats.total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l?.cacheManagement ?? 'Cache management',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l?.cacheDescription ??
                  'The cache stores API responses for faster loading and offline access.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            CacheTtlInfo(theme: theme),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: storage.cacheEntryCount > 0
                        ? () => _clearCache(context)
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(
                      storage.cacheEntryCount > 0
                          ? '${l?.clearCacheButton ?? "Clear cache"} (${storage.cacheEntryCount} ${l?.entries ?? "entries"})'
                          : l?.cacheEmpty ?? 'Cache is empty',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearAllData(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: Text(l?.deleteAllButton ?? 'Delete all'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)?.clearCacheTitle ?? 'Clear cache?'),
        content: Text(
          AppLocalizations.of(context)?.clearCacheBody ??
              'Cached data will be deleted. Settings preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.clearCacheButton ??
                'Clear cache'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cache = ref.read(cacheManagerProvider);
      await cache.clearAll();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared.')),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(AppLocalizations.of(context)?.deleteAllTitle ??
            'Delete all data?'),
        content: Text(
          AppLocalizations.of(context)?.deleteAllBody ??
              'Permanently deletes all data. App will reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)?.deleteAllButton ??
                'Delete all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = ref.read(hiveStorageProvider);
      await storage.clearCache();
      await storage.clearPriceHistory();
      await storage.deleteApiKey();
      for (final boxName in ['settings', 'favorites', 'profiles']) {
        final box = Hive.box(boxName);
        await box.clear();
      }
      if (mounted) {
        context.go('/setup');
      }
    }
  }
}
