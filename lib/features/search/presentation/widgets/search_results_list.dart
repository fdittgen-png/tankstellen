// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/presentation/widgets/swipe_tutorial_banner.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../../../core/domain/station.dart';
import '../../providers/selected_station_provider.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/radar_search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../../providers/station_rating_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import 'all_prices_station_card.dart';
import 'brand_filter_chips.dart';
import 'cross_border_banner.dart';
import 'ev_station_card.dart';
import 'mixed_results_filter_chips.dart';
import 'results/results_row.dart';
import 'swipeable_station_card.dart';
import 'all_prices/all_prices_table_header.dart';

part 'search_results_list_parts.dart';

/// Station list with sort controls, refresh, count bar, and search location header.
///
/// Accepts a unified [List<SearchResultItem>] that may contain both
/// [FuelStationResult] and [EVStationResult]. Fuel-specific features
/// (price sorting, brand filtering, cheapest flags) apply only to fuel items.
class SearchResultsList extends ConsumerStatefulWidget {
  final ServiceResult<List<SearchResultItem>> result;
  final VoidCallback onRefresh;

  /// #3366 — when non-null, a small radar-scope toggle icon appears in the
  /// header next to the list/map icons (the Fuel Station Radar is active and a
  /// usable centre exists). Tapping it switches to the PPI radar-scope view.
  /// Null for an ordinary search (no scope to offer).
  final VoidCallback? onRadarToggle;

  /// #3372 — hide the sort selector + brand/mixed filter rows (the landscape
  /// radar list wants maximum vertical room — just the count/view header + the
  /// station cards). The header row (count + view-mode + radar toggle) stays.
  final bool hideSortAndFilter;

  const SearchResultsList({
    super.key,
    required this.result,
    required this.onRefresh,
    this.onRadarToggle,
    this.hideSortAndFilter = false,
  });

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

/// #1773 — the whole results list shares ONE fade timeline. Every row
/// used to own an `AnimatedOpacity` (its own ticker) plus a one-shot
/// `Timer`; this state hosts the single [AnimationController] the rows
/// slice into via their per-index `Interval`.
class _SearchResultsListState extends ConsumerState<SearchResultsList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: StaggeredFadeIn.timelineDuration,
    );
    unawaited(_fadeController.forward());
  }

  @override
  void didUpdateWidget(SearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh search → replay the staggered cascade from the top.
    if (!identical(oldWidget.result, widget.result)) {
      unawaited(_fadeController.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final onRefresh = widget.onRefresh;
    final ignoredIds = ref.watch(ignoredStationsProvider);

    return Column(
      children: [
        ServiceStatusBanner(result: result),
        // #3926 — ROW B: count, radar chip, badged filter button, view
        // toggle, and the labelled overflow that now holds the map /
        // radar-scope / calculator actions. It replaced the count row with
        // its three bare glyphs and its wordless amber pill, the clipped
        // sort scroller and the "All brands" filter header.
        SearchResultsRow(
          items: result.data,
          onRadarToggle: widget.onRadarToggle,
          showSortAndFilter: !widget.hideSortAndFilter,
        ),
        const CrossBorderBanner(),
        // #494 — same swipe-hint banner as the favorites screen. Shows
        // once until the user taps "Got it", then stays dismissed.
        const SwipeTutorialBanner(),
        // #3939 (Epic #3937) — everything the chrome used to explain in
        // permanent height (the all-prices legend, what the price arrows
        // rank, where the criteria live) lives here instead: a paged,
        // dismissible bubble the user reads once. The landscape radar
        // pane, which trades every non-essential row for vertical room,
        // does not carry it.
        // #3372 — the landscape radar list drops the filter panel for
        // vertical room (row B keeps the count/view/overflow controls).
        // #3926 — the panel no longer carries its own "All brands ⌄"
        // header row: the badged filter button on row B expands it.
        if (!widget.hideSortAndFilter)
          _ExpandableFilters(
            stations: _fuelStationsFrom(result.data)
                .where((s) => !ignoredIds.contains(s.id))
                .toList(),
          ),
        // #3933 — the all-prices table's column header: names each fuel
        // column once above the list so the cells below can stay numeric.
        // Renders nothing outside the all-prices view (and when no column
        // resolves), so the compact list is untouched.
        if (ref.watch(allPricesViewEnabledProvider))
          const AllPricesTableHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: Builder(builder: (context) {
              // #1762 — the ignored/brand/amenity/open filter chain and
              // the sort are memoised in `filteredSortedSearchResults`,
              // keyed on this result set; an unrelated rebuild that
              // passes the same `result.data` reuses the cached list
              // instead of re-running the whole pipeline.
              final sorted =
                  ref.watch(filteredSortedSearchResultsProvider(result.data));
              final fuelOnly = _fuelStationsFrom(sorted);
              final allPrices = ref.watch(allPricesViewEnabledProvider);
              final cheapestMap = allPrices
                  ? _computeCheapestFlagsFor(fuelOnly)
                  : <String, Map<FuelType, bool>>{};

              // Compute price range for tier icons (a11y)
              final fuelType = ref.watch(selectedFuelTypeProvider);
              final priceRange = _getPriceRangeFor(fuelOnly, fuelType);
              final profileFuel = ref.watch(activeProfileProvider)?.preferredFuelType;

              // #3937 — the help bubble is the list's FIRST ITEM, not a
              // band above it: on the screen whose whole point is showing
              // stations, an explanation must scroll away with the first
              // flick instead of holding height until it is dismissed.
              // The landscape radar pane carries no bubble at all.
              final showHelp = !widget.hideSortAndFilter;
              return ListView.builder(
                // #3926 — the extended radar FAB is gone, but the shell's
                // docked search FAB still floats over the list bottom;
                // reserve the shared clearance so the last card is not
                // sitting under it.
                padding: const EdgeInsets.only(bottom: kFabScrollClearance),
                itemCount: sorted.length + (showHelp ? 1 : 0),
                itemBuilder: (context, rawIndex) {
                  if (showHelp && rawIndex == 0) {
                    return const HelpBanner(
                      storageKey: StorageKeys.helpBannerSearchResults,
                      icon: Icons.lightbulb_outline,
                      surface: HelpSurface.searchResults,
                    );
                  }
                  final index = rawIndex - (showHelp ? 1 : 0);
                  final item = sorted[index];
                  // #595 — cap stagger so a 50-result search finishes
                  // fading in well under a second. Index key keeps the
                  // animation bound to the slot, so rebuilds (refresh,
                  // filter changes) don't re-trigger it.
                  return StaggeredFadeIn(
                    key: ValueKey('stagger-${item.id}'),
                    controller: _fadeController,
                    index: index,
                    // #1772 — a RepaintBoundary isolates the card's
                    // raster from the StaggeredFadeIn opacity tween, so
                    // the per-row fade-in (and any in-card animation)
                    // composites a cached layer instead of repainting
                    // the card on every frame.
                    child: RepaintBoundary(
                      // #1771 — the favorite and rating providers are
                      // watched inside this per-row Consumer, not in
                      // the parent build. A favorite toggle or rating
                      // change on one station now rebuilds only that
                      // row — previously it rebuilt the whole list and
                      // re-ran the filter/sort pipeline in the parent.
                      child: Consumer(
                        builder: (context, ref, _) {
                          final isFav =
                              ref.watch(isFavoriteProvider(item.id));
                          return switch (item) {
                            FuelStationResult(:final station) =>
                              _buildFuelCard(
                                context: context,
                                ref: ref,
                                station: station,
                                isFavorite: isFav,
                                allPrices: allPrices,
                                cheapestMap: cheapestMap,
                                fuelType: fuelType,
                                priceRange: priceRange,
                                profileFuel: profileFuel,
                              ),
                            EVStationResult() => EVStationCard(
                                key: ValueKey('ev-${item.id}'),
                                result: item,
                                isFavorite: isFav,
                                onFavoriteTap: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(item.id,
                                        rawJson: item.station.toJson()),
                                onTap: () => EvStationDetailRoute(
                                        item.station)
                                    .push<void>(context),
                              ),
                          };
                        },
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        // #2373/#3926 — the open-data attribution lives in the screen's
        // footer under this list (`SearchResultsFooter`), together with
        // the price-arrow legend.
      ],
    );
  }

  Widget _buildFuelCard({
    required BuildContext context,
    required WidgetRef ref,
    required Station station,
    required bool isFavorite,
    required bool allPrices,
    required Map<String, Map<FuelType, bool>> cheapestMap,
    required FuelType fuelType,
    required (double, double) priceRange,
    required FuelType? profileFuel,
  }) {
    if (allPrices) {
      return AllPricesStationCard(
        key: ValueKey('all-prices-${station.id}'),
        station: station,
        isFavorite: isFavorite,
        cheapestFlags: cheapestMap[station.id] ?? const {},
        profileFuelType: profileFuel,
        onTap: () {
          if (isWideScreen(context)) {
            ref.read(selectedStationProvider.notifier).select(station.id);
          } else {
            unawaited(StationDetailRoute(station.id).push<void>(context));
          }
        },
        onFavoriteTap: () => ref
            .read(favoritesProvider.notifier)
            .toggle(station.id, stationData: station),
      );
    }

    final tier = priceTierOf(
      station.priceFor(fuelType),
      priceRange.$1,
      priceRange.$2,
    );
    final stationRating = ref.watch(stationRatingProvider(station.id));

    // #2995 — when the on-search Fuel Station Radar owns the result list, each
    // card carries the green→accent closeness bar (the SAME [ProximityFillBar]
    // / [RadarCloseness] as the trip card + PiP). The bar scales to the user's
    // APPROACH RADIUS (`profile.approachRadiusKm * 1000`) — the EXACT same base
    // the recording radar card (`trip_radar_card.dart`) and the PiP use, so all
    // three surfaces are consistent on the user's approach-radius base. A 2.5 km
    // forecourt reads `1 - 2.5/3 ≈ 0.17` (matching the recording radar), and a
    // station beyond the approach radius reads ~0 — by design, only stations
    // within reach show a fill. This REVERSES #2984/#2985, which scaled the list
    // to `min(searchRadius, 15 km cap)`; the maintainer decided the recording
    // radar's approach-radius base is correct and the list was wrong. Null off
    // radar mode (or with no active profile) → regular cards.
    final radar = ref.watch(radarSearchProvider);
    final profile = ref.watch(activeProfileProvider);
    final closenessRadiusMeters = (radar.active && profile != null)
        ? profile.approachRadiusKm * 1000.0
        : null;

    return SwipeableStationCard(
      key: ValueKey('station-${station.id}'),
      station: station,
      isFavorite: isFavorite,
      priceTier: tier,
      rating: stationRating,
      profileFuelType: profileFuel,
      closenessRadiusMeters: closenessRadiusMeters,
      onNavigate: () => NavigationUtils.openInMaps(
        station.lat, station.lng,
        label: station.displayName,
      ),
      onIgnore: () {
        // #ref-after-unmount fix — capture the notifier before
        // handing onUndo to the SnackBar. The action can fire after
        // this widget has unmounted (the bar persists across
        // navigation); using `ref.read` from there throws a StateError.
        // The notifier is stable for the provider's lifetime, so the
        // captured reference is safe across that gap.
        final ignoredNotifier =
            ref.read(ignoredStationsProvider.notifier);
        unawaited(ignoredNotifier.add(station.id));
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showWithUndo(
          context,
          l10n.stationHidden(station.displayName),
          undoLabel: l10n.undo,
          onUndo: () => ignoredNotifier.remove(station.id),
        );
      },
      onTap: () {
        if (isWideScreen(context)) {
          ref.read(selectedStationProvider.notifier).select(station.id);
        } else {
          unawaited(StationDetailRoute(station.id).push<void>(context));
        }
      },
      onFavoriteTap: () => ref
          .read(favoritesProvider.notifier)
          .toggle(station.id, stationData: station),
    );
  }
}
