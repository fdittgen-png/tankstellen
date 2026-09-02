// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../storage_bar.dart';

/// The ONE inventory of data on this device (#3910, Epic #3907): the
/// storage bar + legend on top, one row per category with its count and
/// size, empty categories greyed at the end, and the total line. Backed
/// by [deviceDataInventoryProvider] alone — the former dashboard card
/// and storage section each computed their own copy of these numbers.
class DeviceDataInventoryList extends ConsumerWidget {
  /// Opens the blocked-users management list (the row is tappable even
  /// when empty, so the user can SEE the list is empty).
  final VoidCallback onBlockedUsersTap;

  const DeviceDataInventoryList({super.key, required this.onBlockedUsersTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final inventory = ref.watch(deviceDataInventoryProvider);
    final rows = inventory.orderedForDisplay;

    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StorageBar(
              segments: [
                for (final c in inventory.categories)
                  StorageSegment(
                    _label(l, c.kind),
                    c.bytes,
                    _color(theme, c.kind),
                  ),
              ],
              totalBytes: inventory.totalBytes,
              theme: theme,
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          for (final c in rows)
            _InventoryRow(
              category: c,
              label: _label(l, c.kind),
              detail: _detail(l, c),
              icon: _icon(c.kind),
              color: _color(theme, c.kind),
              onTap: c.kind == DeviceDataKind.blockedUsers
                  ? onBlockedUsersTap
                  : null,
            ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.total,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatBytes(inventory.totalBytes),
                  key: const Key('deviceDataTotal'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations l, DeviceDataKind kind) =>
      switch (kind) {
        DeviceDataKind.favorites => l.favorites,
        DeviceDataKind.ratings => l.privacyRatings,
        DeviceDataKind.profiles => l.privacyProfiles,
        DeviceDataKind.alerts => l.priceAlerts,
        DeviceDataKind.priceHistory => l.privacyPriceHistory,
        DeviceDataKind.ignoredStations => l.privacyIgnoredStations,
        DeviceDataKind.blockedUsers => l.blockedAuthorsTitle,
        DeviceDataKind.itineraries => l.privacyItineraries,
        // i18n-ignore: "Cache" is a brand-neutral technical term.
        DeviceDataKind.cache => 'Cache',
        DeviceDataKind.settings => l.settingsLabel,
      };

  /// Second line: the size, and for the cache / settings rows what the
  /// bytes are made of.
  static String _detail(AppLocalizations l, DeviceDataCategory c) {
    final size = formatBytes(c.bytes);
    return switch (c.kind) {
      DeviceDataKind.cache =>
        '${l.privacyCacheResponses(c.count ?? 0)} · $size',
      DeviceDataKind.settings => '${l.settingsStorageDetail} · $size',
      _ => size,
    };
  }

  static IconData _icon(DeviceDataKind kind) => switch (kind) {
        DeviceDataKind.favorites => Icons.favorite,
        DeviceDataKind.ratings => Icons.star,
        DeviceDataKind.profiles => Icons.person,
        DeviceDataKind.alerts => Icons.notifications,
        DeviceDataKind.priceHistory => Icons.show_chart,
        DeviceDataKind.ignoredStations => Icons.visibility_off,
        DeviceDataKind.blockedUsers => Icons.block_outlined,
        DeviceDataKind.itineraries => Icons.route,
        DeviceDataKind.cache => Icons.cached,
        DeviceDataKind.settings => Icons.settings,
      };

  // #2490 — neutral categorical tones; the cache (usually ~96% of the
  // bar) is benign data, never error-red.
  static Color _color(ThemeData theme, DeviceDataKind kind) {
    final s = theme.colorScheme;
    return switch (kind) {
      DeviceDataKind.favorites => s.tertiary,
      DeviceDataKind.ratings => s.tertiaryContainer,
      DeviceDataKind.profiles => s.secondary,
      DeviceDataKind.alerts => s.primaryContainer,
      DeviceDataKind.priceHistory => s.secondaryContainer,
      DeviceDataKind.ignoredStations => s.outlineVariant,
      DeviceDataKind.blockedUsers => s.outline,
      DeviceDataKind.itineraries => s.inversePrimary,
      DeviceDataKind.cache => s.surfaceContainerHighest,
      DeviceDataKind.settings => s.primary,
    };
  }
}

class _InventoryRow extends StatelessWidget {
  final DeviceDataCategory category;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InventoryRow({
    required this.category,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = category.isEmpty;
    // Empty categories are greyed (not hidden): the inventory is a
    // transparency surface, so the user sees what is NOT stored too.
    final muted = theme.colorScheme.onSurfaceVariant;
    final fg = empty ? muted.withValues(alpha: 0.6) : null;
    final count = category.count;
    return ListTile(
      key: Key('deviceDataRow_${category.kind.name}'),
      dense: true,
      enabled: !empty || onTap != null,
      textColor: fg,
      iconColor: fg,
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Icon(icon, size: 22),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
      title: Text(label),
      subtitle: Text(detail),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Text(
              '$count',
              key: Key('deviceDataCount_${category.kind.name}'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: fg),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
