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

  /// A finite fallback camera centre (Paris) when there is nothing sane to
  /// frame — mirrors the map feature's own fallback (#3488). Kept local so
  /// this feature stays self-contained (no cross-feature import).
  static const LatLng _fallbackCenter = LatLng(48.8566, 2.3522);

  /// Half-width (~50 m) of the epsilon box padded around a degenerate,
  /// zero-span bounds so `CameraFit.bounds` never computes an infinite
  /// fit-zoom (which projects to `LatLng(NaN, NaN)` and throws on every
  /// tile update — #3488).
  static const double _boundsEpsilon = 0.0005;

  /// Geographic centroid of the given stations. #3488 — NaN-safe: stations
  /// with non-finite coords are skipped and an empty / all-non-finite input
  /// returns [_fallbackCenter] rather than `0/0 = NaN`, so a
  /// `LatLng(NaN, NaN)` never reaches the camera and freezes the map.
  static LatLng computeCenter(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    var count = 0;
    for (final s in stations) {
      if (!s.lat.isFinite || !s.lng.isFinite) continue;
      sumLat += s.lat;
      sumLng += s.lng;
      count++;
    }
    if (count == 0) return _fallbackCenter;
    return LatLng(sumLat / count, sumLng / count);
  }

  /// (min, max) price for [fuel] across the given stations. Returns (0, 0)
  /// when no station has a price. Delegates to the shared [priceRange]
  /// helper (#2182) — accepts any non-null price, as before.
  static (double, double) computePriceRange(
    List<Station> stations,
    FuelType fuel,
  ) =>
      priceRange(stations, fuel);

  /// The [LatLngBounds] framing all [stations]. #3488 — drops non-finite
  /// coords and epsilon-pads any near-zero span (a single station OR several
  /// co-located / duplicate ones — the field trigger) so `CameraFit.bounds`
  /// cannot compute an infinite fit-zoom → `LatLng(NaN, NaN)` camera.
  static LatLngBounds _boundsOf(List<Station> stations) {
    double? minLat, maxLat, minLng, maxLng;
    for (final s in stations) {
      if (!s.lat.isFinite || !s.lng.isFinite) continue;
      minLat = (minLat == null) ? s.lat : (s.lat < minLat ? s.lat : minLat);
      maxLat = (maxLat == null) ? s.lat : (s.lat > maxLat ? s.lat : maxLat);
      minLng = (minLng == null) ? s.lng : (s.lng < minLng ? s.lng : minLng);
      maxLng = (maxLng == null) ? s.lng : (s.lng > maxLng ? s.lng : maxLng);
    }
    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      minLat = _fallbackCenter.latitude;
      maxLat = _fallbackCenter.latitude;
      minLng = _fallbackCenter.longitude;
      maxLng = _fallbackCenter.longitude;
    }
    if (maxLat - minLat < _boundsEpsilon) {
      minLat -= _boundsEpsilon;
      maxLat += _boundsEpsilon;
    }
    if (maxLng - minLng < _boundsEpsilon) {
      minLng -= _boundsEpsilon;
      maxLng += _boundsEpsilon;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
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
