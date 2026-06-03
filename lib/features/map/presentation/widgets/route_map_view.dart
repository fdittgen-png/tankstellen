// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../itinerary/providers/itinerary_provider.dart';
import '../../../route_search/data/cross_border_corridor.dart'
    show fuelForStation;
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/providers/route_search_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../../search/domain/entities/station.dart';
import '../../../search/providers/search_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import 'route_best_stops_list.dart';
import 'route_info_bar.dart';
import 'route_view_mode_bar.dart';
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

  /// #2755 — the camera target: the bounds of the FULL route polyline,
  /// unioned with every along-route fuel station, computed ONCE from the
  /// immutable result. Framing these (instead of a ~5 km circle around the
  /// polyline midpoint) makes the camera show the COMPLETE itinerary; being
  /// constant across the All/Best toggle, it keeps `StationMapLayers`'
  /// value-`==` `_lastFitBounds` guard a no-op so the camera holds and never
  /// re-zooms to the changed station subset.
  late final LatLngBounds _routeBounds = _computeRouteBounds();

  /// Pre-layout camera fallback used by `MapOptions.initialCenter` /
  /// `initialZoom` before the first layout pass runs `initialCameraFit`
  /// (which frames `_routeBounds`). Mirrors `trip_path_map_card.dart`.
  late final LatLng _initialCenter = _routeBounds.center;

  List<Station> get _allFuelStations => widget.routeResult.stations
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();

  /// Build the route-framing bounds from the polyline geometry unioned
  /// with the along-route fuel stations. A degenerate single-point set
  /// gets a tiny epsilon box so `CameraFit.bounds` can't divide-by-zero
  /// (the same fallback as `trip_path_map_card.dart`).
  LatLngBounds _computeRouteBounds() {
    final points = <LatLng>[
      ...widget.routeResult.route.geometry,
      for (final s in _allFuelStations) LatLng(s.lat, s.lng),
    ];
    if (points.isEmpty) {
      // No geometry and no stations — fall back to a Paris-centred box.
      // (The build method renders an EmptyState in this case anyway.)
      points.add(const LatLng(48.8566, 2.3522));
    }
    if (points.length == 1) {
      final p = points.first;
      const eps = 0.0005; // ~50 m at the equator; fine for any latitude.
      return LatLngBounds(
        LatLng(p.latitude - eps, p.longitude - eps),
        LatLng(p.latitude + eps, p.longitude + eps),
      );
    }
    return LatLngBounds.fromPoints(points);
  }

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

    // #2755 — frame the COMPLETE itinerary. `center`/`zoom` are only the
    // pre-layout fallback (`MapOptions.initialCenter`/`initialZoom`); the
    // real first-paint viewport is framed by `initialCameraFit` to
    // `_routeBounds` inside `StationMapLayers`. The recenter button and
    // the toggle therefore always refit to the SAME route bounds, so the
    // camera holds across the All/Best toggle (no random re-zoom).
    final center = _initialCenter;
    const zoom = 6.0;

    // #2631 — price each station by ITS country's profile fuel (offline,
    // from lat/lng) so a cross-border Spanish station shows the E10 price
    // an E85 driver would pay instead of '--'. An empty `profileFuelByCountry`
    // (single-country search) makes this resolve to the active fuel — the
    // strict #2510 behaviour, unchanged.
    final fuelType = widget.selectedFuel as FuelType;
    FuelType resolveFuel(Station s) =>
        fuelForStation(s, result.profileFuelByCountry, fuelType);

    return Column(
      children: [
        RouteViewModeBar(
          allStationsSelected: _viewMode == RouteViewMode.allStations,
          bestStopsSelected: _viewMode == RouteViewMode.bestStops,
          selectedCount: _selectedStationIds.length,
          onTapAllStations: () => setState(() {
            _viewMode = RouteViewMode.allStations;
            _selectedStationIds.clear();
          }),
          onTapBestStops: () => setState(() {
            _viewMode = RouteViewMode.bestStops;
            _selectedStationIds.clear();
            for (final s in _getBestStopStations(allFuelStations, result)) {
              _selectedStationIds.add(s.id);
            }
          }),
          onOpenSelectedInMaps: () => _openSelectedInMaps(result),
        ),
        Expanded(
          child: StationMapLayers(
            mapController: widget.mapController,
            stations: displayStations,
            center: center,
            zoom: zoom,
            searchRadiusKm: 5,
            selectedFuel: widget.selectedFuel,
            showRecenterButton: true,
            // #2755 — recenter refits to the same full-route bounds the
            // camera was framed to, never the (changing) station subset.
            onRecenter: () => widget.mapController.fitCamera(
              CameraFit.bounds(
                bounds: _routeBounds,
                padding: const EdgeInsets.all(32),
              ),
            ),
            cameraFitBounds: _routeBounds,
            routePolyline: result.route.geometry,
            showSearchRadius: false,
            selectedStationIds:
                _selectedStationIds.isNotEmpty ? _selectedStationIds : null,
            fuelResolver: resolveFuel,
          ),
        ),
        if (_viewMode == RouteViewMode.bestStops && displayStations.isNotEmpty)
          RouteBestStopsList(
            stations: displayStations,
            selectedStationIds: _selectedStationIds,
            selectedFuel: widget.selectedFuel,
            fuelResolver: resolveFuel,
            onToggleStation: (id) => setState(() {
              if (_selectedStationIds.contains(id)) {
                _selectedStationIds.remove(id);
              } else {
                _selectedStationIds.add(id);
              }
            }),
          ),
        RouteInfoBar(
          distanceKm: result.route.distanceKm,
          durationMinutes: result.route.durationMinutes,
          stationCountLabel: _viewMode == RouteViewMode.bestStops
              ? (l10n?.nBest(displayStations.length) ??
                  '${displayStations.length} best')
              : (l10n?.nStations(allFuelStations.length) ??
                  '${allFuelStations.length}'),
          onSaveRoute: () => _showSaveRouteDialog(context, result),
          onOpenInMaps: () => _openSelectedInMaps(result),
        ),
      ],
    );
  }
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
            hintText: l10n?.routeNameHintExample ?? 'e.g. Paris \u2192 Lyon',
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
    // Defer dispose to the next frame so the AlertDialog's exit animation
    // can finish rebuilding the still-mounted TextField before its
    // controller vanishes. Disposing synchronously here races the animation
    // and throws "TextEditingController used after being disposed" in
    // debug/test builds.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
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
        final l10n = AppLocalizations.of(context);
        if (success) {
          SnackBarHelper.showSuccess(
              context, l10n?.routeSaved ?? 'Route saved!');
        } else {
          SnackBarHelper.showError(
              context, l10n?.routeSaveFailed ?? 'Failed to save route');
        }
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
}
