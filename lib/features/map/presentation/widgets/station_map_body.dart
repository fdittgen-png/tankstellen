// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/sparkilo_tile_layer.dart';
import '../../../../core/widgets/osm_attribution.dart';
import 'station_cluster_layers.dart';
import 'station_map_geometry.dart';

/// #3233 — the [FlutterMap] layer tree extracted out of [StationMapLayers]'s
/// build as a pure presentational widget. It owns NO state: the parent
/// computes the memoised marker model ([markers] / [markerMeta] /
/// [priceRange]) and the camera [fitBounds], and threads its `_mapReady`
/// latch through [onMapReady]. This leaves [StationMapLayers] holding only the
/// memoisation + the camera-fit lifecycle, below the file-length cap.
///
/// The hardened single tile path ([SparkiloTileLayer]), the route polyline,
/// the search-radius circle, the centre marker, the four marker-clustering
/// modes and the OSM attribution all live here, byte-identical to the inline
/// tree they replaced.
class StationMapBody extends StatelessWidget {
  const StationMapBody({
    super.key,
    required this.mapController,
    required this.center,
    required this.zoom,
    required this.fitBounds,
    required this.onMapReady,
    required this.interactionOptions,
    required this.onMapTap,
    required this.routePolyline,
    required this.showSearchRadius,
    required this.searchRadiusKm,
    required this.markers,
    required this.markerMeta,
    required this.priceRange,
    required this.clusterAlways,
    required this.excludeSelectedFromClustering,
    required this.selectedStationIds,
    required this.stationCount,
    required this.extraLayers,
  });

  final MapController mapController;
  final LatLng center;
  final double zoom;
  final LatLngBounds fitBounds;
  final VoidCallback onMapReady;
  final InteractionOptions? interactionOptions;
  final void Function()? onMapTap;
  final List<LatLng>? routePolyline;
  final bool showSearchRadius;
  final double searchRadiusKm;
  final List<Marker> markers;
  final Map<Marker, MarkerMeta> markerMeta;
  final (double, double) priceRange;
  final bool clusterAlways;
  final bool excludeSelectedFromClustering;
  final Set<String>? selectedStationIds;

  /// The raw station count, used only to pick the legacy count-cluster mode
  /// at [StationMapGeometry.clusterThreshold].
  final int stationCount;
  final List<Widget> extraLayers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        // #2399 — frame the camera target during the FIRST layout pass, not
        // via a post-frame `fitCamera`. The old post-frame fit raced the
        // (now-deleted) cold-start reset window and could land on a degenerate
        // viewport. Positioning the camera as part of layout means the very
        // first tile fetch already targets the right viewport — no reset
        // needed. #2755 — [fitBounds] is the explicit cameraFitBounds (route
        // mode: the full itinerary) when supplied by the parent, else the
        // search circle (nearby mode, unchanged).
        initialCameraFit: CameraFit.bounds(
          bounds: fitBounds,
          padding: const EdgeInsets.all(32),
        ),
        // #2399 — keep the FlutterMap (and its loaded tiles) alive when
        // offstage in an IndexedStack so a tab flip back to the map doesn't
        // tear down + cold-rebuild the tile pipeline.
        keepAlive: true,
        onMapReady: onMapReady,
        // #1457 — clamp the camera to the tile-layer's max zoom (19) so a
        // programmatic `move(camera.zoom + 1)` past 19 doesn't leave the user
        // staring at a grey viewport (tiles only render up to maxNativeZoom).
        minZoom: StationMapGeometry.minZoom,
        maxZoom: StationMapGeometry.maxZoom,
        // #3002 — the DRIVING map passes its restricted gesture set (no pinch);
        // every other map keeps the default all-gestures option.
        interactionOptions: interactionOptions ??
            const InteractionOptions(flags: InteractiveFlag.all),
        // #3002 — driving wires a background-tap to its auto-lock reset.
        onTap: onMapTap == null ? null : (_, _) => onMapTap!(),
      ),
      children: [
        // #2398 — the SINGLE hardened tile path. No inline TileLayer, no reset
        // stream: the cold-start reset storm that evicted tiles before they
        // painted is gone. `SparkiloTileLayer` owns its retry provider
        // lifecycle and uses the upstream default `abortObsoleteRequests: true`,
        // unified with every other map surface.
        const SparkiloTileLayer(key: ValueKey('main-tiles')),
        // Route polyline (if in route search mode)
        if (routePolyline != null && routePolyline!.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePolyline!,
                color: theme.colorScheme.primary,
                strokeWidth: 4.0,
              ),
            ],
          ),
        // Search radius circle
        if (showSearchRadius)
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                radius: searchRadiusKm * 1000,
                useRadiusInMeter: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),
        // Center marker
        MarkerLayer(
          markers: [
            Marker(
              point: center,
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
        // Station markers (#1774 — `markers` is memoised by the parent). Modes:
        //  - #3000 `clusterAlways` + `excludeSelectedFromClustering` (route
        //    map): SELECTED stations stay un-clustered as full pills on top,
        //    the rest fold into the cheapest cluster — so the Best/All
        //    multi-select + list↔map 1:1 survive;
        //  - #2939 `clusterAlways` (radar / Nearby): proximity-cluster EVERY
        //    set with the cheapest-labelled badge;
        //  - legacy huge set (≥ clusterThreshold): bare count cluster;
        //  - legacy bounded set (#2510): plain [MarkerLayer], emphasis.
        if (markers.isNotEmpty)
          if (clusterAlways && excludeSelectedFromClustering)
            ...selectionPartitionedClusterLayers(
              markers: markers,
              metaOf: (m) => markerMeta[m],
              priceRange: priceRange,
              selectedIds: selectedStationIds ?? const <String>{},
            )
          else if (clusterAlways)
            cheapestLabelledClusterLayer(
              markers: markers,
              metaOf: (m) => markerMeta[m],
              priceRange: priceRange,
              selectedIds: selectedStationIds ?? const <String>{},
            )
          else if (stationCount >= StationMapGeometry.clusterThreshold)
            countClusterLayer(markers: markers, theme: theme)
          else
            MarkerLayer(markers: markers),
        // Extra layers (e.g. EV overlay)
        ...extraLayers,
        // Attribution — localized OSM credit (#2402).
        const OsmAttribution(),
      ],
    );
  }
}
