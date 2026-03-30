import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../itinerary/providers/itinerary_provider.dart';
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/providers/search_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../widgets/station_map_layers.dart';

/// Route map view modes.
enum _RouteViewMode { allStations, bestStops }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  _RouteViewMode _viewMode = _RouteViewMode.allStations;
  final Set<String> _selectedStationIds = {};

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final routeState = ref.watch(routeSearchStateProvider);
    final l10n = AppLocalizations.of(context);

    final hasRouteResults = routeState.hasValue && routeState.value != null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: AppBar(
          title: Text(l10n?.map ?? 'Map', style: const TextStyle(fontSize: 16)),
          toolbarHeight: 36,
          titleSpacing: 12,
        ),
      ),
      body: hasRouteResults
          ? _buildRouteMap(context, l10n, routeState.value!, selectedFuel)
          : _buildNearbyMap(context, l10n, searchState, selectedFuel, searchRadius),
    );
  }

  // ---------------------------------------------------------------------------
  // Route map with two view modes
  // ---------------------------------------------------------------------------

  Widget _buildRouteMap(
    BuildContext context,
    AppLocalizations? l10n,
    RouteSearchResult result,
    dynamic selectedFuel,
  ) {
    final allFuelStations = result.stations
        .whereType<FuelStationResult>()
        .map((r) => r.station)
        .toList();

    if (allFuelStations.isEmpty && result.route.geometry.isEmpty) {
      return EmptyState(
        icon: Icons.route,
        title: l10n?.noStationsAlongRoute ?? 'No stations found along route',
        actionLabel: l10n?.search ?? 'Back to search',
        onAction: () => context.go('/'),
      );
    }

    // Determine which stations to show based on view mode
    final displayStations = _viewMode == _RouteViewMode.bestStops
        ? _getBestStopStations(allFuelStations, result)
        : allFuelStations;

    final midIdx = result.route.geometry.length ~/ 2;
    final center = result.route.geometry.isNotEmpty
        ? result.route.geometry[midIdx]
        : const LatLng(48.8566, 2.3522);
    final zoom = _zoomForRoute(result.route.distanceKm);
    final theme = Theme.of(context);

    return Column(
      children: [
        // View mode toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              _ViewModeChip(
                label: l10n?.allStations ?? 'All stations',
                icon: Icons.local_gas_station,
                selected: _viewMode == _RouteViewMode.allStations,
                onTap: () => setState(() {
                  _viewMode = _RouteViewMode.allStations;
                  _selectedStationIds.clear();
                }),
              ),
              const SizedBox(width: 8),
              _ViewModeChip(
                label: l10n?.bestStops ?? 'Best stops',
                icon: Icons.star,
                selected: _viewMode == _RouteViewMode.bestStops,
                onTap: () => setState(() {
                  _viewMode = _RouteViewMode.bestStops;
                  _selectedStationIds.clear();
                  // Auto-select all best stops
                  for (final s in _getBestStopStations(allFuelStations, result)) {
                    _selectedStationIds.add(s.id);
                  }
                }),
              ),
              const Spacer(),
              // Selection count + navigate button
              if (_selectedStationIds.isNotEmpty) ...[
                Text(
                  '${_selectedStationIds.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.navigation, size: 18,
                      color: theme.colorScheme.primary),
                  tooltip: l10n?.openInMaps ?? 'Open in Maps',
                  onPressed: () => _openSelectedInMaps(result),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),
        ),

        // Map
        Expanded(
          child: StationMapLayers(
            mapController: _mapController,
            stations: displayStations,
            center: center,
            zoom: zoom,
            searchRadiusKm: 5,
            selectedFuel: selectedFuel,
            showRecenterButton: true,
            onRecenter: () => _mapController.move(center, zoom),
            routePolyline: result.route.geometry,
            showSearchRadius: false,
            selectedStationIds: _selectedStationIds.isNotEmpty ? _selectedStationIds : null,
          ),
        ),

        // Best stops list (scrollable, tappable for selection)
        if (_viewMode == _RouteViewMode.bestStops && displayStations.isNotEmpty)
          Container(
            height: 44,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              itemCount: displayStations.length,
              itemBuilder: (context, index) {
                final station = displayStations[index];
                final isSelected = _selectedStationIds.contains(station.id);
                final price = station.priceFor(selectedFuel);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedStationIds.remove(station.id);
                    } else {
                      _selectedStationIds.add(station.id);
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 10,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 3),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.displayName,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${price != null ? "${price.toStringAsFixed(3)}\u20ac" : "--"} · ${station.dist}km',
                              style: TextStyle(fontSize: 8, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Route info bar — compact
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.route, size: 12, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${result.route.distanceKm.round()}km · ${result.route.durationMinutes.round()}min',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(
                _viewMode == _RouteViewMode.bestStops
                    ? (l10n?.nBest(displayStations.length) ?? '${displayStations.length} best')
                    : (l10n?.nStations(allFuelStations.length) ?? '${allFuelStations.length}'),
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_add, size: 14),
                tooltip: l10n?.saveRoute ?? 'Save route',
                onPressed: () => _showSaveRouteDialog(context, result),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                iconSize: 14,
              ),
              IconButton(
                icon: const Icon(Icons.navigation, size: 14),
                tooltip: l10n?.openInMaps ?? 'Open in Maps',
                onPressed: () => _openSelectedInMaps(result),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                iconSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showSaveRouteDialog(BuildContext context, RouteSearchResult result) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.saveRoute ?? 'Save Route'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n?.routeName ?? 'Route name',
            hintText: 'e.g. Paris → Lyon',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name != null && name.isNotEmpty && mounted) {
      // Get the waypoints from the route — use start/end of geometry
      final start = result.route.geometry.first;
      final end = result.route.geometry.last;

      final selectedIds = _selectedStationIds.toList();
      final profile = ref.read(activeProfileProvider);

      final success = await ref.read(itineraryProvider.notifier).saveRoute(
        name: name,
        waypoints: [
          RouteWaypoint(lat: start.latitude, lng: start.longitude, label: 'Start'),
          RouteWaypoint(lat: end.latitude, lng: end.longitude, label: 'Destination'),
        ],
        distanceKm: result.route.distanceKm,
        durationMinutes: result.route.durationMinutes,
        avoidHighways: profile?.avoidHighways ?? false,
        fuelType: ref.read(selectedFuelTypeProvider).apiValue,
        selectedStationIds: selectedIds,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Route saved!' : 'Failed to save route')),
        );
      }
    }
  }

  /// Filter to only the cheapest station per route segment.
  List<Station> _getBestStopStations(
    List<Station> allStations,
    RouteSearchResult result,
  ) {
    final segmentMap = result.cheapestPerSegment;
    if (segmentMap == null || segmentMap.isEmpty) {
      // Fallback: just return overall cheapest
      if (result.cheapestId != null) {
        return allStations.where((s) => s.id == result.cheapestId).toList();
      }
      return allStations.take(5).toList();
    }

    final bestIds = segmentMap.values.toSet();
    return allStations.where((s) => bestIds.contains(s.id)).toList();
  }

  /// Open route in Google Maps with selected stations as waypoints.
  ///
  /// Stations are sorted by their position along the route polyline
  /// (not by price) so Google Maps doesn't create a zigzag detour.
  /// Only stations close to the route are included as waypoints.
  void _openSelectedInMaps(RouteSearchResult result) {
    final start = result.route.geometry.first;
    final end = result.route.geometry.last;

    final allStations = result.stations
        .whereType<FuelStationResult>()
        .map((r) => r.station)
        .toList();

    var selectedStations = _selectedStationIds.isNotEmpty
        ? allStations.where((s) => _selectedStationIds.contains(s.id)).toList()
        : _getBestStopStations(allStations, result);

    // Sort stations by their position along the route polyline.
    // For each station, find the index of the nearest polyline point.
    // This ensures waypoints are passed to Maps in driving order.
    final polyline = result.route.geometry;
    selectedStations = List<Station>.from(selectedStations)
      ..sort((a, b) {
        final aIdx = _nearestPolylineIndex(a.lat, a.lng, polyline);
        final bIdx = _nearestPolylineIndex(b.lat, b.lng, polyline);
        return aIdx.compareTo(bIdx);
      });

    // Use centralized NavigationUtils for route opening
    NavigationUtils.openRouteInMaps(
      origin: '${start.latitude},${start.longitude}',
      destination: '${end.latitude},${end.longitude}',
      waypoints: selectedStations.map((s) => '${s.lat},${s.lng}').toList(),
    );
  }

  /// Find the index of the nearest polyline point to a station.
  /// Used to sort waypoints in driving order along the route.
  int _nearestPolylineIndex(double lat, double lng, List<LatLng> polyline) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    // Sample every 5th point for performance on long polylines
    final step = polyline.length > 200 ? 5 : 1;
    for (int i = 0; i < polyline.length; i += step) {
      final p = polyline[i];
      final d = (p.latitude - lat) * (p.latitude - lat) +
                (p.longitude - lng) * (p.longitude - lng);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  // ---------------------------------------------------------------------------
  // Nearby map (unchanged)
  // ---------------------------------------------------------------------------

  Widget _buildNearbyMap(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue searchState,
    dynamic selectedFuel,
    double searchRadius,
  ) {
    return searchState.when(
      data: (result) {
        final stations = result.data;

        if (stations.isEmpty) {
          return EmptyState(
            icon: Icons.map_outlined,
            title: l10n?.startSearch ?? 'Search for stations to see them on the map',
            actionLabel: l10n?.search ?? 'Search now',
            onAction: () => context.go('/'),
            iconSize: 80,
          );
        }

        final center = StationMapLayers.centerOf(stations);
        final zoom = StationMapLayers.zoomForRadius(searchRadius);

        return Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(
              child: StationMapLayers(
                mapController: _mapController,
                stations: stations,
                center: center,
                zoom: zoom,
                searchRadiusKm: searchRadius,
                selectedFuel: selectedFuel,
                showRecenterButton: true,
                onRecenter: () => _mapController.move(center, zoom),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.local_gas_station, size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.nStations(stations.length) ?? '${stations.length} stations',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.circle, size: 8,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  Text(
                    '${searchRadius.round()} km ${l10n?.searchRadius ?? "radius"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    result.freshnessLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ServiceChainErrorWidget(
        error: error,
        onRetry: () => context.go('/'),
      ),
    );
  }

  double _zoomForRoute(double distanceKm) {
    if (distanceKm <= 50) return 10;
    if (distanceKm <= 100) return 9;
    if (distanceKm <= 200) return 8;
    if (distanceKm <= 500) return 7;
    if (distanceKm <= 1000) return 6;
    return 5;
  }
}

/// Compact chip for switching between map view modes.
class _ViewModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
