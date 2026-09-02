// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/domain/search_result_item.dart';
import '../../../../../core/domain/station.dart';
import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/utils/price_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/application/feature_flags_provider.dart';
import '../../../../feature_management/domain/feature.dart';
import '../../../providers/search_provider.dart';

/// The three secondary results actions, one labelled entry each (#3926).
enum ResultsAction {
  /// Open the map tab centred on the result set.
  showOnMap,

  /// Swap the list for the PPI radar scope (only offered while the Fuel
  /// Station Radar owns the list and a usable centre exists).
  radarScope,

  /// Open the fuel-cost calculator, pre-filled with the cheapest price.
  fuelCalculator,
}

/// The "⋯" overflow button on the results row (row B, #3926).
///
/// Replaces three unlabelled icon buttons (`Icons.map`, `Icons.radar`,
/// `Icons.calculate`) that sat side by side in the old count row with no
/// text at all. Each action keeps its handler, its accessibility label and
/// its widget key; it simply gains a visible label and a single labelled
/// entry point.
class ResultsActionMenu extends ConsumerWidget {
  const ResultsActionMenu({
    super.key,
    required this.items,
    this.onRadarToggle,
  });

  /// The current (unfiltered) result set — the calculator entry pre-fills
  /// the cheapest price found in it (#2543).
  final List<SearchResultItem> items;

  /// #3366 — non-null only while the radar scope can be shown.
  final VoidCallback? onRadarToggle;

  void _run(BuildContext context, WidgetRef ref, ResultsAction action) {
    switch (action) {
      case ResultsAction.showOnMap:
        context.go(RoutePaths.map);
      case ResultsAction.radarScope:
        onRadarToggle?.call();
      case ResultsAction.fuelCalculator:
        final fuel = ref.read(selectedFuelTypeProvider);
        final stations = <Station>[
          for (final item in items)
            if (item is FuelStationResult) item.station,
        ];
        final (minP, _) = priceRange(stations, fuel, requirePositive: true);
        CalculatorRoute(initialPrice: minP > 0 ? minP : null).go(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // #1613 — the fuel-cost calculator is a gated feature.
    final hasCalculator = ref.watch(
      enabledFeaturesProvider.select((f) => f.contains(Feature.fuelCalculator)),
    );

    return PopupMenuButton<ResultsAction>(
      key: const Key('results_action_menu'),
      tooltip: l10n.searchResultsMoreActionsTooltip,
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      iconSize: 18,
      padding: EdgeInsets.zero,
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (context) => [
        _entry(
          value: ResultsAction.showOnMap,
          icon: Icons.map,
          label: l10n.showOnMapSemanticLabel,
        ),
        // #2682 — the radar LAUNCH affordance is the row's radar chip; this
        // entry only swaps the list for the scope view.
        if (onRadarToggle != null)
          _entry(
            key: const Key('radar_view_toggle'),
            value: ResultsAction.radarScope,
            icon: Icons.radar,
            label: l10n.radarScopeShowScope,
          ),
        if (hasCalculator)
          _entry(
            value: ResultsAction.fuelCalculator,
            icon: Icons.calculate,
            label: l10n.fuelCostCalculator,
          ),
      ],
    );
  }

  PopupMenuItem<ResultsAction> _entry({
    Key? key,
    required ResultsAction value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<ResultsAction>(
      key: key,
      value: value,
      child: Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 12),
            Flexible(
              child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
