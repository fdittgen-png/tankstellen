// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/cache/cache_manager.dart';
import '../../../../../core/storage/storage_providers.dart';
import '../../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/snackbar_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../storage_bar.dart';

/// "Cache details" — a collapsed [ExpansionTile] under the device-data
/// inventory (#3910, Epic #3907) holding what the former storage section
/// showed inline: the cache explanation, the lifetime (TTL) table and the
/// clear-cache button. Collapsed by default: the cache is benign data
/// most visitors never need to touch.
class CacheDetailsTile extends ConsumerWidget {
  const CacheDetailsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cacheCount = ref
        .watch(deviceDataInventoryProvider)
        .byKind(DeviceDataKind.cache)
        .count ??
        0;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: const Key('privacyCacheDetailsTile'),
        leading: const Icon(Icons.cached, size: 20),
        title: Text(l.privacyCacheDetails),
        subtitle: Text(l.privacyCacheResponses(cacheCount),
            style: theme.textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.cacheDescription, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          CacheTtlInfo(theme: theme),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('privacyClearCacheButton'),
              onPressed:
                  cacheCount > 0 ? () => _clearCache(context, ref) : null,
              icon: const Icon(Icons.delete_sweep),
              label: Text(cacheCount > 0
                  ? l.privacyClearCacheEntries(cacheCount)
                  : l.cacheEmpty),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // #3682 — the ONE shared destructive-action dialog.
    final confirmed = await confirmDestructiveAction(
      context,
      title: l.clearCacheTitle,
      message: l.clearCacheBody,
      confirmLabel: l.clearCacheButton,
    );
    // #3159 — the dialog await above means the tile can be gone here;
    // ref.read / ref.invalidate on a dead WidgetRef throw under Riverpod 3.
    if (!confirmed || !context.mounted) return;
    final cache = ref.read(cacheManagerProvider);
    await cache.clearAll();
    // Also wipe Flutter's in-memory ImageCache so map tiles are refetched
    // on the next map visit (#711).
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!context.mounted) return;
    ref.invalidate(storageManagementProvider);
    ref.invalidate(deviceDataInventoryProvider);
    SnackBarHelper.show(context, AppLocalizations.of(context).cacheCleared);
  }
}
