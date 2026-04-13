import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'driving_marker_builder.dart';

/// Full-screen map for driving mode. Renders the station markers with the
/// oversized driving-mode style and forwards user gestures to [onInteraction].
///
/// When [stations] is empty the map falls back to a default Berlin view so
/// the screen still has a tile background while the search loads.
class DrivingMapView extends StatelessWidget {
  final MapController mapController;
  final List<Station> stations;
  final FuelType selectedFuel;
  final void Function(Station station) onMarkerTap;
  final VoidCallback onInteraction;

  const DrivingMapView({
    super.key,
    required this.mapController,
    required this.stations,
    required this.selectedFuel,
    required this.onMarkerTap,
    required this.onInteraction,
  });

  static const _defaultCenter = LatLng(52.52, 13.405);

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return FlutterMap(
        mapController: mapController,
        options: const MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.osmTileUrl,
            userAgentPackageName: AppConstants.osmUserAgent,
          ),
        ],
      );
    }

    final center = computeCenter(stations);
    final priceRange = computePriceRange(stations, selectedFuel);

    final markers = stations.map((station) {
      return DrivingMarkerBuilder.build(
        station,
        selectedFuel,
        priceRange.$1,
        priceRange.$2,
        onTap: () {
          onInteraction();
          onMarkerTap(station);
        },
      );
    }).toList();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.doubleTapZoom,
        ),
        onTap: (_, _) => onInteraction(),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: AppConstants.osmUserAgent,
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  /// Geographic centroid of the given stations.
  static LatLng computeCenter(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

  /// (min, max) price for [fuel] across the given stations. Returns (0, 0)
  /// when no station has a price.
  static (double, double) computePriceRange(
    List<Station> stations,
    FuelType fuel,
  ) {
    double minP = double.infinity;
    double maxP = 0;
    for (final s in stations) {
      final p = priceForFuelType(s, fuel);
      if (p != null) {
        if (p < minP) minP = p;
        if (p > maxP) maxP = p;
      }
    }
    if (minP == double.infinity) return (0, 0);
    return (minP, maxP);
  }
}
