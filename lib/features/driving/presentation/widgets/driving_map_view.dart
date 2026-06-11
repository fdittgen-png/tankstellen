// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../map/data/sparkilo_tile_layer.dart';
import '../../../map/presentation/widgets/station_map_layers.dart';
import '../../../map/presentation/widgets/station_marker.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';

/// Full-screen map for driving mode. #3002 (Epic #2997) — driving now renders
/// on the SHARED [StationMapLayers] stack (the same price-band colours +
/// marker grammar as every other map), but with the big, driver-legible
/// marker variant ([StationMarkerVariant.driving]) and NO clustering: driving
/// shows few stations and needs an immediate tap-to-open-sheet with restricted
/// gestures. The bespoke `DrivingMarkerBuilder` + its `_drivingStops` palette
/// are gone — driving folds onto the ONE canonical `PriceBandColors.ramp`.
///
/// Driving keeps its restricted gestures (drag | fling | double-tap-zoom, no
/// pinch), its [onInteraction] auto-lock reset (on a background tap), and maps
/// a marker tap to [onMarkerTap] (which opens the `DrivingStationSheet`) — not
/// a navigation push. The zoom controls + price legend are suppressed because
/// driving owns its own oversized bottom bar.
///
/// When [stations] is empty the map falls back to a default Berlin view so the
/// screen still has a tile background while the search loads.
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

  /// Restricted driving gestures: pan + fling + double-tap-zoom, but never the
  /// two-finger pinch/rotate a driver can't safely perform at the wheel.
  static const _drivingInteraction = InteractionOptions(
    flags: InteractiveFlag.drag |
        InteractiveFlag.flingAnimation |
        InteractiveFlag.doubleTapZoom,
  );

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
  /// when no station has a price. Delegates to the shared [priceRange]
  /// helper (#2182) — accepts any non-null price, as before.
  static (double, double) computePriceRange(
    List<Station> stations,
    FuelType fuel,
  ) =>
      priceRange(stations, fuel);

  /// The [LatLngBounds] framing all [stations]. A single station gets a tiny
  /// epsilon box so `CameraFit.bounds` cannot divide-by-zero (mirrors
  /// `InlineMap._boundsOf` / `RouteMapView._computeRouteBounds`).
  static LatLngBounds _boundsOf(List<Station> stations) {
    final points = [for (final s in stations) LatLng(s.lat, s.lng)];
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

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) {
      return FlutterMap(
        mapController: mapController,
        options: const MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 12,
          interactionOptions: _drivingInteraction,
        ),
        // #2096 — the hardened tile wrapper, not a raw TileLayer.
        children: const [SparkiloTileLayer()],
      );
    }

    final center = computeCenter(stations);
    return StationMapLayers(
      mapController: mapController,
      stations: stations,
      center: center,
      zoom: 13,
      // Driving has no search-radius circle; frame the actual station bounds.
      searchRadiusKm: 0,
      showSearchRadius: false,
      cameraFitBounds: _boundsOf(stations),
      selectedFuel: selectedFuel,
      // The big, driver-legible card (brand + tier icon + large price).
      markerVariant: StationMarkerVariant.driving,
      // Driving shows few stations and needs immediate tap-to-open-sheet.
      clusterAlways: false,
      // Restricted gestures + the auto-lock reset on a background tap.
      interactionOptions: _drivingInteraction,
      onMapTap: onInteraction,
      // Driving owns its own oversized bottom bar, so suppress the overlay
      // chrome the other maps carry.
      showZoomControls: false,
      showLegend: false,
      // A marker tap resets the lock timer and opens the DrivingStationSheet —
      // never a navigation push.
      onStationTap: (id) {
        onInteraction();
        final station = stations.firstWhere((s) => s.id == id);
        onMarkerTap(station);
      },
    );
  }
}
