import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_provider.dart';

/// Card showing the trip cost result for the calculator.
///
/// Reads from [CalculatorState] directly so the parent screen doesn't need to
/// pipe individual numbers through the widget tree.
class CalculatorResultCard extends StatelessWidget {
  final CalculatorState state;

  const CalculatorResultCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.tripCost ?? 'Trip Cost',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultItem(
                  label: l10n?.fuelNeeded ?? 'Fuel needed',
                  value: UnitFormatter.formatVolume(
                      state.calculation.totalLiters),
                ),
                _ResultItem(
                  // Trip totals are shown at cent precision, not the
                  // 3-decimal fuel-price precision, so we don't route
                  // through formatPrice here — only the currency
                  // symbol is localised.
                  label: l10n?.totalCost ?? 'Total cost',
                  value:
                      '${state.calculation.totalCost.toStringAsFixed(2)} ${PriceFormatter.currency}',
                  highlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _ResultItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: highlight
              ? theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
