import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
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
import 'station_map_layers.dart';

/// View modes for the route map.
enum RouteViewMode { allStations, bestStops }

/// Displays a route map with stations along the route, supporting
/// "all stations" and "best stops" view modes with station selection.
class RouteMapView extends ConsumerStatefulWidget {
  final RouteSearchResult routeResult;
  final dynamic selectedFuel;
  final MapController mapController;

  const RouteMapView({
    super.key,
    required this.routeResult,
    required this.selectedFuel,
    required this.mapController,
  });

  @override
  ConsumerState<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends ConsumerState<RouteMapView> {
  RouteViewMode _viewMode = RouteViewMode.allStations;
  final Set<String> _selectedStationIds = {};

  List<Station> get _allFuelStations => widget.routeResult.stations
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = widget.routeResult;
    final allFuelStations = _allFuelStations;

    if (allFuelStations.isEmpty && result.route.geometry.isEmpty) {
      return EmptyState(
        icon: Icons.route,
        title: l10n?.noStationsAlongRoute ?? 'No stations found along route',
        actionLabel: l10n?.search ?? 'Back to search',
        onAction: () => context.go('/'),
      );
    }

    final displayStations = _viewMode == RouteViewMode.bestStops
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
        _buildViewModeToggle(theme, l10n, allFuelStations, result),
        Expanded(
          child: StationMapLayers(
            mapController: widget.mapController,
            stations: displayStations,
            center: center,
            zoom: zoom,
            searchRadiusKm: 5,
            selectedFuel: widget.selectedFuel,
            showRecenterButton: true,
            onRecenter: () => widget.mapController.move(center, zoom),
            routePolyline: result.route.geometry,
            showSearchRadius: false,
            selectedStationIds:
                _selectedStationIds.isNotEmpty ? _selectedStationIds : null,
          ),
        ),
        if (_viewMode == RouteViewMode.bestStops && displayStations.isNotEmpty)
          _buildBestStopsList(theme, displayStations),
        _buildRouteInfoBar(theme, l10n, result, displayStations, allFuelStations),
      ],
    );
  }

  Widget _buildViewModeToggle(
    ThemeData theme,
    AppLocalizations? l10n,
    List<Station> allFuelStations,
    RouteSearchResult result,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _ViewModeChip(
            label: l10n?.allStations ?? 'All stations',
            icon: Icons.local_gas_station,
            selected: _viewMode == RouteViewMode.allStations,
            onTap: () => setState(() {
              _viewMode = RouteViewMode.allStations;
              _selectedStationIds.clear();
            }),
          ),
          const SizedBox(width: 8),
          _ViewModeChip(
            label: l10n?.bestStops ?? 'Best stops',
            icon: Icons.star,
            selected: _viewMode == RouteViewMode.bestStops,
            onTap: () => setState(() {
              _viewMode = RouteViewMode.bestStops;
              _selectedStationIds.clear();
              for (final s in _getBestStopStations(allFuelStations, result)) {
                _selectedStationIds.add(s.id);
              }
            }),
          ),
          const Spacer(),
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
              icon: Icon(Icons.navigation,
                  size: 18, color: theme.colorScheme.primary),
              tooltip: l10n?.openInMaps ?? 'Open in Maps',
              onPressed: () => _openSelectedInMaps(result),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBestStopsList(ThemeData theme, List<Station> displayStations) {
    return Container(
      height: 44,
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        itemCount: displayStations.length,
        itemBuilder: (context, index) {
          final station = displayStations[index];
          final isSelected = _selectedStationIds.contains(station.id);
          final price = station.priceFor(widget.selectedFuel);
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
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 10,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 3),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.displayName,
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${price != null ? "${price.toStringAsFixed(3)}\u20ac" : "--"} · ${station.dist}km',
                        style:
                            TextStyle(fontSize: 8, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteInfoBar(
    ThemeData theme,
    AppLocalizations? l10n,
    RouteSearchResult result,
    List<Station> displayStations,
    List<Station> allFuelStations,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.route, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '${result.route.distanceKm.round()}km · ${result.route.durationMinutes.round()}min',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Text(
            _viewMode == RouteViewMode.bestStops
                ? (l10n?.nBest(displayStations.length) ??
                    '${displayStations.length} best')
                : (l10n?.nStations(allFuelStations.length) ??
                    '${allFuelStations.length}'),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _showSaveRouteDialog(
      BuildContext context, RouteSearchResult result) async {
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
            hintText: 'e.g. Paris \u2192 Lyon',
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
      final start = result.route.geometry.first;
      final end = result.route.geometry.last;
      final selectedIds = _selectedStationIds.toList();
      final profile = ref.read(activeProfileProvider);

      final success = await ref.read(itineraryProvider.notifier).saveRoute(
        name: name,
        waypoints: [
          RouteWaypoint(
              lat: start.latitude, lng: start.longitude, label: 'Start'),
          RouteWaypoint(
              lat: end.latitude, lng: end.longitude, label: 'Destination'),
        ],
        distanceKm: result.route.distanceKm,
        durationMinutes: result.route.durationMinutes,
        avoidHighways: profile?.avoidHighways ?? false,
        fuelType: ref.read(selectedFuelTypeProvider).apiValue,
        selectedStationIds: selectedIds,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(success ? 'Route saved!' : 'Failed to save route')),
        );
      }
    }
  }

  List<Station> _getBestStopStations(
    List<Station> allStations,
    RouteSearchResult result,
  ) {
    final segmentMap = result.cheapestPerSegment;
    if (segmentMap == null || segmentMap.isEmpty) {
      if (result.cheapestId != null) {
        return allStations.where((s) => s.id == result.cheapestId).toList();
      }
      return allStations.take(5).toList();
    }
    final bestIds = segmentMap.values.toSet();
    return allStations.where((s) => bestIds.contains(s.id)).toList();
  }

  void _openSelectedInMaps(RouteSearchResult result) {
    final start = result.route.geometry.first;
    final end = result.route.geometry.last;
    final allStations = _allFuelStations;

    var selectedStations = _selectedStationIds.isNotEmpty
        ? allStations.where((s) => _selectedStationIds.contains(s.id)).toList()
        : _getBestStopStations(allStations, result);

    final polyline = result.route.geometry;
    selectedStations = List<Station>.from(selectedStations)
      ..sort((a, b) {
        final aIdx = _nearestPolylineIndex(a.lat, a.lng, polyline);
        final bIdx = _nearestPolylineIndex(b.lat, b.lng, polyline);
        return aIdx.compareTo(bIdx);
      });

    NavigationUtils.openRouteInMaps(
      origin: '${start.latitude},${start.longitude}',
      destination: '${end.latitude},${end.longitude}',
      waypoints: selectedStations.map((s) => '${s.lat},${s.lng}').toList(),
    );
  }

  int _nearestPolylineIndex(double lat, double lng, List<LatLng> polyline) {
    int bestIdx = 0;
    double bestDist = double.infinity;
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
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
