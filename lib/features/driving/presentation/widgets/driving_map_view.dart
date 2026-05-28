// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../map/data/sparkilo_tile_layer.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'driving_marker_builder.dart';

/// Full-screen map for driving mode. Renders the station markers with the
/// oversized driving-mode style and forwards user gestures to [onInteraction].
///
/// When [stations] is empty the map falls back to a default Berlin view so
/// the screen still has a tile background while the search loads.
class DrivingMapView extends StatefulWidget {
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
  State<DrivingMapView> createState() => _DrivingMapViewState();

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
}

class _DrivingMapViewState extends State<DrivingMapView> {
  // #2176 — centroid, price range and the oversized markers are memoised
  // here and recomputed only when the station list identity or the
  // selected fuel changes (mirrors StationMapLayers #1774). The driving
  // screen rebuilds on a 30 s auto-lock setState; without this it
  // re-ran two O(n) passes + re-allocated every marker each time.
  LatLng? _center;
  List<Marker> _markers = const [];

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(DrivingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stations, widget.stations) ||
        oldWidget.selectedFuel != widget.selectedFuel) {
      _recompute();
    }
  }

  void _recompute() {
    final stations = widget.stations;
    if (stations.isEmpty) {
      _center = null;
      _markers = const [];
      return;
    }
    _center = DrivingMapView.computeCenter(stations);
    final range = DrivingMapView.computePriceRange(stations, widget.selectedFuel);
    _markers = stations
        .map(
          (station) => DrivingMarkerBuilder.build(
            station,
            widget.selectedFuel,
            range.$1,
            range.$2,
            // Read the callbacks off `widget` at tap time so a memoised
            // marker still dispatches to the current handlers.
            onTap: () {
              widget.onInteraction();
              widget.onMarkerTap(station);
            },
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) {
      return FlutterMap(
        mapController: widget.mapController,
        options: const MapOptions(
          initialCenter: DrivingMapView._defaultCenter,
          initialZoom: 12,
        ),
        children: const [
          // #2096 — was a raw TileLayer; routed through the
          // hardened wrapper.
          SparkiloTileLayer(),
        ],
      );
    }

    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: _center!,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.doubleTapZoom,
        ),
        onTap: (_, _) => widget.onInteraction(),
      ),
      children: [
        // #2096 — was a raw TileLayer; routed through the hardened
        // wrapper.
        const SparkiloTileLayer(),
        MarkerLayer(markers: _markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}
