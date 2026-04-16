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
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/presentation/widgets/swipe_tutorial_banner.dart';
import '../../../favorites/providers/favorites_provider.dart';
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
import 'sort_selector.dart';
import 'swipeable_station_card.dart';

/// Station list with sort controls, refresh, count bar, and search location header.
///
/// Accepts a unified [List<SearchResultItem>] that may contain both
/// [FuelStationResult] and [EVStationResult]. Fuel-specific features
/// (price sorting, brand filtering, cheapest flags) apply only to fuel items.
class SearchResultsList extends ConsumerWidget {
  final ServiceResult<List<SearchResultItem>> result;
  final VoidCallback onRefresh;

  const SearchResultsList({
    super.key,
    required this.result,
    required this.onRefresh,
  });

  /// Extracts fuel stations from the unified results list.
  List<Station> _fuelStations(List<SearchResultItem> items) =>
      items.whereType<FuelStationResult>().map((r) => r.station).toList();

  /// Computes which station has the cheapest price for each fuel type.
  Map<String, Map<FuelType, bool>> _computeCheapestFlags(List<Station> stations) {
    if (stations.isEmpty) return {};

    final cheapest = <FuelType, double>{};
    final cheapestIds = <FuelType, String>{};

    const fuelTypes = [
      FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.e85, FuelType.lpg, FuelType.cng,
    ];

    for (final ft in fuelTypes) {
      for (final s in stations) {
        final price = s.priceFor(ft);
        if (price != null && price > 0) {
          if (!cheapest.containsKey(ft) || price < cheapest[ft]!) {
            cheapest[ft] = price;
            cheapestIds[ft] = s.id;
          }
        }
      }
    }

    final result = <String, Map<FuelType, bool>>{};
    for (final entry in cheapestIds.entries) {
      result.putIfAbsent(entry.value, () => {});
      result[entry.value]![entry.key] = true;
    }
    return result;
  }

  /// Get min/max price range for tier classification.
  static (double, double) _getPriceRange(List<Station> stations, FuelType fuel) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = s.priceFor(fuel);
      if (p != null && p > 0) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    if (minP == double.infinity) return (0.0, 0.0);
    return (minP, maxP);
  }

  List<SearchResultItem> _sortItems(
      List<SearchResultItem> items, SortMode sortMode, WidgetRef ref) {
    final sorted = List<SearchResultItem>.from(items);
    final fuelType = ref.read(selectedFuelTypeProvider);

    // EV items always sort by distance — no price data to sort on.
    if (sorted.every((item) => item is EVStationResult)) {
      sorted.sort((a, b) => a.dist.compareTo(b.dist));
      return sorted;
    }

    switch (sortMode) {
      case SortMode.distance:
        sorted.sort((a, b) => a.dist.compareTo(b.dist));
      case SortMode.price:
        sorted.sort((a, b) {
          final sa = a is FuelStationResult ? a.station : null;
          final sb = b is FuelStationResult ? b.station : null;
          if (sa != null && sb != null) return compareByPrice(sa, sb, fuelType);
          return a.dist.compareTo(b.dist);
        });
      case SortMode.name:
        sorted.sort((a, b) {
          final sa = a is FuelStationResult ? a.station : null;
          final sb = b is FuelStationResult ? b.station : null;
          if (sa != null && sb != null) return compareByName(sa, sb);
          return a.displayName.compareTo(b.displayName);
        });
      case SortMode.open24h:
        sorted.sort((a, b) {
          final sa = a is FuelStationResult ? a.station : null;
          final sb = b is FuelStationResult ? b.station : null;
          if (sa != null && sb != null) return compareByOpen24h(sa, sb);
          return a.dist.compareTo(b.dist);
        });
      case SortMode.rating:
        final ratings = ref.read(stationRatingsProvider);
        sorted.sort((a, b) {
          final sa = a is FuelStationResult ? a.station : null;
          final sb = b is FuelStationResult ? b.station : null;
          if (sa != null && sb != null) return compareByRating(sa, sb, ratings);
          return a.dist.compareTo(b.dist);
        });
      case SortMode.priceDistance:
        sorted.sort((a, b) {
          final sa = a is FuelStationResult ? a.station : null;
          final sb = b is FuelStationResult ? b.station : null;
          if (sa != null && sb != null) return compareByPriceDistance(sa, sb, fuelType);
          return a.dist.compareTo(b.dist);
        });
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          stations: _fuelStations(result.data)
              .where((s) => !ignoredIds.contains(s.id))
              .toList(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: Builder(builder: (context) {
              // Filter out ignored stations
              final afterIgnored = result.data
                  .where((s) => !ignoredIds.contains(s.id))
                  .toList();

              // Apply fuel-specific filters to fuel items; EV items pass through.
              final selectedBrands = ref.watch(selectedBrandsProvider);
              final excludeHighway = ref.watch(excludeHighwayStationsProvider);
              final requiredAmenities = ref.watch(selectedAmenitiesProvider);
              final openOnly = ref.watch(openOnlyFilterProvider);

              // Split into fuel + EV, filter fuel items, then recombine.
              final fuelItems = afterIgnored.whereType<FuelStationResult>().toList();
              final evItems = afterIgnored.whereType<EVStationResult>().toList();
              final fuelFiltered = applyAmenityAndStatusFilters(
                applyBrandFilter(
                  fuelItems.map((r) => r.station).toList(),
                  selectedBrands: selectedBrands,
                  excludeHighway: excludeHighway,
                ),
                requiredAmenities: requiredAmenities,
                openOnly: openOnly,
              );
              final filteredFuelIds = fuelFiltered.map((s) => s.id).toSet();
              final filtered = <SearchResultItem>[
                ...fuelItems.where((r) => filteredFuelIds.contains(r.station.id)),
                ...evItems,
              ];

              final sorted = _sortItems(filtered, sortMode, ref);
              final fuelOnly = _fuelStations(sorted);
              final allPrices = ref.watch(allPricesViewEnabledProvider);
              final cheapestMap = allPrices
                  ? _computeCheapestFlags(fuelOnly)
                  : <String, Map<FuelType, bool>>{};

              // Compute price range for tier icons (a11y)
              final fuelType = ref.watch(selectedFuelTypeProvider);
              final priceRange = _getPriceRange(fuelOnly, fuelType);
              final profileFuel = ref.watch(activeProfileProvider)?.preferredFuelType;

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final item = sorted[index];
                  final isFav = ref.watch(isFavoriteProvider(item.id));

                  return switch (item) {
                    FuelStationResult(:final station) => _buildFuelCard(
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
                      onTap: () => context.push('/ev-station', extra: item.station),
                    ),
                  };
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

/// Collapsible section that wraps [BrandFilterChips] inside an expandable
/// toggle. When collapsed, only a "Brands" label with a chevron is shown.
class _CollapsibleBrandFilters extends ConsumerWidget {
  final List<Station> stations;

  const _CollapsibleBrandFilters({required this.stations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(brandFiltersExpandedProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedBrands = ref.watch(selectedBrandsProvider);
    final excludeHighway = ref.watch(excludeHighwayStationsProvider);
    final hasActiveFilters =
        selectedBrands.isNotEmpty || excludeHighway;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () =>
              ref.read(brandFiltersExpandedProvider.notifier).toggle(),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n?.brandFilterAll ?? 'Brands',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: BrandFilterChips(stations: stations),
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Toggle button to switch between compact card view and all-prices detail view.
class _ViewToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPrices = ref.watch(allPricesViewEnabledProvider);
    final l10n = AppLocalizations.of(context);

    final label = allPrices
        ? (l10n?.switchToCompactView ?? 'Switch to compact view')
        : (l10n?.switchToAllPricesView ?? 'Switch to all-prices view');

    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: () => ref
              .read(allPricesViewEnabledProvider.notifier)
              .toggle(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(
              allPrices ? Icons.view_list : Icons.view_agenda,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
