import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../data/repositories/price_history_repository.dart';

/// Displays aggregate price statistics (min, max, avg, current) with
/// a trend indicator arrow.
class PriceStatsCard extends StatelessWidget {
  final PriceStats stats;
  final String currencySymbol;

  const PriceStatsCard({
    super.key,
    required this.stats,
    this.currencySymbol = '\u20ac',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.current == null && stats.min == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No statistics available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Min',
            value: _formatPrice(stats.min),
            color: DarkModeColors.success(context),
          ),
          _StatItem(
            label: 'Max',
            value: _formatPrice(stats.max),
            color: DarkModeColors.error(context),
          ),
          _StatItem(
            label: 'Avg',
            value: _formatPrice(stats.avg),
            color: theme.colorScheme.onSurface,
          ),
          _CurrentWithTrend(
            value: _formatPrice(stats.current),
            trend: stats.trend,
          ),
        ],
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '--';
    return '${price.toStringAsFixed(3)} $currencySymbol';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CurrentWithTrend extends StatelessWidget {
  final String value;
  final PriceTrend trend;

  const _CurrentWithTrend({required this.value, required this.trend});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (trend) {
      PriceTrend.up => (Icons.trending_up, DarkModeColors.error(context)),
      PriceTrend.down => (Icons.trending_down, DarkModeColors.success(context)),
      PriceTrend.stable => (Icons.trending_flat, Theme.of(context).colorScheme.onSurfaceVariant),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Current',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 18, color: color),
          ],
        ),
      ],
    );
  }
}
