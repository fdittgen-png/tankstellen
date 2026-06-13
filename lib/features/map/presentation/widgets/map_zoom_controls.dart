// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'price_legend.dart' show ZoomButton;
import 'station_map_geometry.dart';

/// #3233 — the top-right zoom / recenter control column extracted out of
/// [StationMapLayers.build]. A [Positioned] so it drops straight into the map
/// [Stack]; rendered only when the host enables zoom controls (the driving map
/// hides it behind its own oversized bottom bar, #3002).
class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.mapController,
    required this.center,
    required this.zoom,
    this.showRecenterButton = false,
    this.onRecenter,
  });

  final MapController mapController;
  final LatLng center;
  final double zoom;
  final bool showRecenterButton;
  final VoidCallback? onRecenter;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        children: [
          ZoomButton(
            icon: Icons.add,
            onPressed: () {
              // #1457 — clamp to [StationMapGeometry.minZoom,
              // StationMapGeometry.maxZoom]. Without the clamp, a + tap at the
              // cap silently no-ops AND pushes the camera to a zoom level with
              // no tiles (the user sees a grey screen and assumes the button is
              // broken). The clamp turns it into a graceful no-op AT the cap —
              // the visible feedback is "I'm already at max zoom" instead of
              // "the button is dead".
              final z = (mapController.camera.zoom + 1)
                  .clamp(StationMapGeometry.minZoom, StationMapGeometry.maxZoom);
              mapController.move(mapController.camera.center, z);
            },
          ),
          const SizedBox(height: 8),
          ZoomButton(
            icon: Icons.remove,
            onPressed: () {
              final z = (mapController.camera.zoom - 1)
                  .clamp(StationMapGeometry.minZoom, StationMapGeometry.maxZoom);
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
    );
  }
}
