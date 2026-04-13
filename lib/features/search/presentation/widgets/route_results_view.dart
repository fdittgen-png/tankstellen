import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/search_result_item.dart';
import '../../providers/ignored_stations_provider.dart';
import '../../providers/search_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import 'ev_station_card.dart';
import 'mode_chip.dart';
import 'station_card.dart';

/// View mode toggle for route search results.
enum RouteResultMode { allStations, bestStops }

/// Displays route search results as a sliver list with an all/best-stops
/// toggle and dismissible station cards (swipe to navigate or hide).
class RouteResultsView extends ConsumerStatefulWidget {
  const RouteResultsView({super.key});

  @override
  ConsumerState<RouteResultsView> createState() => _RouteResultsViewState();
}

class _RouteResultsViewState extends ConsumerState<RouteResultsView> {
  RouteResultMode _resultMode = RouteResultMode.allStations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fuelType = ref.watch(selectedFuelTypeProvider);
    final routeState = ref.watch(routeSearchStateProvider);

    return routeState.when(
      data: (result) {
        if (result == null) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                l10n?.startSearch ?? 'Enter start and destination to search along route.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (result.stations.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                l10n?.noStationsAlongThisRoute ?? 'No stations found along this route.',
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final ignoredIds = ref.watch(ignoredStationsProvider);
        final visibleStations = result.stations
            .where((s) => !ignoredIds.contains(s.id))
            .toList();

        // Sort stations by position along the route (drive order)
        _sortByRoutePosition(visibleStations, result.route.geometry);

        final allFuelStations = visibleStations.whereType<FuelStationResult>().toList();
        final displayItems = _resultMode == RouteResultMode.bestStops
            ? _filterBestStops(allFuelStations, result)
            : visibleStations;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return _buildHeader(context, l10n, result);
              }
              final item = displayItems[index - 1];
              if (item is FuelStationResult) {
                return _buildDismissibleCard(context, l10n, item, fuelType, result);
              } else if (item is EVStationResult) {
                return EVStationCard(
                  key: ValueKey('route-ev-${item.station.id}'),
                  result: item,
                  onTap: () => context.push('/ev-station', extra: item.station),
                );
              }
              return const SizedBox.shrink();
            },
            childCount: displayItems.length + 1,
          ),
        );
      },
      loading: () => const SliverFillRemaining(child: ShimmerStationList()),
      error: (error, _) => SliverFillRemaining(
        child: ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.read(routeSearchStateProvider.notifier).clear(),
        ),
      ),
    );
  }

  /// Route info header with distance/duration and all/best-stops toggle.
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? l10n,
    RouteSearchResult result,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.route.distanceKm.round()} km · '
                  '${result.route.durationMinutes.round()} min · '
                  '${result.stations.length} stations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ModeChip(
                label: l10n?.allStations ?? 'All stations',
                icon: Icons.local_gas_station,
                selected: _resultMode == RouteResultMode.allStations,
                onTap: () => setState(() => _resultMode = RouteResultMode.allStations),
              ),
              const SizedBox(width: 8),
              ModeChip(
                label: l10n?.bestStops ?? 'Best stops',
                icon: Icons.star,
                selected: _resultMode == RouteResultMode.bestStops,
                onTap: () => setState(() => _resultMode = RouteResultMode.bestStops),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A single station card wrapped in a Dismissible for swipe actions.
  Widget _buildDismissibleCard(
    BuildContext context,
    AppLocalizations? l10n,
    FuelStationResult item,
    FuelType fuelType,
    RouteSearchResult result,
  ) {
    return Dismissible(
      key: ValueKey('swipe-${item.id}'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await NavigationUtils.openInMaps(
            item.station.lat, item.station.lng,
            label: item.station.displayName,
          );
          return false;
        } else {
          await ref.read(ignoredStationsProvider.notifier).add(item.id);
          if (context.mounted) {
            final stationLabel = item.station.brand.isNotEmpty ? item.station.brand : item.station.name;
            final l10n = AppLocalizations.of(context);
            SnackBarHelper.showWithUndo(
              context,
              l10n?.stationHidden(stationLabel) ?? '$stationLabel hidden',
              undoLabel: l10n?.undo ?? 'Undo',
              onUndo: () => ref.read(ignoredStationsProvider.notifier).remove(item.id),
            );
          }
          return true;
        }
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: Theme.of(context).colorScheme.primary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.navigate ?? 'Navigate',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.orange.shade700,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n?.swipeHide ?? 'Hide',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.visibility_off, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: StationCard(
        station: item.station,
        selectedFuelType: fuelType,
        isFavorite: ref.watch(isFavoriteProvider(item.id)),
        profileFuelType: ref.watch(activeProfileProvider)?.preferredFuelType,
        onTap: () => context.push('/station/${item.id}'),
        onFavoriteTap: () => ref.read(favoritesProvider.notifier)
            .toggle(item.id, stationData: item.station),
        isCheapest: item.id == result.cheapestId,
      ),
    );
  }

  /// Sort stations by their position along the route polyline.
  ///
  /// For each station, finds the nearest polyline point index — this
  /// represents how far along the route the station is. Stations
  /// near the start of the route appear first.
  void _sortByRoutePosition(
    List<SearchResultItem> items,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return;

    // Sample every 3rd point for performance on long routes
    final step = polyline.length > 300 ? 3 : 1;

    double nearestPolylineIndex(double lat, double lng) {
      double minDist = double.infinity;
      int bestIdx = 0;
      for (int i = 0; i < polyline.length; i += step) {
        final d = distanceKm(lat, lng, polyline[i].latitude, polyline[i].longitude);
        if (d < minDist) {
          minDist = d;
          bestIdx = i;
        }
      }
      return bestIdx.toDouble();
    }

    items.sort((a, b) {
      final posA = nearestPolylineIndex(a.lat, a.lng);
      final posB = nearestPolylineIndex(b.lat, b.lng);
      return posA.compareTo(posB);
    });
  }

  /// Filter to only the cheapest station per route segment.
  List<SearchResultItem> _filterBestStops(
    List<FuelStationResult> allStations,
    RouteSearchResult result,
  ) {
    final segmentMap = result.cheapestPerSegment;
    if (segmentMap == null || segmentMap.isEmpty) {
      if (result.cheapestId != null) {
        return allStations.where((s) => s.id == result.cheapestId).cast<SearchResultItem>().toList();
      }
      return allStations.take(5).cast<SearchResultItem>().toList();
    }
    final bestIds = segmentMap.values.toSet();
    return allStations.where((s) => bestIds.contains(s.id)).cast<SearchResultItem>().toList();
  }
}
