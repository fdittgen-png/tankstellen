// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../route_search/data/cross_border_corridor.dart'
    show fuelForStation;
import '../../../route_search/providers/route_search_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/search_mode.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../../../core/domain/station.dart';
import '../../../search/presentation/widgets/sort_selector.dart';
import '../../../search/providers/radar_search_provider.dart';
import '../../../search/providers/search_mode_provider.dart';
import '../../../search/providers/search_provider.dart';
import '../../../search/providers/search_screen_ui_provider.dart';
import '../../../search/providers/selected_station_provider.dart';
import 'station_map_layers.dart';

/// A reusable map widget that displays station markers in the split-screen
/// landscape pane.
///
/// #2939 — "Clustered + cheapest-labelled". When the on-search Fuel Station
/// Radar owns the results (`radarSearchProvider.active`), the map renders the
/// RADAR stations — proximity-clustered with cheapest-price badges so the
/// narrow pane never overlaps — fits the camera to the actual result bounds,
/// and two-way-syncs selection with the list via `selectedStationProvider`
/// (tap a marker -> select the row; the selected row's marker is emphasised).
/// When the radar is idle it falls back to the regular `searchStateProvider`
/// results — also clustered now, so the split pane never overlaps either.
///
/// #3033 — when the active search mode is [SearchMode.route] the map takes a
/// dedicated route branch BEFORE the radar/search checks: it renders the
/// along-route fuel stations from `routeSearchStateProvider` (proximity-
/// clustered) plus the route polyline, framed to the result bounds — mirroring
/// the list's `RouteResultsView` early-return so the split pane no longer shows
/// the stale nearby set with no route line. The route chrome (All/Best toggle,
/// best-stops list, info bar) stays in the left pane; this map renders only the
/// map.
class InlineMap extends ConsumerStatefulWidget {
  const InlineMap({super.key});

  @override
  ConsumerState<InlineMap> createState() => _InlineMapState();
}

class _InlineMapState extends ConsumerState<InlineMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedFuel = ref.watch(selectedFuelTypeProvider);
    final searchRadius = ref.watch(searchRadiusProvider);
    final sortMode = ref.watch(selectedSortModeProvider);

    // #3033 — route mode OWNS the split map BEFORE the radar/search checks
    // (mirrors `SearchResultsContent`'s `RouteResultsView` early-return). The
    // route's along-route stations + polyline come from
    // `routeSearchStateProvider`; without this branch the pane fell through to
    // the stale `searchStateProvider` nearby set and never drew the route line.
    final searchMode = ref.watch(activeSearchModeProvider);
    if (searchMode == SearchMode.route) {
      final routeState = ref.watch(routeSearchStateProvider);
      return routeState.when(
        data: (result) {
          final stations = _routeFuelStations(result);
          final hasGeometry = result?.route.geometry.isNotEmpty ?? false;
          if (result == null || (stations.isEmpty && !hasGeometry)) {
            return EmptyState(
              icon: Icons.route,
              title: AppLocalizations.of(context)?.noStationsAlongRoute ??
                  'No stations found along route',
            );
          }
          return _buildRouteMap(context, result, stations, selectedFuel);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _mapUnavailable(context),
      );
    }

    // #2939 — the on-search radar OWNS the split map when active (mirrors the
    // results-list early-return in SearchResultsContent). Its stations are
    // clustered + fit-to-bounds and list<->map selection is two-way synced.
    // Idle -> regular search results.
    final radar = ref.watch(radarSearchProvider);
    if (radar.active) {
      return radar.stations.when(
        data: (stations) =>
            _buildMap(context, stations, selectedFuel, searchRadius, sortMode),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _mapUnavailable(context),
      );
    }

    final searchState = ref.watch(searchStateProvider);
    return searchState.when(
      data: (result) {
        final stations = result.data
            .whereType<FuelStationResult>()
            .map((r) => r.station)
            .toList();
        return _buildMap(
            context, stations, selectedFuel, searchRadius, sortMode);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _mapUnavailable(context),
    );
  }

  /// Render [stations] on the clustered split map, fitting the camera to the
  /// actual result bounds and wiring two-way list<->map selection.
  Widget _buildMap(
    BuildContext context,
    List<Station> stations,
    FuelType selectedFuel,
    double searchRadius,
    SortMode sortMode,
  ) {
    if (stations.isEmpty) {
      return EmptyState(
        icon: Icons.map_outlined,
        title: AppLocalizations.of(context)?.searchToSeeMap ??
            'Search to see stations on the map',
      );
    }

    // #2939 — fit the camera to the ACTUAL result bounds within the pane, not
    // the search-radius circle: a dense radar set is far smaller than the
    // radius (and a sparse one larger), so the radius zoom framed the wrong
    // viewport in the narrow split pane.
    final bounds = _boundsOf(stations);
    final center = StationMapLayers.centerOf(stations);

    // #2939 — two-way sync: emphasise the selected row's marker, and a marker
    // tap selects its row (keeping the map visible) instead of navigating.
    final selectedId = ref.watch(selectedStationProvider);

    return StationMapLayers(
      mapController: _mapController,
      stations: stations,
      center: center,
      zoom: StationMapLayers.zoomForRadius(searchRadius),
      searchRadiusKm: searchRadius,
      selectedFuel: selectedFuel,
      sortMode: sortMode,
      clusterAlways: true,
      cameraFitBounds: bounds,
      showSearchRadius: false,
      selectedStationIds: selectedId != null ? {selectedId} : null,
      onStationTap: (id) =>
          ref.read(selectedStationProvider.notifier).select(id),
    );
  }

  /// #3033 — render JUST the route map for the split pane: the along-route fuel
  /// [stations] (proximity-clustered) + the route polyline, framed to the
  /// along-route STATION bounds (mirrors `RouteMapView`, but without its
  /// All/Best toggle, best-stops list and info bar — those belong to the left
  /// pane). Each station prices by ITS country's profile fuel so a cross-border
  /// stop shows a real price instead of '--' (#2631).
  Widget _buildRouteMap(
    BuildContext context,
    RouteSearchResult result,
    List<Station> stations,
    FuelType selectedFuel,
  ) {
    // #2782 — frame the along-route STATION bounds (the results), not the full
    // cross-border polyline, so the camera fits what was found. Falls back to
    // the route geometry, then a default box, when there are no stations.
    final bounds = _routeBoundsOf(stations, result.route.geometry);
    final center = bounds.center;

    final selectedId = ref.watch(selectedStationProvider);

    return StationMapLayers(
      mapController: _mapController,
      stations: stations,
      center: center,
      // Pre-layout fallback only; `cameraFitBounds` drives the first paint.
      zoom: 6.0,
      searchRadiusKm: 5,
      selectedFuel: selectedFuel,
      cameraFitBounds: bounds,
      routePolyline: result.route.geometry,
      showSearchRadius: false,
      // Plain proximity clustering for the route overview — NOT
      // `excludeSelectedFromClustering` (with an empty selection that collapses
      // every station into one cheapest-labelled badge; the dedicated-map
      // All-Stations bug).
      clusterAlways: true,
      fuelResolver: (s) =>
          fuelForStation(s, result.profileFuelByCountry, selectedFuel),
      selectedStationIds: selectedId != null ? {selectedId} : null,
      onStationTap: (id) =>
          ref.read(selectedStationProvider.notifier).select(id),
    );
  }

  Widget _mapUnavailable(BuildContext context) => Center(
        child: Text(
          AppLocalizations.of(context)?.mapUnavailable ?? 'Map unavailable',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  /// The along-route fuel stations of [result] (drops EV/other result kinds),
  /// or `const []` when there is no result yet.
  static List<Station> _routeFuelStations(RouteSearchResult? result) =>
      result == null
          ? const []
          : result.stations
              .whereType<FuelStationResult>()
              .map((r) => r.station)
              .toList();

  /// The [LatLngBounds] of the result [stations], with a tiny epsilon box for
  /// a single result so `CameraFit.bounds` cannot divide-by-zero (mirrors
  /// `RouteMapView._computeRouteBounds`).
  static LatLngBounds _boundsOf(List<Station> stations) =>
      _boundsOfPoints([for (final s in stations) LatLng(s.lat, s.lng)]);

  /// #3033 — the camera bounds for the route map: the along-route STATION
  /// extent, falling back to the route [geometry] (so an empty route still
  /// frames its line), then a default box. Mirrors
  /// `RouteMapView._computeRouteBounds`.
  static LatLngBounds _routeBoundsOf(
    List<Station> stations,
    List<LatLng> geometry,
  ) {
    final points = <LatLng>[for (final s in stations) LatLng(s.lat, s.lng)];
    if (points.isEmpty) points.addAll(geometry);
    if (points.isEmpty) points.add(const LatLng(48.8566, 2.3522)); // Paris.
    return _boundsOfPoints(points);
  }

  /// Bounds over [points], with a tiny epsilon box for a single point so
  /// `CameraFit.bounds` cannot divide-by-zero. Assumes [points] is non-empty.
  static LatLngBounds _boundsOfPoints(List<LatLng> points) {
    if (points.length == 1) {
      final p = points.first;
      const eps = 0.0005; // ~50 m; fine for any latitude.
      return LatLngBounds(
        LatLng(p.latitude - eps, p.longitude - eps),
        LatLng(p.latitude + eps, p.longitude + eps),
      );
    }
    return LatLngBounds.fromPoints(points);
  }
}
