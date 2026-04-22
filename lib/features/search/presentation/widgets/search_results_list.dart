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
import '../../../../core/widgets/staggered_fade_in.dart';
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

part 'search_results_list_parts.dart';

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
          stations: _fuelStationsFrom(result.data)
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

              final sorted = _sortSearchResults(filtered, sortMode, ref);
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
                  final isFav = ref.watch(isFavoriteProvider(item.id));

                  final card = switch (item) {
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
                  // #595 — cap stagger so a 50-result search finishes
                  // fading in well under a second. Index key keeps the
                  // animation bound to the slot, so rebuilds (refresh,
                  // filter changes) don't re-trigger it.
                  return StaggeredFadeIn(
                    key: ValueKey('stagger-${item.id}'),
                    index: index,
                    child: card,
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
