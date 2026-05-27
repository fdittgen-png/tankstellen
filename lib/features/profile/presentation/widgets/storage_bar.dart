// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Format byte count to human-readable string.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ── Helper widgets for StorageSection ──

class StorageSegment {
  final String label;
  final int bytes;
  final Color color;
  const StorageSegment(this.label, this.bytes, this.color);
}

class StorageBar extends StatelessWidget {
  final List<StorageSegment> segments;
  final int totalBytes;
  final ThemeData theme;

  const StorageBar({
    super.key,
    required this.segments,
    required this.totalBytes,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (totalBytes == 0) {
      final l10n = AppLocalizations.of(context);
      return Container(
        height: 24,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(l10n?.noStorageUsed ?? 'No storage used',
              style: const TextStyle(fontSize: 11)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 24,
            child: Row(
              children: segments.map((seg) {
                final fraction = seg.bytes / totalBytes;
                if (fraction < 0.01) return const SizedBox.shrink();
                return Expanded(
                  flex: (fraction * 1000).round(),
                  child: Container(color: seg.color),
                );
              }).toList(),
            ),
          ),
        ),
        // #2116 — legend ties each bar segment to its detail row's dot,
        // so the colours stop being arbitrary "what's the orange one
        // again?" guesses. Only segments with a measurable share
        // (≥ 1 % of total) make it into the legend — the same
        // threshold the bar uses to render its slice.
        const SizedBox(height: 6),
        Wrap(
          key: const Key('storage_bar_legend'),
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final seg in segments)
              if (totalBytes > 0 && seg.bytes / totalBytes >= 0.01)
                _LegendSwatch(label: seg.label, color: seg.color),
          ],
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendSwatch({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class StorageDetailRow extends StatelessWidget {
  final String label;
  final String detail;
  final int bytes;
  final Color color;

  const StorageDetailRow({
    super.key,
    required this.label,
    required this.detail,
    required this.bytes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatBytes(bytes),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CacheTtlInfo extends StatelessWidget {
  final ThemeData theme;
  const CacheTtlInfo({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // #2116 — groups give the dense six-row list a visual hierarchy.
    // Three buckets that mirror the call paths: Network = remote API
    // round-trips, Data = client-side derived caches, Geocoding =
    // postal-code → coordinates lookups.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ttlGroupHeader(l?.cacheTtlGroupNetwork ?? 'Network'),
        _ttlRow(l?.stationSearch ?? 'Station search', l?.minutes(5) ?? '5 min'),
        _ttlRow(l?.stationDetails ?? 'Station details',
            l?.minutes(15) ?? '15 min'),
        _ttlRow(l?.priceQuery ?? 'Price query', l?.minutes(5) ?? '5 min'),
        const SizedBox(height: 4),
        _ttlGroupHeader(l?.cacheTtlGroupData ?? 'Data'),
        _ttlRow(l?.favoritesDataCache ?? 'Favorites data',
            l?.minutes(30) ?? '30 min'),
        _ttlRow(l?.citySearchCache ?? 'City search',
            l?.minutes(30) ?? '30 min'),
        const SizedBox(height: 4),
        _ttlGroupHeader(l?.cacheTtlGroupGeocoding ?? 'Geocoding'),
        _ttlRow(l?.zipGeocoding ?? 'ZIP geocoding', l?.hours(24) ?? '24 h'),
      ],
    );
  }

  Widget _ttlGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2, left: 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _ttlRow(String label, String ttl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.timer,
              size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            ttl,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
