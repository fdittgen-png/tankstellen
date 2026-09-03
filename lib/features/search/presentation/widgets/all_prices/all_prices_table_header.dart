// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/country/country_provider.dart';
import '../../../../../core/theme/fuel_colors.dart';
import '../../../../../core/utils/station_extensions.dart';
import '../../../providers/all_prices_table_provider.dart';

/// The sticky column header of the all-prices comparison view (#3933).
///
/// Names the fuels ONCE above the list — the cards below carry the same
/// columns in the same order, so the reader learns the layout here and
/// then scans prices vertically. The fuel codes are DATA, so they stay.
///
/// #3939 (Epic #3937) — the two-line legend that used to sit under this
/// row is gone. "Filled = cheapest of these results. Second figure =
/// what 100 km costs…" is true, worth knowing once, and was costing two
/// permanent lines on the one surface whose job is showing stations. It
/// is now two tips in the search surface's dismissible help bubble
/// (`HelpSurface.searchResults`), where the user meets it once and then
/// never again.
///
/// Mount it directly above the results `ListView` when the all-prices view
/// is on (the results-list file itself is owned by #3926). Renders nothing
/// when no columns resolved, so mounting it unconditionally is safe.
class AllPricesTableHeader extends ConsumerWidget {
  /// Horizontal inset — matches the card shell's 8 dp margin plus the
  /// card body's 12 dp padding so the header codes sit over their
  /// columns.
  static const double horizontalInset = 20;

  /// Width the table reserves for the "＋n" expander; mirrored here so a
  /// header column keeps its pitch when the country overflows the grid.
  static const double expanderWidth = 34;

  const AllPricesTableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(allPricesColumnsProvider);
    if (columns.visible.isEmpty) return const SizedBox.shrink();

    final countryCode = ref.watch(activeCountryProvider).code;

    return Padding(
      padding: const EdgeInsets.fromLTRB(horizontalInset, 4, horizontalInset, 4),
      child: Row(
        children: [
          for (final fuel in columns.visible) ...[
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fuelDisplayLabel(fuel, countryCode: countryCode),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: FuelColors.forType(fuel),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
          ],
          if (columns.overflow.isNotEmpty)
            const SizedBox(width: expanderWidth),
        ],
      ),
    );
  }
}
