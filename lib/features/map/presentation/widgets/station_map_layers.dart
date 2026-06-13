// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/sparkilo_tile_layer.dart';
import 'station_map_geometry.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../search/presentation/widgets/sort_selector.dart';
import 'map_zoom_controls.dart';
import 'price_legend.dart';
import 'station_cluster_layers.dart';
import 'station_marker.dart';
import 'station_marker_model_builder.dart';

/// Camera zoom bounds (#1457). Top end matches the OSM tile cap so a
/// `move(camera.zoom + 1)` past the cap doesn't park the user on a
/// grey viewport with no tiles to draw. Bottom end is conservative —

/// Shared map widget containing all layers: tiles, search radius circle,
/// center marker, station markers with clustering, attribution, zoom
/// controls, and price legend.
///
/// Used by both [MapScreen] (full-screen) and [InlineMap] (split-screen)
/// to eliminate ~130 lines of duplicated map layer code.
///
/// ## One tile path (#2394 / #2398)
///
/// The basemap renders through the single hardened [SparkiloTileLayer].
/// Prior to #2398 this widget ran a *parallel* inline `TileLayer` plus a
/// 12-second cold-start "reset window" that fired `TileLayer.reset` on
/// every camera/size event during cold-start. That storm evicted tiles
/// before they painted on a slow first round-trip — the recurring
/// grey-tile bug (#757 → #1234 → #1316 → #1991 → #2044 → #2096 →
/// #2122 → #2177). The reset machinery is deleted: there is exactly one
/// tile path, every surface shares `abortObsoleteRequests: true`
/// (the upstream default inside [SparkiloTileLayer]), and there is no
/// reset stream to mis-fire. See `tile_layer_consistency_test.dart`
/// (allowlist is now the single `sparkilo_tile_layer.dart`) and
/// `station_map_layers_no_reset_test.dart`.
class StationMapLayers extends StatefulWidget {
  final MapController mapController;
  final List<Station> stations;
  final LatLng center;
  final double zoom;
  final double searchRadiusKm;
  final FuelType selectedFuel;

  /// The active list sort (#2510). Governs which stations are EMPHASIZED
  /// on the map: the top-ranked few keep their full price bubble while
  /// the rest render as compact price-band dots so a bounded result set
  /// stays fully visible without the bubbles overlapping. `price` /
  /// `priceDistance` emphasize the cheapest; everything else (distance,
  /// 24h, rating, name) emphasizes the closest. Defaults to
  /// [SortMode.price] — the savings-first emphasis — for callers (route,
  /// driving, inline) that don't surface a sort selector.
  final SortMode sortMode;

  final bool showRecenterButton;
  final VoidCallback? onRecenter;
  final List<LatLng>? routePolyline;
  final bool showSearchRadius;

  /// #2755 — when non-null, the camera frames THESE bounds (both the
  /// first-paint [MapOptions.initialCameraFit] and the post-ready re-fit)
  /// instead of the [boundsForRadius] circle around [center]. Route mode
  /// passes the full route-polyline bounds (unioned with the along-route
  /// stations) so the camera frames the COMPLETE itinerary rather than a
  /// ~5 km circle around the polyline midpoint, and the bounds stay
  /// identical across the All/Best toggle so the camera holds.
  ///
  /// Null on a nearby/radius search → the [boundsForRadius] path is used,
  /// byte-identical to the pre-#2755 behaviour (#2399 / #2510 unchanged).
  final LatLngBounds? cameraFitBounds;

  /// When non-null, stations NOT in this set are rendered in pastel.
  /// Stations IN this set use vivid/flashy colors for quick identification.
  final Set<String>? selectedStationIds;

  /// Additional map layers rendered after the station markers, e.g. the
  /// EV charging station overlay.
  final List<Widget> extraLayers;

  /// #2631 — on a cross-border route, maps a station to the fuel of ITS
  /// country's profile (offline, from the station's lat/lng). When set,
  /// marker price, colour and paint order all use that resolved fuel so a
  /// Spanish station shows the E10 price an E85 driver would pay instead
  /// of '--'. Null on a single-country search → strict [selectedFuel]
  /// behaviour (#2510), unchanged.
  final FuelType Function(Station)? fuelResolver;

  /// #2939 — "Clustered + cheapest-labelled". When true, EVERY result set is
  /// proximity-clustered (regardless of count) with a cheapest-price badge so
  /// the narrow landscape-radar split pane never overlaps. When false (the
  /// default) the legacy emphasis-then-cluster-at-[clusterThreshold] behaviour
  /// is byte-identical to pre-#2939.
  final bool clusterAlways;

  /// #2939 — when set, a marker tap fires this with the station id INSTEAD of
  /// navigating to `/station/{id}`, so the radar split map can select the
  /// matching list row (the inverse of a row tap) and keep the map visible.
  final void Function(String stationId)? onStationTap;

  /// #3000 (Epic #2997) — selection-aware clustering for the ROUTE map. Only
  /// meaningful with [clusterAlways]. When true, stations in
  /// [selectedStationIds] are partitioned OUT of the cheapest-labelled cluster
  /// and rendered as their own un-clustered full price pills (painted on top),
  /// while the rest fold into the cluster. Keeps the route map's Best/All
  /// multi-select highlighting and its `RouteBestStopsList`↔marker 1:1 mapping
  /// intact — a blanket cluster would otherwise collapse several selected
  /// stations into one ringed badge. Default false → the radar / Nearby
  /// blanket-cluster behaviour (#2939 / #2999) is unchanged.
  final bool excludeSelectedFromClustering;

  /// #3002 (Epic #2997) — how the station markers are RENDERED.
  /// [StationMarkerVariant.driving] makes the DRIVING map paint the big,
  /// driver-legible card (brand + tier icon + large price) instead of the
  /// small price-only pill, while still colouring from the shared
  /// [PriceBandColors.ramp]. Defaults to the pill, so nearby / radar / route
  /// are unchanged.
  final StationMarkerVariant markerVariant;

  /// #3002 (Epic #2997) — overrides the map's gesture flags. The DRIVING map
  /// passes its restricted set (drag | fling | double-tap-zoom, no pinch) so a
  /// glance-and-tap stays safe at the wheel. Null → the default
  /// [InteractiveFlag.all] (nearby / radar / route), unchanged.
  final InteractionOptions? interactionOptions;

  /// #3002 (Epic #2997) — fired on any background tap (not a marker). The
  /// DRIVING map wires this to its auto-lock reset so touching the map keeps
  /// the lock overlay away. Null → no map-tap callback (every other map).
  final void Function()? onMapTap;

  /// #3002 (Epic #2997) — when false, the +/− zoom (+ recenter) controls are
  /// hidden. The DRIVING map owns its own oversized bottom bar, so it suppresses
  /// the small overlay buttons. Defaults to true → nearby / radar / route keep
  /// their controls, unchanged.
  final bool showZoomControls;

  /// #3002 (Epic #2997) — when false, the bottom-left [PriceLegend] is hidden.
  /// The DRIVING map suppresses it so the legend never sits under the oversized
  /// driving bottom bar. Defaults to true → unchanged for every other map.
  final bool showLegend;

  const StationMapLayers({
    super.key,
    required this.mapController,
    required this.stations,
    required this.center,
    required this.zoom,
    required this.searchRadiusKm,
    required this.selectedFuel,
    this.sortMode = SortMode.price,
    this.showRecenterButton = false,
    this.onRecenter,
    this.routePolyline,
    this.showSearchRadius = true,
    this.cameraFitBounds,
    this.selectedStationIds,
    this.extraLayers = const [],
    this.fuelResolver,
    this.clusterAlways = false,
    this.onStationTap,
    this.excludeSelectedFromClustering = false,
    this.markerVariant = StationMarkerVariant.pill,
    this.interactionOptions,
    this.onMapTap,
    this.showZoomControls = true,
    this.showLegend = true,
  });

  @override
  State<StationMapLayers> createState() => _StationMapLayersState();

}

class _StationMapLayersState extends State<StationMapLayers> {
  /// #1774 — the marker list and the price range are memoised here and
  /// recomputed only when `stations` / `selectedFuel` /
  /// `selectedStationIds` actually change. `MapScreen` watches four
  /// providers, so without this every unrelated rebuild (or an
  /// app-resume widget refresh) re-ran `_getPriceRange` over every
  /// station and rebuilt every `Marker`.
  late List<Marker> _markers;
  late (double, double) _priceRange;

  /// #2939 — per-marker price + station id, keyed on marker identity, so the
  /// cluster badge can roll a cluster up to its cheapest member + spot the
  /// selected one (the builder only gets the [Marker]s). Rebuilt with [_markers].
  final Map<Marker, MarkerMeta> _markerMeta = {};

  /// #3000 — the per-marker meta map, exposed so a test can assert a clustered
  /// cross-border station carries its [fuelResolver]-derived price (not '--').
  @visibleForTesting
  Map<Marker, MarkerMeta> get markerMetaForTesting =>
      Map.unmodifiable(_markerMeta);

  /// True once FlutterMap has laid out and emitted `onMapReady`. The
  /// guarded `didUpdateWidget` fit waits on this so a `fitCamera` call
  /// never lands before the controller has a real viewport (#2399).
  bool _mapReady = false;

  /// The bounds the camera was last fitted to. Held so a redundant
  /// rebuild (EV-toggle, app resume, unrelated provider change) does not
  /// re-schedule an identical `fitCamera`. Set at SCHEDULE time so a
  /// fit→rebuild→fit loop cannot form (the next build computes the same
  /// bounds, finds them equal, skips) — relocated from `NearbyMapView`
  /// in #2399. First paint is positioned by `MapOptions.initialCameraFit`,
  /// so this only handles the stations-arrived / centre-moved transition.
  LatLngBounds? _lastFitBounds;

  /// The camera target for both `initialCameraFit` and the post-ready
  /// re-fit. #2755 — when an explicit [cameraFitBounds] is supplied (route
  /// mode), frame exactly those bounds; otherwise (nearby mode) fall back
  /// to the search circle around the current centre, byte-identical to the
  /// pre-#2755 behaviour.
  LatLngBounds get _fitBounds =>
      widget.cameraFitBounds ??
      StationMapGeometry.boundsForRadius(widget.center, widget.searchRadiusKm);

  /// Recompute the memoised price range + marker list from the current
  /// widget inputs. #3233 — the pricing / emphasis / ordering / build pipeline
  /// is the pure [StationMarkerModelBuilder]; this only latches its result.
  void _recomputeMarkers() {
    final model = StationMarkerModelBuilder.build(
      context: context,
      stations: widget.stations,
      selectedFuel: widget.selectedFuel,
      selectedStationIds: widget.selectedStationIds,
      byPrice: widget.sortMode == SortMode.price ||
          widget.sortMode == SortMode.priceDistance,
      clusterAlways: widget.clusterAlways,
      fuelResolver: widget.fuelResolver,
      onStationTap: widget.onStationTap,
      markerVariant: widget.markerVariant,
    );
    _markers = model.markers;
    _priceRange = model.priceRange;
    _markerMeta
      ..clear()
      ..addAll(model.meta);
  }

  @override
  void initState() {
    super.initState();
    _recomputeMarkers();
    // First paint is positioned by `MapOptions.initialCameraFit`, so the
    // initial fit is already accounted for; record it so the post-ready
    // re-fit doesn't redundantly re-snap to the same bounds.
    _lastFitBounds = _fitBounds;
  }

  @override
  void didUpdateWidget(StationMapLayers oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Riverpod hands back the same `stations` / `selectedStationIds`
    // references until the underlying value changes, so identity
    // comparison is enough to skip the recompute on an unrelated
    // `MapScreen` rebuild.
    final stationsChanged = !identical(oldWidget.stations, widget.stations);
    if (stationsChanged ||
        oldWidget.selectedFuel != widget.selectedFuel ||
        oldWidget.sortMode != widget.sortMode ||
        // #2631 — a changed cross-border resolver re-prices every marker.
        !identical(oldWidget.fuelResolver, widget.fuelResolver) ||
        !identical(oldWidget.selectedStationIds, widget.selectedStationIds)) {
      _recomputeMarkers();
    }

    // #2399 — the SINGLE re-fit. When stations are present and the
    // camera-anchoring centre changed VALUE (e.g. a new search landed
    // after a cold open, or a ZIP search jumped to another city),
    // schedule exactly ONE post-frame `fitCamera`. Guarded by:
    //   - non-empty stations (nothing to frame otherwise),
    //   - a value-distinct centre (`LatLng` has value `==`),
    //   - bounds not already fitted (`LatLngBounds` value `==`),
    //   - `mounted` + `_mapReady` inside the callback.
    // `_lastFitBounds` is set HERE (at schedule time, not in the
    // callback) so a fit→rebuild→fit loop cannot form. This replaces the
    // per-build post-frame fit that used to live in `NearbyMapView` and
    // land inside the cold-start reset window (deleted in #2398).
    final centerChanged = widget.center != oldWidget.center;
    if (widget.stations.isNotEmpty && centerChanged) {
      final bounds = _fitBounds;
      // `LatLngBounds` has value `==`, so this skips an identical re-fit.
      // `NearbyMapView.shouldFit` is the same pure predicate, kept there
      // for its unit test; inlined here to avoid an import cycle.
      if (_lastFitBounds != bounds) {
        _lastFitBounds = bounds;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_mapReady) return;
          widget.mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            // #2399 — frame the camera target during the FIRST layout
            // pass, not via a post-frame `fitCamera`. The old post-frame
            // fit raced the (now-deleted) cold-start reset window and
            // could land on a degenerate viewport. Positioning the
            // camera as part of layout means the very first tile fetch
            // already targets the right viewport — no reset needed.
            // #2755 — `_fitBounds` is the explicit [cameraFitBounds] (route
            // mode: the full itinerary) when supplied, else the search
            // circle (nearby mode, unchanged).
            initialCameraFit: CameraFit.bounds(
              bounds: _fitBounds,
              padding: const EdgeInsets.all(32),
            ),
            // #2399 — keep the FlutterMap (and its loaded tiles) alive
            // when offstage in an IndexedStack so a tab flip back to the
            // map doesn't tear down + cold-rebuild the tile pipeline.
            keepAlive: true,
            onMapReady: () {
              if (mounted) _mapReady = true;
            },
            // #1457 — clamp the camera to the tile-layer's max zoom (19)
            // so a programmatic `move(camera.zoom + 1)` past 19 doesn't
            // leave the user staring at a grey viewport (tiles only
            // render up to maxNativeZoom). The default flutter_map
            // MapOptions.maxZoom is 25 — that lets the camera stride
            // past where there are tiles to draw, which looks broken to
            // the user. Min clamp guards against accidental zoom-out
            // beyond the world wrap.
            minZoom: StationMapGeometry.minZoom,
            maxZoom: StationMapGeometry.maxZoom,
            // #3002 — the DRIVING map passes its restricted gesture set (no
            // pinch); every other map keeps the default all-gestures option.
            interactionOptions: widget.interactionOptions ??
                const InteractionOptions(flags: InteractiveFlag.all),
            // #3002 — driving wires a background-tap to its auto-lock reset.
            onTap: widget.onMapTap == null
                ? null
                : (_, _) => widget.onMapTap!(),
          ),
          children: [
            // #2398 — the SINGLE hardened tile path. No inline TileLayer,
            // no reset stream: the cold-start reset storm that evicted
            // tiles before they painted is gone. `SparkiloTileLayer`
            // owns its retry provider lifecycle and uses the upstream
            // default `abortObsoleteRequests: true`, unified with every
            // other map surface.
            const SparkiloTileLayer(key: ValueKey('main-tiles')),
            // Route polyline (if in route search mode)
            if (widget.routePolyline != null &&
                widget.routePolyline!.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePolyline!,
                    color: theme.colorScheme.primary,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            // Search radius circle
            if (widget.showSearchRadius)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.center,
                    radius: widget.searchRadiusKm * 1000,
                    useRadiusInMeter: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderColor:
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            // Center marker
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.center,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Station markers (#1774 — `_markers` is memoised). Modes:
            //  - #3000 `clusterAlways` + `excludeSelectedFromClustering`
            //    (route map): SELECTED stations stay un-clustered as full
            //    pills on top, the rest fold into the cheapest cluster — so
            //    the Best/All multi-select + list↔map 1:1 survive;
            //  - #2939 `clusterAlways` (radar / Nearby): proximity-cluster
            //    EVERY set with the cheapest-labelled badge;
            //  - legacy huge set (≥ clusterThreshold): bare count cluster;
            //  - legacy bounded set (#2510): plain [MarkerLayer], emphasis.
            if (_markers.isNotEmpty)
              if (widget.clusterAlways &&
                  widget.excludeSelectedFromClustering)
                ...selectionPartitionedClusterLayers(
                  markers: _markers,
                  metaOf: (m) => _markerMeta[m],
                  priceRange: _priceRange,
                  selectedIds:
                      widget.selectedStationIds ?? const <String>{},
                )
              else if (widget.clusterAlways)
                cheapestLabelledClusterLayer(
                  markers: _markers,
                  metaOf: (m) => _markerMeta[m],
                  priceRange: _priceRange,
                  selectedIds:
                      widget.selectedStationIds ?? const <String>{},
                )
              else if (widget.stations.length >=
                  StationMapGeometry.clusterThreshold)
                countClusterLayer(markers: _markers, theme: theme)
              else
                MarkerLayer(markers: _markers),
            // Extra layers (e.g. EV overlay)
            ...widget.extraLayers,
            // Attribution — localized OSM credit (#2402).
            const OsmAttribution(),
          ],
        ),
        // Zoom controls — #3002: hidden on the driving map, which has its own
        // oversized bottom bar.
        if (widget.showZoomControls)
          MapZoomControls(
            mapController: widget.mapController,
            center: widget.center,
            zoom: widget.zoom,
            showRecenterButton: widget.showRecenterButton,
            onRecenter: widget.onRecenter,
          ),
        // Price legend — #3002: hidden on the driving map so it never sits
        // under the oversized driving bottom bar.
        if (widget.showLegend)
          const Positioned(
            left: 16,
            bottom: 16,
            child: PriceLegend(),
          ),
      ],
    );
  }
}
