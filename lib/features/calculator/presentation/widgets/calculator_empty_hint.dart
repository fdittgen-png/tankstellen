import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Placeholder shown when the calculator has no input yet.
class CalculatorEmptyHint extends StatelessWidget {
  const CalculatorEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.enterCalcValues ??
                  'Enter distance, consumption, and price to calculate trip cost',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
