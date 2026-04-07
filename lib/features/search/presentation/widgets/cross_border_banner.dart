import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/cross_border_comparison.dart';
import '../../providers/cross_border_provider.dart';

/// Shows a banner when the user is near a country border,
/// highlighting that prices may differ across the border.
///
/// Displayed above the search results list. Shows the neighboring
/// country flag, name, distance to border, and current average price
/// for context.
class CrossBorderBanner extends ConsumerWidget {
  const CrossBorderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisons = ref.watch(crossBorderComparisonsProvider);
    if (comparisons.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: comparisons
          .map((c) => _CrossBorderCard(comparison: c))
          .toList(),
    );
  }
}

class _CrossBorderCard extends StatelessWidget {
  final CrossBorderComparison comparison;

  const _CrossBorderCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Country flag
              Text(
                comparison.neighborFlag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              // Info text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.crossBorderNearby(comparison.neighborName) ??
                          '${comparison.neighborName} is nearby',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.crossBorderDistance(
                            comparison.borderDistanceKm.round(),
                          ) ??
                          '~${comparison.borderDistanceKm.round()} km to border',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.crossBorderAvgPrice(
                            comparison.currentAvgPrice.toStringAsFixed(3),
                            comparison.stationCount,
                          ) ??
                          'Avg here: ${comparison.currentAvgPrice.toStringAsFixed(3)} EUR (${comparison.stationCount} stations)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Border indicator icon
              Icon(
                Icons.compare_arrows,
                color: colorScheme.tertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
