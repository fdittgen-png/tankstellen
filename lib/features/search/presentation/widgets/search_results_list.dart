import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/search_screen_ui_provider.dart';
import 'all_prices_station_card.dart';
import 'cross_border_banner.dart';
import 'sort_selector.dart';
import 'swipeable_station_card.dart';

/// Station list with sort controls, refresh, count bar, and search location header.
class SearchResultsList extends ConsumerStatefulWidget {
  final ServiceResult<List<Station>> result;
  final VoidCallback onRefresh;

  const SearchResultsList({
    super.key,
    required this.result,
    required this.onRefresh,
  });

  @override
  ConsumerState<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends ConsumerState<SearchResultsList> {
  SortMode _sortMode = SortMode.distance;

  void _openStationInMaps(Station station) {
    NavigationUtils.openInMaps(
      station.lat, station.lng,
      label: station.displayName,
    );
  }

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

  List<Station> _sortStations(List<Station> stations) {
    final sorted = List<Station>.from(stations);
    final fuelType = ref.read(selectedFuelTypeProvider);

    switch (_sortMode) {
      case SortMode.distance:
        sorted.sort((a, b) => a.dist.compareTo(b.dist));
      case SortMode.price:
        sorted.sort((a, b) => compareByPrice(a, b, fuelType));
      case SortMode.name:
        sorted.sort((a, b) => compareByName(a, b));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final l10n = AppLocalizations.of(context);
    final ignoredIds = ref.watch(ignoredStationsProvider);

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
              Text(
                result.freshnessLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const CrossBorderBanner(),
        SortSelector(
          selected: _sortMode,
          onChanged: (mode) => setState(() => _sortMode = mode),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: Builder(builder: (context) {
              // Filter out ignored stations
              final filtered = result.data
                  .where((s) => !ignoredIds.contains(s.id))
                  .toList();
              final sorted = _sortStations(filtered);
              final allPrices = ref.watch(allPricesViewEnabledProvider);
              final cheapestMap = allPrices
                  ? _computeCheapestFlags(sorted)
                  : <String, Map<FuelType, bool>>{};

              // Compute price range for tier icons (a11y)
              final fuelType = ref.watch(selectedFuelTypeProvider);
              final priceRange = _getPriceRange(sorted, fuelType);

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final station = sorted[index];
                  final isFav = ref.watch(isFavoriteProvider(station.id));

                  if (allPrices) {
                    return AllPricesStationCard(
                      key: ValueKey('all-prices-${station.id}'),
                      station: station,
                      isFavorite: isFav,
                      cheapestFlags: cheapestMap[station.id] ?? const {},
                      onTap: () => context.push('/station/${station.id}'),
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

                  return SwipeableStationCard(
                    key: ValueKey('station-${station.id}'),
                    station: station,
                    isFavorite: isFav,
                    priceTier: tier,
                    onNavigate: () => _openStationInMaps(station),
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
                    onTap: () => context.push('/station/${station.id}'),
                    onFavoriteTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(station.id, stationData: station),
                  );
                },
              );
            }),
          ),
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

    return Semantics(
      label: allPrices
          ? (l10n?.switchToCompactView ?? 'Switch to compact view')
          : (l10n?.switchToAllPricesView ?? 'Switch to all-prices view'),
      button: true,
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
    );
  }
}
