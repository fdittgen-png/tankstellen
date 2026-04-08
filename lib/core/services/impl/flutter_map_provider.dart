import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../constants/app_constants.dart';
import '../map_provider.dart';

/// Default [MapProvider] implementation backed by flutter_map + OSM tiles.
///
/// This is the only implementation shipped today. The abstraction exists
/// so that a Google Maps (or other) provider can be plugged in later
/// without touching the feature-level map widgets.
class FlutterMapProvider implements MapProvider {
  const FlutterMapProvider();

  @override
  String get name => 'OpenStreetMap';

  @override
  TileLayerConfig get tileConfig => const TileLayerConfig(
        urlTemplate: AppConstants.osmTileUrl,
        userAgent: AppConstants.osmUserAgent,
        attribution: AppConstants.osmAttribution,
      );

  @override
  Widget buildMapWidget({
    required dynamic controller,
    required LatLng initialCenter,
    required double initialZoom,
    required List<Widget> children,
  }) {
    return FlutterMap(
      mapController: controller as MapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: children,
    );
  }

  @override
  Widget buildTileLayer() {
    final config = tileConfig;
    return TileLayer(
      urlTemplate: config.urlTemplate,
      userAgentPackageName: config.userAgent ?? '',
    );
  }

  @override
  Widget buildMarkerLayer({
    required List<MapMarkerConfig> markers,
    required bool cluster,
    Widget Function(BuildContext context, int markerCount)? clusterBuilder,
  }) {
    final flutterMapMarkers = markers
        .map((m) => Marker(
              point: m.point,
              width: m.width,
              height: m.height,
              child: m.child,
            ))
        .toList();

    if (cluster && markers.length > 20) {
      return MarkerClusterLayerWidget(
        options: MarkerClusterLayerOptions(
          maxClusterRadius: 80,
          markers: flutterMapMarkers,
          builder: (context, clusterMarkers) {
            if (clusterBuilder != null) {
              return clusterBuilder(context, clusterMarkers.length);
            }
            return _defaultClusterWidget(context, clusterMarkers.length);
          },
        ),
      );
    }

    return MarkerLayer(markers: flutterMapMarkers);
  }

  @override
  Widget buildPolylineLayer({required List<MapPolylineConfig> polylines}) {
    return PolylineLayer(
      polylines: polylines
          .map((p) => Polyline(
                points: p.points,
                color: p.color,
                strokeWidth: p.strokeWidth,
              ))
          .toList(),
    );
  }

  @override
  Widget buildCircleLayer({required List<MapCircleConfig> circles}) {
    return CircleLayer(
      circles: circles
          .map((c) => CircleMarker(
                point: c.center,
                radius: c.radiusMeters,
                useRadiusInMeter: true,
                color: c.fillColor,
                borderColor: c.borderColor,
                borderStrokeWidth: c.borderStrokeWidth,
              ))
          .toList(),
    );
  }

  @override
  Widget buildAttribution() {
    return const RichAttributionWidget(
      attributions: [
        TextSourceAttribution('OpenStreetMap contributors'),
      ],
    );
  }

  @override
  dynamic createController() => MapController();

  @override
  void disposeController(dynamic controller) {
    (controller as MapController).dispose();
  }

  @override
  void move(dynamic controller, LatLng center, double zoom) {
    (controller as MapController).move(center, zoom);
  }

  @override
  double getZoom(dynamic controller) {
    return (controller as MapController).camera.zoom;
  }

  @override
  LatLng getCenter(dynamic controller) {
    return (controller as MapController).camera.center;
  }

  Widget _defaultClusterWidget(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
