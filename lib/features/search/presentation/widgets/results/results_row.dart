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

/// **Row B** of the results chrome — now a single band (#3943, #3926).
///
/// #3926 collapsed four stacked strips (the count row with its three
/// unlabelled icon buttons and amber pill, the clipped sort scroller and
/// the "All brands ⌄" filter header) into a count line plus a sort line.
/// #3943 collapses those two into one:
///
///  * the sort chips — distance, price, rating — moved up here, icon-only;
///  * the result count is gone (the list already says how many there are,
///    and the count was the segment that kept truncating), which is
///    exactly the width the chips needed;
///  * the Fuel Station Radar chip, the badged filter button, the
///    compact/all-prices view toggle and the "⋮" overflow are unchanged;
///  * `A-Z`, `24h` and `Price/km` are still real sort modes — they are
///    labelled entries in the overflow menu now, not deleted.
///
/// ## Overflow safety at 320 dp / 1.3x
/// Every trailing control is a fixed-width glyph. The sort group is the
/// only elastic part, so it goes in an [Expanded]: it gets exactly the
/// room the controls leave, and scrolls inside it if a future locale or
/// accessibility setting ever makes three chips wider than that. The row
/// itself therefore cannot be pushed past its own width.
class SearchResultsRow extends ConsumerWidget {
  const SearchResultsRow({
    super.key,
    required this.items,
    this.onRadarToggle,
    this.showSortAndFilter = true,
  });

  /// The unfiltered result set — drives the calculator pre-fill.
  final List<SearchResultItem> items;

  /// #3366 — non-null while the radar scope view can be shown.
  final VoidCallback? onRadarToggle;

  /// #3372 — the landscape radar list drops sort + filters for vertical
  /// room; the radar chip, view toggle and overflow stay.
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
    final allPrices = ref.watch(allPricesViewEnabledProvider);
    final viewToggleLabel = allPrices
        ? l10n.switchToCompactView
        : l10n.switchToAllPricesView;
    final activeFilters = showSortAndFilter ? _activeFilterCount(ref) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // The one flexible slot on the row. Empty in the landscape radar
          // pane, where it simply pushes the controls to the trailing edge.
          Expanded(
            child: showSortAndFilter
                ? SortSelector(
                    selected: ref.watch(selectedSortModeProvider),
                    onChanged: (mode) =>
                        ref.read(selectedSortModeProvider.notifier).set(mode),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
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
    );
  }
}
