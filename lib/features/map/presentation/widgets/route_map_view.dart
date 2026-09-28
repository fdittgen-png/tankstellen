// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/station_offer.dart';
import '../../../../core/time/app_clock.dart';
import '../../../../core/utils/best_stops.dart';
import '../../../../core/utils/route_projection.dart';
import '../../../../core/widgets/shell_bottom_inset.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../itinerary/providers/itinerary_provider.dart';
import '../../../route_search/data/cross_border_corridor.dart'
    show fuelForStation;
import '../../../route_search/domain/entities/route_info.dart';
import '../../../route_search/api.dart'
    show
        RouteLiveProgress,
        RouteLiveProgressScope,
        RouteStopMetricsScope,
        RouteUpdateFromPositionBanner,
        aheadOfDriver,
        routeLiveProgressControllerProvider;
import '../../../route_search/providers/route_search_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../../../core/domain/station.dart';
import '../../../search/providers/search_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import 'route_map_framing.dart';
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

  /// #4432 — the camera frame and route metrics, held per ROUTE (see
  /// [RouteMapFraming]): recomputed when a new route revision lands,
  /// held across partial batches and the All/Best toggle.
  final RouteMapFraming _framing = RouteMapFraming();

  LatLngBounds get _routeBounds => _framing.boundsFor(widget.routeResult);

  /// #4432 — route-local selections belong to the route they were made
  /// on. When a new route replaces it, a selection survives only if the
  /// station is still one of the new route's results; the rest are
  /// dropped rather than launched as waypoints of a route that no longer
  /// contains them.
  @override
  void didUpdateWidget(RouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (RouteMapFraming.isNewRoute(oldWidget.routeResult, widget.routeResult)) {
      final ids = {for (final s in widget.routeResult.stations) s.id};
      _selectedStationIds.retainWhere(ids.contains);
    }
  }

  List<Station> get _allFuelStations => widget.routeResult.stations
      .whereType<FuelStationResult>()
      .map((r) => r.station)
      .toList();

  /// #4432 — the stations still ahead of the driver: markers, counts,
  /// best stops and the maps launch drop a stop already passed, by the
  /// same retirement rule as the list.
  List<Station> _aheadFuelStations(RouteLiveProgress progress) =>
      aheadOfDriver(widget.routeResult, progress, _allFuelStations,
          (s) => (lat: s.lat, lng: s.lng));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = widget.routeResult;
    final progress = ref.watch(routeLiveProgressControllerProvider);
    final allFuelStations = _aheadFuelStations(progress);
    final now = ref.watch(appClockProvider).now();

    if (allFuelStations.isEmpty && result.route.geometry.isEmpty) {
      return EmptyState(
        icon: Icons.route,
        title: l10n.noStationsAlongRoute,
        actionLabel: l10n.search,
        onAction: () => context.go(RoutePaths.search),
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
    // #4432 — `StationMapLayers` re-fits when this centre changes VALUE,
    // which is exactly when `_routeBounds` moved to a new route.
    final routeBounds = _routeBounds;
    final center = routeBounds.center;
    const zoom = 6.0;

    // #2631 — price each station by ITS country's profile fuel (offline,
    // from lat/lng) so a cross-border Spanish station shows the E10 price
    // an E85 driver would pay instead of '--'. An empty `profileFuelByCountry`
    // (single-country search) makes this resolve to the active fuel — the
    // strict #2510 behaviour, unchanged.
    final fuelType = widget.selectedFuel as FuelType;
    FuelType resolveFuel(Station s) =>
        fuelForStation(s, result.profileFuelByCountry, fuelType);

    return RouteLiveProgressScope(child: RouteStopMetricsScope(
      // #4432 — the chips and the marker sheet below are shared with the
      // nearby map; this scope is how they learn they are on a route.
      metrics: _framing.metricsFor(result),
      child: Column(
      children: [
        const RouteUpdateFromPositionBanner(),
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
            // #4432 — `center` is `_routeBounds.center`, the bounding box
            // of the along-route STATIONS (#2782/#2755). It is a camera
            // target, not a position, so nothing is drawn there. The
            // route's start and destination are marked from the polyline;
            // the device marker is the latest accepted foreground fix, else
            // the request's current-location fix, and only while that fix
            // is still current — no fix, no "you are here" claim.
            center: center,
            originMarker: progress.currentFix(now) ??
                result.request?.currentDeviceFix(now),
            zoom: zoom,
            searchRadiusKm: 5,
            selectedFuel: widget.selectedFuel as FuelType,
            showRecenterButton: true,
            // #2755 — recenter refits to the same full-route bounds the
            // camera was framed to, never the (changing) station subset.
            onRecenter: () => widget.mapController.fitCamera(
              CameraFit.bounds(
                bounds: _routeBounds,
                padding: const EdgeInsets.all(32),
              ),
            ),
            cameraFitBounds: routeBounds,
            routePolyline: result.route.geometry,
            showSearchRadius: false,
            selectedStationIds: _selectedStationIds.isNotEmpty
                ? _selectedStationIds
                : null,
            fuelResolver: resolveFuel,
            // #3000 (Epic #2997) — adopt the radar clustered+cheapest-labelled
            // grammar, but SELECTION-AWARE: cluster the non-selected stations
            // while the Best/All SELECTED stations stay as full, un-clustered
            // price pills so the multi-select highlighting + the
            // RouteBestStopsList↔marker 1:1 mapping survive at every zoom.
            clusterAlways: true,
            excludeSelectedFromClustering: true,
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
        // #4147 — the bar carries CONTROLS, so it clears the chrome the
        // map is allowed to paint behind. Without this its two actions
        // land on the Android gesture strip.
        ShellBottomInset(
          child: RouteInfoBar(
          distanceKm: result.route.distanceKm,
          durationMinutes: result.route.durationMinutes,
          stationCountLabel: _viewMode == RouteViewMode.bestStops
              ? (l10n.nBest(displayStations.length))
              : (l10n.nStations(allFuelStations.length)),
          onSaveRoute: () => _showSaveRouteDialog(context, result),
          onOpenInMaps: () => _openSelectedInMaps(result),
          ),
        ),
      ],
    )));
  }

  Future<void> _showSaveRouteDialog(
    BuildContext context,
    RouteSearchResult result,
  ) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveRoute),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.routeName,
            hintText: l10n.routeNameHintExample,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.save),
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
      // #3159 — capture everything ref-dependent BEFORE the await so the
      // unmount race can't touch a dead WidgetRef.
      final fuelType = ref.read(selectedFuelTypeProvider).apiValue;
      final itineraries = ref.read(itineraryProvider.notifier);
      final success = await itineraries.saveRoute(
        name: name,
        waypoints: [
          RouteWaypoint(
            lat: start.latitude,
            lng: start.longitude,
            label: 'Start',
          ),
          RouteWaypoint(
            lat: end.latitude,
            lng: end.longitude,
            label: 'Destination',
          ),
        ],
        distanceKm: result.route.distanceKm,
        durationMinutes: result.route.durationMinutes,
        avoidHighways: profile?.avoidHighways ?? false,
        fuelType: fuelType,
        selectedStationIds: selectedIds,
      );

      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        if (success) {
          SnackBarHelper.showSuccess(context, l10n.routeSaved);
        } else {
          SnackBarHelper.showError(context, l10n.routeSaveFailed);
        }
      }
    }
  }

  /// The cheapest station per route segment (#4125 — the rule itself
  /// lives in `core/utils/best_stops.dart`; the route results LIST
  /// applies the same one, which it could not while both features held
  /// a private copy).
  List<Station> _getBestStopStations(
    List<Station> allStations,
    RouteSearchResult result,
  ) =>
      bestStopsAmong<Station>(
        stations: allStations,
        idOf: (s) => s.id,
        cheapestPerSegment: result.cheapestPerSegment,
        cheapestId: result.cheapestId,
      );

  void _openSelectedInMaps(RouteSearchResult result) {
    final start = result.route.geometry.first;
    final end = result.route.geometry.last;
    final allStations =
        _aheadFuelStations(ref.read(routeLiveProgressControllerProvider));

    var selectedStations = _selectedStationIds.isNotEmpty
        ? allStations.where((s) => _selectedStationIds.contains(s.id)).toList()
        : _getBestStopStations(allStations, result);

    final polyline = result.route.geometry;
    // #4348 — a reference price stood in at a town centre is not a stop
    // anyone can make; it never becomes a waypoint.
    selectedStations = selectedStations
        .where((s) => StationOffer.forStation(
                stationId: s.id, lat: s.lat, lng: s.lng)
            .canRouteTo)
        .toList();
    // #4432 — launch waypoints in the order the route meets them, by
    // the same itinerary pass the list and the corridor filter use.
    final projection = RouteProjection(polyline);
    final along = {
      for (final s in selectedStations)
        s.id: projection.project(s.lat, s.lng).alongKm,
    };
    selectedStations.sort((a, b) => along[a.id]!.compareTo(along[b.id]!));

    unawaited(
      NavigationUtils.openRouteInMaps(
        origin: '${start.latitude},${start.longitude}',
        destination: '${end.latitude},${end.longitude}',
        waypoints: selectedStations.map((s) => '${s.lat},${s.lng}').toList(),
      ),
    );
  }
}
