// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import 'storage_bar.dart';

class StorageSection extends ConsumerWidget {
  const StorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageMgmt = ref.watch(storageManagementProvider);
    final stats = storageMgmt.storageStats;
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
                  '${l?.profile ?? "Profile"} (${storageMgmt.profileCount})',
                  stats.profiles,
                  theme.colorScheme.secondary,
                ),
                StorageSegment(
                  '${l?.favorites ?? "Favorites"} (${storageMgmt.favoriteCount})',
                  stats.favorites,
                  theme.colorScheme.tertiary,
                ),
                StorageSegment(
                  // i18n-ignore: "Cache" is a brand-neutral technical term.
                  'Cache (${storageMgmt.cacheEntryCount} ${l?.entries ?? "entries"})',
                  stats.cache,
                  // #2490 — cache is benign data, not data-loss. It maps to
                  // a NEUTRAL categorical tone rather than error-red (which
                  // dominated ~96% of the bar and read as an alarm). Error
                  // red is reserved for the Delete-all action below.
                  theme.colorScheme.surfaceContainerHighest,
                ),
                StorageSegment(
                  '${l?.priceHistory ?? "Price History"} '
                  '(${storageMgmt.priceHistoryEntryCount})',
                  stats.priceHistory,
                  // #2490 — neutral categorical tone, not warning-orange.
                  theme.colorScheme.secondaryContainer,
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
              label: l?.profile ?? 'Profile',
              detail:
                  '${storageMgmt.profileCount} ${l?.profilesStored ?? 'profiles'}',
              bytes: stats.profiles,
              color: theme.colorScheme.secondary,
            ),
            StorageDetailRow(
              label: l?.favorites ?? 'Favorites',
              detail:
                  '${storageMgmt.favoriteCount} ${l?.stationsMarked ?? 'stations'}',
              bytes: stats.favorites,
              color: theme.colorScheme.tertiary,
            ),
            StorageDetailRow(
              // i18n-ignore: "Cache" is a brand-neutral technical term
              // commonly left untranslated across European locales.
              label: 'Cache',
              detail:
                  '${storageMgmt.cacheEntryCount} ${l?.cachedResponses ?? 'cached'}',
              bytes: stats.cache,
              // #2490 — neutral categorical tone (matches the bar segment),
              // not error-red; cache is benign data, not data-loss.
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            StorageDetailRow(
              label: l?.priceHistory ?? 'Price History',
              detail: l?.priceHistoryStationsTracked(
                      storageMgmt.priceHistoryEntryCount) ??
                  '${storageMgmt.priceHistoryEntryCount} stations tracked',
              bytes: stats.priceHistory,
              // #2490 — neutral categorical tone, not warning-orange.
              color: theme.colorScheme.secondaryContainer,
            ),
            StorageDetailRow(
              label: l?.priceAlerts ?? 'Alerts',
              detail: l?.alertsConfiguredCount(storageMgmt.alertCount) ??
                  '${storageMgmt.alertCount} configured',
              bytes: stats.alerts,
              // #2490 — neutral categorical tone, not warning-orange.
              color: theme.colorScheme.tertiaryContainer,
            ),
            StorageDetailRow(
              label: l?.ignoredStationsLabel ?? 'Ignored',
              detail: l?.ignoredStationsHidden(
                      storageMgmt.getIgnoredIds().length) ??
                  '${storageMgmt.getIgnoredIds().length} stations hidden',
              bytes: storageMgmt.getIgnoredIds().length * 64,
              // #2490 — theme outline token instead of a hard-coded grey.
              color: theme.colorScheme.outlineVariant,
            ),
            StorageDetailRow(
              label: l?.ratingsLabel ?? 'Ratings',
              detail: l?.ratingsStationsRated(
                      storageMgmt.getRatings().length) ??
                  '${storageMgmt.getRatings().length} stations rated',
              bytes: storageMgmt.getRatings().length * 64,
              // #2490 — neutral categorical tone instead of hard-coded amber.
              color: theme.colorScheme.tertiary,
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
                    onPressed: storageMgmt.cacheEntryCount > 0
                        ? () => _clearCache(context, ref)
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(
                      storageMgmt.cacheEntryCount > 0
                          ? '${l?.clearCacheButton ?? "Clear cache"} (${storageMgmt.cacheEntryCount} ${l?.entries ?? "entries"})'
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
                    onPressed: () => _clearAllData(context, ref),
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

  Future<void> _clearCache(BuildContext ctx, WidgetRef ref) async {
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
      // Also wipe Flutter's in-memory ImageCache so map tiles are
      // refetched on the next Carte visit (#711).
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ref.invalidate(storageManagementProvider);
      if (ctx.mounted) {
        SnackBarHelper.show(
            ctx, AppLocalizations.of(ctx)?.cacheCleared ?? 'Cache cleared.');
      }
    }
  }

  Future<void> _clearAllData(BuildContext ctx, WidgetRef ref) async {
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
      final storageMgmt = ref.read(storageManagementProvider);
      await storageMgmt.clearCache();
      await storageMgmt.clearPriceHistory();
      await storageMgmt.deleteApiKey();
      // Drop in-memory tile images too so the rebuilt app sees a
      // blank slate for the map layer (#711).
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      for (final boxName in ['settings', 'favorites', 'profiles']) {
        final box = Hive.box(boxName);
        await box.clear();
      }
      ref.invalidate(storageManagementProvider);
      if (ctx.mounted) {
        ctx.go('/setup');
      }
    }
  }
}
