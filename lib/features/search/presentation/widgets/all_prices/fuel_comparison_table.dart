// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/consumption_unit.dart';
import '../../../../../core/theme/dark_mode_colors.dart';
import '../../../../../core/theme/fuel_colors.dart';
import '../../../../../core/utils/price_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/all_prices_comparison_model.dart';
import 'fuel_comparison_cell.dart';

/// One station's row of the all-prices comparison table (#3933).
///
/// A fixed-width `Row` of equal columns — NOT a `Wrap`. That is the whole
/// point: the chips this replaced re-flowed per card, so E10 sat in a
/// different place on every row and no column could be scanned. Here the
/// column set is decided list-wide (`allPricesColumnsProvider`) and each
/// card renders exactly those columns, blank where the station has no
/// price.
///
/// Below the row: the per-station verdict — which fuel actually costs
/// least per 100 km HERE — plus the "cheapest of the results" marker when
/// that fuel's price also wins the whole result set. Both vanish when the
/// user has no vehicle or no consumption history, leaving a clean price
/// table with deltas.
class FuelComparisonTable extends StatefulWidget {
  final StationFuelComparison comparison;
  final ConsumptionUnit consumptionUnit;

  const FuelComparisonTable({
    super.key,
    required this.comparison,
    this.consumptionUnit = ConsumptionUnit.lPer100Km,
  });

  @override
  State<FuelComparisonTable> createState() => _FuelComparisonTableState();
}

class _FuelComparisonTableState extends State<FuelComparisonTable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final comparison = widget.comparison;
    final overflow = comparison.overflowCells;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IntrinsicHeight so every cell in the row paints to the same
        // height — a blank column must look like a column, not a gap.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final cell in comparison.cells) ...[
                Expanded(
                  child: FuelComparisonCell(
                    key: ValueKey('all-prices-cell-${cell.fuel.apiValue}'),
                    data: cell,
                    consumptionUnit: widget.consumptionUnit,
                  ),
                ),
                const SizedBox(width: 3),
              ],
              if (overflow.isNotEmpty)
                _ExpanderButton(
                  count: overflow.length,
                  expanded: _expanded,
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),
        ),
        if (overflow.isNotEmpty && _expanded) ...[
          const SizedBox(height: 3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cell in overflow) ...[
                  Expanded(
                    child: FuelComparisonCell(
                      key: ValueKey('all-prices-extra-${cell.fuel.apiValue}'),
                      data: cell,
                      consumptionUnit: widget.consumptionUnit,
                    ),
                  ),
                  const SizedBox(width: 3),
                ],
                // Keep the overflow row on the same column pitch as the
                // main grid so the expanded cells still line up under it.
                for (var i = overflow.length; i < comparison.cells.length; i++)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
        if (comparison.hasVerdict) ...[
          const SizedBox(height: 5),
          _VerdictLine(comparison: comparison, l10n: l10n),
        ],
      ],
    );
  }
}

/// The "＋n" per-card expander that reveals the fuels which did not fit
/// the 320 dp column budget. Sized to a column so the grid pitch holds.
class _ExpanderButton extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onPressed;

  const _ExpanderButton({
    required this.count,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        tooltip: expanded
            ? l10n.allPricesFewerFuelsTooltip
            : l10n.allPricesMoreFuelsTooltip(count),
        icon: expanded
            ? Icon(Icons.expand_less, color: theme.colorScheme.primary)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.allPricesMoreFuels(count),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

/// « E85 — 5,02 €/100 km here », plus the outright-winner marker.
class _VerdictLine extends StatelessWidget {
  final StationFuelComparison comparison;
  final AppLocalizations l10n;

  const _VerdictLine({required this.comparison, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fuel = comparison.verdictFuel!;
    final color = FuelColors.forType(fuel);
    final cell = <FuelCellData>[
      ...comparison.cells,
      ...comparison.overflowCells,
    ].firstWhere((c) => c.fuel == fuel);

    return Row(
      children: [
        Icon(Icons.emoji_events_outlined, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            l10n.allPricesVerdictHere(
              cell.label,
              l10n.allPricesCostPer100km(
                PriceFormatter.formatTotal(comparison.verdictCostPer100km),
              ),
            ),
            maxLines: 2,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (comparison.winsResults) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.allPricesVerdictWinsResults,
              maxLines: 2,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: DarkModeColors.success(context),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
