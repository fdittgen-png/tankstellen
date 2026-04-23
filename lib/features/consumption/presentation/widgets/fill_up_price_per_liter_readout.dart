import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Read-only "Price per liter" strip rendered below the cost field on
/// the Add-Fill-up form (#751 phase 2).
///
/// Pure derivation: listens to the two `TextEditingController`s
/// (liters + cost), computes `cost / liters` when both are valid, and
/// renders a small tile with the value. When either input is
/// missing/invalid, the tile stays hidden so the form doesn't flash
/// "NaN" or zero values at the user.
///
/// Decorative only — the field below it (price/L is not a form
/// input) — so we hide it from TalkBack via [ExcludeSemantics]; the
/// two real inputs above already announce themselves.
class FillUpPricePerLiterReadout extends StatelessWidget {
  final TextEditingController litersController;
  final TextEditingController costController;

  const FillUpPricePerLiterReadout({
    super.key,
    required this.litersController,
    required this.costController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([litersController, costController]),
      builder: (context, _) {
        final liters =
            double.tryParse(litersController.text.replaceAll(',', '.'));
        final cost =
            double.tryParse(costController.text.replaceAll(',', '.'));
        if (liters == null ||
            liters <= 0 ||
            cost == null ||
            cost <= 0) {
          return const SizedBox.shrink();
        }
        final pricePerLiter = cost / liters;
        // Semantics-exposed node — TalkBack WILL read this (the
        // computed value is useful context), but the label is baked
        // into one string so only a single announcement fires.
        final label = l?.fillUpPricePerLiterLabel ?? 'Price per liter';
        final value = pricePerLiter.toStringAsFixed(3);
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 56),
          child: Semantics(
            container: true,
            label: '$label: $value',
            excludeSemantics: true,
            child: Row(
              children: [
                Icon(
                  Icons.price_change_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '$label: $value',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
