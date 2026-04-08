import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Configuration for a map tile layer.
///
/// Abstracts the tile URL template and attribution so that
/// different map backends (OSM, Google, Mapbox, etc.) can
/// provide their own tile sources.
class TileLayerConfig {
  /// URL template with `{z}`, `{x}`, `{y}` placeholders.
  final String urlTemplate;

  /// User-Agent sent with tile requests (required by some providers).
  final String? userAgent;

  /// Human-readable attribution text for the tile source.
  final String attribution;

  const TileLayerConfig({
    required this.urlTemplate,
    this.userAgent,
    required this.attribution,
  });
}

/// Configuration for a single map marker.
///
/// Provides a platform-agnostic marker description that
/// each [MapProvider] implementation converts into its own marker type.
class MapMarkerConfig {
  final LatLng point;
  final double width;
  final double height;
  final Widget child;

  const MapMarkerConfig({
    required this.point,
    required this.width,
    required this.height,
    required this.child,
  });
}

/// Configuration for displaying a polyline on the map.
class MapPolylineConfig {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const MapPolylineConfig({
    required this.points,
    required this.color,
    this.strokeWidth = 4.0,
  });
}

/// Configuration for displaying a circle overlay on the map.
class MapCircleConfig {
  final LatLng center;

  /// Radius in meters.
  final double radiusMeters;
  final Color fillColor;
  final Color borderColor;
  final double borderStrokeWidth;

  const MapCircleConfig({
    required this.center,
    required this.radiusMeters,
    required this.fillColor,
    required this.borderColor,
    this.borderStrokeWidth = 2.0,
  });
}

/// Abstract interface for map rendering backends.
///
/// Allows swapping the underlying map library (flutter_map, Google Maps,
/// Mapbox, etc.) without changing the feature-level map code.
///
/// The default implementation wraps flutter_map + OpenStreetMap tiles.
abstract class MapProvider {
  /// Human-readable name of this map backend (e.g. "OpenStreetMap").
  String get name;

  /// Returns the tile layer configuration for this provider.
  TileLayerConfig get tileConfig;

  /// Builds a complete, interactive map widget.
  ///
  /// The [controller] handle is provider-specific; callers obtain it
  /// from [createController]. The [children] list contains layer widgets
  /// (tiles, markers, polylines) that the implementation should render
  /// on top of the base map.
  Widget buildMapWidget({
    required dynamic controller,
    required LatLng initialCenter,
    required double initialZoom,
    required List<Widget> children,
  });

  /// Builds a tile layer widget for this provider.
  Widget buildTileLayer();

  /// Builds a marker layer widget from a list of [MapMarkerConfig]s.
  ///
  /// When [cluster] is true and the implementation supports it,
  /// markers should be clustered for dense areas.
  Widget buildMarkerLayer({
    required List<MapMarkerConfig> markers,
    required bool cluster,
    Widget Function(BuildContext context, int markerCount)? clusterBuilder,
  });

  /// Builds a polyline layer widget.
  Widget buildPolylineLayer({required List<MapPolylineConfig> polylines});

  /// Builds a circle layer widget.
  Widget buildCircleLayer({required List<MapCircleConfig> circles});

  /// Builds an attribution widget for the map tiles.
  Widget buildAttribution();

  /// Creates a new map controller handle.
  ///
  /// The returned object is implementation-specific (e.g. flutter_map's
  /// [MapController]). Callers should treat it as opaque and pass it
  /// back to [buildMapWidget] and [move].
  dynamic createController();

  /// Disposes a previously created controller.
  void disposeController(dynamic controller);

  /// Moves the map to the given [center] at [zoom] level.
  void move(dynamic controller, LatLng center, double zoom);

  /// Returns the current zoom level from the controller.
  double getZoom(dynamic controller);

  /// Returns the current center from the controller.
  LatLng getCenter(dynamic controller);
}
