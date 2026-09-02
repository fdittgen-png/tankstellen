// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/search_result_item.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/brand_filter_provider.dart';
import '../../../providers/mixed_results_filter_provider.dart';
import '../../../providers/search_screen_ui_provider.dart';
import '../header_icon_button.dart';
import '../radar_search_fab.dart';
import '../sort_selector.dart';
import 'results_action_menu.dart';

/// **Row B** of the two-row results chrome (#3926, epic #3925).
///
/// Collapses four stacked strips — the count row with its three unlabelled
/// icon buttons and amber pill, the clipped sort-chip scroller and the
/// "All brands ⌄" filter header — into one band:
///
///  * the result count;
///  * the Fuel Station Radar as a compact chip (it was an extended FAB
///    floating over the third card, fighting the shell's docked search FAB);
///  * the filter button, badged with the number of active filters;
///  * the compact/all-prices view toggle;
///  * the "⋯" menu holding the map / radar-scope / calculator actions;
///  * the sort chips, which now **wrap** instead of scrolling, so no chip is
///    ever cut mid-glyph at the right edge.
class SearchResultsRow extends ConsumerWidget {
  const SearchResultsRow({
    super.key,
    required this.items,
    this.onRadarToggle,
    this.showSortAndFilter = true,
  });

  /// The unfiltered result set — drives the count and the calculator
  /// pre-fill.
  final List<SearchResultItem> items;

  /// #3366 — non-null while the radar scope view can be shown.
  final VoidCallback? onRadarToggle;

  /// #3372 — the landscape radar list drops sort + filters for vertical
  /// room; the count, radar chip, view toggle and overflow stay.
  final bool showSortAndFilter;

  /// Number of filters currently narrowing the list — brands, the
  /// no-motorway toggle, and the EV connector / minimum-power filters.
  int _activeFilterCount(WidgetRef ref) {
    final brands = ref.watch(selectedBrandsProvider).length;
    final excludeHighway = ref.watch(excludeHighwayStationsProvider) ? 1 : 0;
    final connectors = ref.watch(evConnectorFilterProvider).length;
    final minPower = ref.watch(evMinPowerFilterProvider) > 0 ? 1 : 0;
    return brands + excludeHighway + connectors + minPower;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final allPrices = ref.watch(allPricesViewEnabledProvider);
    final viewToggleLabel = allPrices
        ? l10n.switchToCompactView
        : l10n.switchToAllPricesView;
    final activeFilters = showSortAndFilter ? _activeFilterCount(ref) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.stationsFound(items.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const RadarSearchChip(),
              if (showSortAndFilter)
                HeaderIconButton(
                  key: const Key('results_filter_button'),
                  icon: Icons.filter_list,
                  semanticsLabel: activeFilters > 0
                      ? l10n.searchResultsFilterActiveSemantic(activeFilters)
                      : l10n.searchResultsFilterTooltip,
                  tooltip: l10n.searchResultsFilterTooltip,
                  badgeCount: activeFilters,
                  onTap: () =>
                      ref.read(brandFiltersExpandedProvider.notifier).toggle(),
                ),
              HeaderIconButton(
                key: const Key('results_view_toggle'),
                icon: allPrices ? Icons.view_list : Icons.view_agenda,
                semanticsLabel: viewToggleLabel,
                onTap: () =>
                    ref.read(allPricesViewEnabledProvider.notifier).toggle(),
              ),
              ResultsActionMenu(items: items, onRadarToggle: onRadarToggle),
            ],
          ),
          if (showSortAndFilter)
            SortSelector(
              selected: ref.watch(selectedSortModeProvider),
              onChanged: (mode) =>
                  ref.read(selectedSortModeProvider.notifier).set(mode),
            ),
        ],
      ),
    );
  }
}
