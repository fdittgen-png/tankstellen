import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../search/domain/entities/fuel_type.dart';
import '../../data/models/price_prediction.dart';
import '../../providers/price_prediction_provider.dart';

/// A compact banner that shows the "best time to fill" recommendation.
///
/// Only renders content when prediction data is available (i.e. enough local
/// price history exists). When no prediction is available, renders [SizedBox.shrink].
class BestTimeBanner extends ConsumerWidget {
  final String stationId;
  final FuelType fuelType;

  const BestTimeBanner({
    super.key,
    required this.stationId,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(
      pricePredictionProvider(stationId, fuelType),
    );

    if (prediction == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final savingText = _buildSavingText(prediction);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prediction.recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (savingText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    savingText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _buildSavingText(PricePrediction prediction) {
    final saving = prediction.potentialSaving;
    if (saving == null || saving <= 0) return null;

    // Convert EUR to cents for display.
    final cents = (saving * 100).toStringAsFixed(1);
    return 'Save ~$cents ct/L';
  }
}
