// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../data/sparkilo_tile_layer.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/widgets/osm_attribution.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'price_legend.dart';
import 'station_marker.dart';

/// Camera zoom bounds (#1457). Top end matches the OSM tile cap so a
/// `move(camera.zoom + 1)` past the cap doesn't park the user on a
/// grey viewport with no tiles to draw. Bottom end is conservative —
/// flutter_map wraps the world at zoom 0, but anything below ~3 puts
/// every pin in a single pixel which is unhelpful UX.
const double _kMinZoom = 3.0;
const double _kMaxZoom = 19.0;

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
  final bool showRecenterButton;
  final VoidCallback? onRecenter;
  final List<LatLng>? routePolyline;
  final bool showSearchRadius;

  /// When non-null, stations NOT in this set are rendered in pastel.
  /// Stations IN this set use vivid/flashy colors for quick identification.
  final Set<String>? selectedStationIds;

  /// Additional map layers rendered after the station markers, e.g. the
  /// EV charging station overlay.
  final List<Widget> extraLayers;

  const StationMapLayers({
    super.key,
    required this.mapController,
    required this.stations,
    required this.center,
    required this.zoom,
    required this.searchRadiusKm,
    required this.selectedFuel,
    this.showRecenterButton = false,
    this.onRecenter,
    this.routePolyline,
    this.showSearchRadius = true,
    this.selectedStationIds,
    this.extraLayers = const [],
  });

  @override
  State<StationMapLayers> createState() => _StationMapLayersState();

  /// Camera zoom bounds for the +/− button handlers + the [MapOptions]
  /// camera constraints. Aligned with the OSM tile cap (`maxNativeZoom: 19`)
  /// so a programmatic zoom-in past the cap doesn't park the camera at
  /// a level with no tiles to render. The min is conservative — flutter_map
  /// itself wraps the world at zoom 0, but anything below ~3 puts every
  /// pin in a single pixel, which is unhelpful UX. Per #1457.
  @visibleForTesting
  static const double minZoom = _kMinZoom;
  @visibleForTesting
  static const double maxZoom = _kMaxZoom;

  /// Calculate zoom level from search radius.
  static double zoomForRadius(double radiusKm) {
    if (radiusKm <= 5) return 13;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 15) return 11;
    if (radiusKm <= 25) return 10;
    return 9;
  }

  /// Compute the [LatLngBounds] of a circle of [radiusKm] around [center].
  ///
  /// Uses a flat-earth approximation that is accurate enough for the
  /// search radii we deal with (< 100 km). 1 degree latitude is ~111 km;
  /// the longitude degree shrinks with the cosine of the latitude.
  static LatLngBounds boundsForRadius(LatLng center, double radiusKm) {
    const double kmPerLatDegree = 111.0;
    final double latDelta = radiusKm / kmPerLatDegree;
    final double cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    // Guard against the poles where cos(lat) approaches zero.
    final double safeCos = cosLat < 0.01 ? 0.01 : cosLat;
    final double lngDelta = radiusKm / (kmPerLatDegree * safeCos);
    final double south = (center.latitude - latDelta).clamp(-90.0, 90.0);
    final double north = (center.latitude + latDelta).clamp(-90.0, 90.0);
    final double west = (center.longitude - lngDelta).clamp(-180.0, 180.0);
    final double east = (center.longitude + lngDelta).clamp(-180.0, 180.0);
    return LatLngBounds(
      LatLng(south, west),
      LatLng(north, east),
    );
  }

  /// Calculate center point from a list of stations.
  static LatLng centerOf(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

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

  /// Bounds of the search circle around the current centre — the camera
  /// target for both `initialCameraFit` and the post-ready re-fit.
  LatLngBounds get _fitBounds =>
      StationMapLayers.boundsForRadius(widget.center, widget.searchRadiusKm);

  /// Recompute the memoised price range + marker list from the current
  /// widget inputs.
  void _recomputeMarkers() {
    // #2400 — colour by the RESOLVED display price (selected fuel, else
    // fallback) so a fallback-priced marker is coloured by the value it
    // actually shows rather than appearing grey because the selected
    // fuel was null.
    _priceRange = resolvedPriceRange(widget.stations, widget.selectedFuel);
    final ids = widget.selectedStationIds;
    final hasSelection = ids != null && ids.isNotEmpty;
    _markers = widget.stations.map((station) {
      final isPastel = hasSelection && !ids.contains(station.id);
      return StationMarkerBuilder.build(
        context,
        station,
        widget.selectedFuel,
        _priceRange.$1,
        _priceRange.$2,
        pastel: isPastel,
      );
    }).toList();
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
            // #2399 — frame the search circle during the FIRST layout
            // pass, not via a post-frame `fitCamera`. The old post-frame
            // fit raced the (now-deleted) cold-start reset window and
            // could land on a degenerate viewport. Positioning the
            // camera as part of layout means the very first tile fetch
            // already targets the right viewport — no reset needed.
            initialCameraFit: CameraFit.bounds(
              bounds:
                  StationMapLayers.boundsForRadius(
                      widget.center, widget.searchRadiusKm),
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
            minZoom: _kMinZoom,
            maxZoom: _kMaxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
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
            // Station markers with clustering. #1774 — `_markers` is
            // memoised; this builder just places the pre-built list.
            Builder(builder: (ctx) {
              final markers = _markers;
              if (widget.stations.length > 20) {
                return MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    markers: markers,
                    builder: (context, clusterMarkers) => Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return MarkerLayer(markers: markers);
            }),
            // Extra layers (e.g. EV overlay)
            ...widget.extraLayers,
            // Attribution — localized OSM credit (#2402).
            const OsmAttribution(),
          ],
        ),
        // Zoom controls
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              ZoomButton(
                icon: Icons.add,
                onPressed: () {
                  // #1457 — clamp to [_kMinZoom, _kMaxZoom]. Without
                  // the clamp, a + tap at the cap silently no-ops AND
                  // pushes the camera to a zoom level with no tiles
                  // (the user sees a grey screen and assumes the button
                  // is broken). The clamp turns it into a graceful
                  // no-op AT the cap — the visible feedback is "I'm
                  // already at max zoom" instead of "the button is
                  // dead".
                  final z = (widget.mapController.camera.zoom + 1)
                      .clamp(_kMinZoom, _kMaxZoom);
                  widget.mapController
                      .move(widget.mapController.camera.center, z);
                },
              ),
              const SizedBox(height: 8),
              ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final z = (widget.mapController.camera.zoom - 1)
                      .clamp(_kMinZoom, _kMaxZoom);
                  widget.mapController
                      .move(widget.mapController.camera.center, z);
                },
              ),
              if (widget.showRecenterButton) ...[
                const SizedBox(height: 8),
                ZoomButton(
                  icon: Icons.my_location,
                  onPressed: widget.onRecenter ??
                      () => widget.mapController
                          .move(widget.center, widget.zoom),
                ),
              ],
            ],
          ),
        ),
        // Price legend
        const Positioned(
          left: 16,
          bottom: 16,
          child: PriceLegend(),
        ),
      ],
    );
  }
}
