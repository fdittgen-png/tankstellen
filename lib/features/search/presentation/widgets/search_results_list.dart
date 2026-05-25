// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/responsive_search_layout.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/services/widgets/freshness_badge.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/presentation/widgets/swipe_tutorial_banner.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_result_item.dart';
import '../../domain/entities/station.dart';
import '../../providers/selected_station_provider.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/brand_filter_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import '../../providers/station_rating_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import 'all_prices_station_card.dart';
import 'brand_filter_chips.dart';
import 'cross_border_banner.dart';
import 'ev_station_card.dart';
import 'mixed_results_filter_chips.dart';
import 'sort_selector.dart';
import 'swipeable_station_card.dart';

part 'search_results_list_parts.dart';

/// Station list with sort controls, refresh, count bar, and search location header.
///
/// Accepts a unified [List<SearchResultItem>] that may contain both
/// [FuelStationResult] and [EVStationResult]. Fuel-specific features
/// (price sorting, brand filtering, cheapest flags) apply only to fuel items.
class SearchResultsList extends ConsumerStatefulWidget {
  final ServiceResult<List<SearchResultItem>> result;
  final VoidCallback onRefresh;

  const SearchResultsList({
    super.key,
    required this.result,
    required this.onRefresh,
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
    )..forward();
  }

  @override
  void didUpdateWidget(SearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh search → replay the staggered cascade from the top.
    if (!identical(oldWidget.result, widget.result)) {
      _fadeController.forward(from: 0);
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
    final l10n = AppLocalizations.of(context);
    final ignoredIds = ref.watch(ignoredStationsProvider);
    final sortMode = ref.watch(selectedSortModeProvider);

    return Column(
      children: [
        ServiceStatusBanner(result: result),
        // Compact header: location + count + sort in minimal space
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Builder(builder: (ctx) {
                  final location = ref.watch(searchLocationProvider);
                  return Text(
                    location.isNotEmpty
                        ? '$location · ${result.data.length}'
                        : l10n?.stationsFound(result.data.length) ??
                            '${result.data.length} stations',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ),
              _ViewToggleButton(),
              const SizedBox(width: 4),
              Semantics(
                label: 'Show stations on map',
                button: true,
                child: InkWell(
                  onTap: () => context.go('/map'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Icon(Icons.map, size: 18,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // #1613 — gated entry point for the fuel-cost Calculator.
              // The /calculator route exists but had no navigation entry
              // point anywhere in lib/; this affordance makes it
              // reachable when Feature.fuelCalculator is enabled.
              if (ref
                  .watch(enabledFeaturesProvider)
                  .contains(Feature.fuelCalculator)) ...[
                Semantics(
                  label: l10n?.fuelCostCalculator ?? 'Fuel Cost Calculator',
                  button: true,
                  child: InkWell(
                    onTap: () => context.go('/calculator'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Icon(Icons.calculate,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              FreshnessBadge(result: result),
            ],
          ),
        ),
        const CrossBorderBanner(),
        // #494 — same swipe-hint banner as the favorites screen. Shows
        // once until the user taps "Got it", then stays dismissed.
        const SwipeTutorialBanner(),
        SortSelector(
          selected: sortMode,
          onChanged: (mode) =>
              ref.read(selectedSortModeProvider.notifier).set(mode),
        ),
        _CollapsibleBrandFilters(
          stations: _fuelStationsFrom(result.data)
              .where((s) => !ignoredIds.contains(s.id))
              .toList(),
        ),
        // #1784 — Fuel/EV/Both kind selector + EV connector & power
        // filters. Renders nothing for a fuel-only result set.
        const MixedResultsFilterChips(),
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

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
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
                                onTap: () => context.push('/ev-station',
                                    extra: item.station),
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
            context.push('/station/${station.id}');
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

    return SwipeableStationCard(
      key: ValueKey('station-${station.id}'),
      station: station,
      isFavorite: isFavorite,
      priceTier: tier,
      rating: stationRating,
      profileFuelType: profileFuel,
      onNavigate: () => NavigationUtils.openInMaps(
        station.lat, station.lng,
        label: station.displayName,
      ),
      onIgnore: () {
        ref.read(ignoredStationsProvider.notifier).add(station.id);
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showWithUndo(
          context,
          l10n?.stationHidden(station.displayName) ?? '${station.displayName} hidden',
          undoLabel: l10n?.undo ?? 'Undo',
          onUndo: () => ref
              .read(ignoredStationsProvider.notifier)
              .remove(station.id),
        );
      },
      onTap: () {
        if (isWideScreen(context)) {
          ref.read(selectedStationProvider.notifier).select(station.id);
        } else {
          context.push('/station/${station.id}');
        }
      },
      onFavoriteTap: () => ref
          .read(favoritesProvider.notifier)
          .toggle(station.id, stationData: station),
    );
  }
}
