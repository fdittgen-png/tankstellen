// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/calculator_provider.dart';

/// Result hero for the calculator — leads with the answer (#2543).
///
/// A [SectionCard] titled "Trip Cost" with a big primary-colour total
/// and a 3–4-up breakdown of compact tiles. Before all three inputs are
/// entered ([CalculatorState.hasInput] false) it renders the **same**
/// card with `--` placeholders and a one-line helper, so the screen
/// never shows an empty void waiting on input.
class CalculatorResultCard extends StatelessWidget {
  final CalculatorState state;

  const CalculatorResultCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final calc = state.calculation;
    final filled = state.hasInput;
    final roundTrip = state.roundTrip;

    // The hero total honours the round-trip flag; `--` until ready.
    final totalText = filled
        ? PriceFormatter.formatTotal(calc.effectiveCost(roundTrip: roundTrip))
        : _placeholder;

    final tiles = <Widget>[
      _BreakdownTile(
        label: l10n?.fuelNeeded ?? 'Fuel needed',
        value: filled
            ? UnitFormatter.formatVolume(
                calc.effectiveLiters(roundTrip: roundTrip))
            : _placeholder,
      ),
      _BreakdownTile(
        label: l10n?.costPerDistance ?? 'Cost per km',
        value: filled
            ? '${PriceFormatter.formatPerKm(calc.costPerKm)} $_perKmSuffix'
            : _placeholder,
      ),
    ];

    if (roundTrip) {
      tiles.add(_BreakdownTile(
        label: l10n?.roundTripTotal ?? 'Round trip',
        value: filled
            ? PriceFormatter.formatTotal(calc.roundTripCost)
            : _placeholder,
      ));
    }

    final monthly = calc.monthlyCost(
      roundTrip: roundTrip,
      tripsPerMonth: state.tripsPerMonth,
    );
    if (state.tripsPerMonth != null && state.tripsPerMonth! > 0) {
      tiles.add(_BreakdownTile(
        label: l10n?.costPerMonth ?? 'Cost per month',
        value: filled ? PriceFormatter.formatTotal(monthly) : _placeholder,
      ));
    }

    return SectionCard(
      title: l10n?.tripCost ?? 'Trip Cost',
      leadingIcon: Icons.calculate_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            totalText,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!filled) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l10n?.calculatorResultPlaceholder ??
                  'Fill in distance, consumption and price to see your '
                      'trip cost',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.xl),
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: Spacing.xl,
            runSpacing: Spacing.md,
            children: tiles,
          ),
        ],
      ),
    );
  }

  /// Cost-per-distance unit mask, e.g. `€/km` or `£/mi`. Currency from
  /// [PriceFormatter], distance unit from the active country config so
  /// it never hard-codes km. Language-neutral format mask.
  static String get _perKmSuffix {
    final unit = PriceFormatter.activeConfig.distanceUnit;
    return '${PriceFormatter.currency}/$unit';
  }

  static const String _placeholder = '--';
}

class _BreakdownTile extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
