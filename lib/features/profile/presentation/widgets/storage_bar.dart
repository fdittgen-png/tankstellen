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

    return ClipRRect(
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
    return Column(
      children: [
        _ttlRow(l?.stationSearch ?? 'Station search', l?.minutes(5) ?? '5 min'),
        _ttlRow(l?.stationDetails ?? 'Station details', l?.minutes(15) ?? '15 min'),
        _ttlRow(l?.priceQuery ?? 'Price query', l?.minutes(5) ?? '5 min'),
        _ttlRow('Favorites data', '30 min'),
        _ttlRow('City search', '30 min'),
        _ttlRow(l?.zipGeocoding ?? 'ZIP geocoding', l?.hours(24) ?? '24 h'),
      ],
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
