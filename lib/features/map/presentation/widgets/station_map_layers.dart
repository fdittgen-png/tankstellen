import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'price_legend.dart';
import 'station_marker.dart';

/// Shared map widget containing all layers: tiles, search radius circle,
/// center marker, station markers with clustering, attribution, zoom
/// controls, and price legend.
///
/// Used by both [MapScreen] (full-screen) and [InlineMap] (split-screen)
/// to eliminate ~130 lines of duplicated map layer code.
class StationMapLayers extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceRange = _getPriceRange(stations, selectedFuel);

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            // #496 — force the TileLayer to refetch tiles once the map
            // has actually laid out. When the map screen sits inside
            // StatefulShellRoute.indexedStack, the widget is pre-built
            // offstage with degenerate constraints and the TileLayer's
            // viewport is empty. The initState-based nudge in
            // MapScreen fires before FlutterMap attaches the controller,
            // so it gets swallowed. onMapReady fires exactly when the
            // controller is attached AND the map has real constraints,
            // which is the only reliable moment to nudge.
            onMapReady: () {
              // Zoom-jiggle: tiny delta then revert so the TileLayer's
              // `_TileBoundsAtZoom` invalidates its cached-empty viewport
              // and re-requests tiles (#709). A same-center/same-zoom
              // move is a no-op and kept the blank viewport on first
              // load.
              try {
                mapController.move(center, zoom + 0.0001);
                mapController.move(center, zoom);
              } catch (e) {
                debugPrint('StationMapLayers onMapReady nudge: $e');
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
              maxNativeZoom: 19,
              maxZoom: 19,
              // #757 — kill the persistent-gray-tile bug at its root.
              // Default NetworkTileProvider caches failed fetches in
              // TileImageManager and the same (z,x,y) is never
              // re-requested even on redraw, so a single transient
              // 429/503 from the OSM tile server leaves a permanent
              // gray square in the user's viewport. With
              // `notVisibleRespectMargin`, the failed tile is
              // evicted as soon as it scrolls out of the keepBuffer
              // margin — the next pan retries cleanly. Every prior
              // map-bug PR (#496, #532, #696, #707, #709, #711)
              // attacked symptoms; this is the root cause.
              evictErrorTileStrategy:
                  EvictErrorTileStrategy.notVisibleRespectMargin,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint(
                    'TileLayer error at (z:${tile.coordinates.z} '
                    'x:${tile.coordinates.x} y:${tile.coordinates.y}): '
                    '$error');
              },
            ),
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
            // Station markers with clustering
            Builder(builder: (ctx) {
              final hasSelection = selectedStationIds != null && selectedStationIds!.isNotEmpty;
              final markers = stations.map((station) {
                final isPastel = hasSelection && !selectedStationIds!.contains(station.id);
                return StationMarkerBuilder.build(
                  ctx, station, selectedFuel,
                  priceRange.$1, priceRange.$2,
                  pastel: isPastel,
                );
              }).toList();
              if (stations.length > 20) {
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
            ...extraLayers,
            // Attribution
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
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
                  final z = mapController.camera.zoom + 1;
                  mapController.move(mapController.camera.center, z);
                },
              ),
              const SizedBox(height: 8),
              ZoomButton(
                icon: Icons.remove,
                onPressed: () {
                  final z = mapController.camera.zoom - 1;
                  mapController.move(mapController.camera.center, z);
                },
              ),
              if (showRecenterButton) ...[
                const SizedBox(height: 8),
                ZoomButton(
                  icon: Icons.my_location,
                  onPressed: onRecenter ?? () => mapController.move(center, zoom),
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

  /// Get min/max price range for color gradient.
  static (double, double) _getPriceRange(List<Station> stations, FuelType fuel) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = s.priceFor(fuel);
      if (p != null) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    if (minP == double.infinity) return (0, 0);
    return (minP, maxP);
  }
}
