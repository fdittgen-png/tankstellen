// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/consumption_unit.dart';
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
/// #3943 — the table is now the whole card. The verdict line that used to
/// sit under it ("🏆 Cheapest here: E85 at 3,91 €/100 km", plus a
/// "cheapest of the results" marker) restated what the cells directly
/// above it already showed: every cell carries its own cost per 100 km,
/// and the cheapest one is filled in its fuel colour. One sentence of
/// chrome per card, on every card, saying nothing new.
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
