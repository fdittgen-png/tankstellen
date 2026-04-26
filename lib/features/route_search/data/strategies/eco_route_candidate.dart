import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart' as geo;
import '../../domain/entities/route_info.dart';

/// A single OSRM alternative (or any candidate route) scored by the
/// eco strategy. Bundles the raw OSRM-derived metrics we need to
/// compute `time + α × elevation + β × speed_variance_penalty`.
///
/// `elevationGainMeters` is null when OSRM did not return an
/// elevation profile (the public demo server typically doesn't).
/// In that case `EcoRouteSearchStrategy.scoreCandidate` falls back
/// to time + speed-variance only — see the strategy's class docs.
@immutable
class EcoRouteCandidate {
  const EcoRouteCandidate({
    required this.geometry,
    required this.distanceKm,
    required this.durationMinutes,
    this.elevationGainMeters,
    this.legSpeedsKmh = const <double>[],
  });

  final List<LatLng> geometry;
  final double distanceKm;
  final double durationMinutes;

  /// Total positive elevation gain along the candidate, in metres.
  /// Null when the OSRM response carries no elevation data.
  final double? elevationGainMeters;

  /// Per-leg average speed in km/h. Used to compute a speed-variance
  /// penalty: routes that mix highway + slow stretches burn more
  /// fuel than a flat-cruise highway-only route. Empty list means
  /// "we couldn't sample legs" and the variance penalty is 0.
  final List<double> legSpeedsKmh;

  /// Convert to the public `RouteInfo` shape, sampling every ~15 km
  /// for downstream station-along-route queries (mirrors
  /// `RoutingService._sampleAlongPolyline`).
  RouteInfo toRouteInfo() {
    final samples = sampleAlongPolyline(geometry, 15.0);
    return RouteInfo(
      geometry: geometry,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      samplePoints: samples,
    );
  }
}

/// Sample a polyline at roughly [intervalKm] spacing, always
/// including the first and last points. Mirrors the heuristic used
/// by `RoutingService._sampleAlongPolyline` — kept as a top-level
/// helper so eco-specific tests can exercise the sampling logic
/// without instantiating an [EcoRouteCandidate].
@visibleForTesting
List<LatLng> sampleAlongPolyline(
  List<LatLng> polyline,
  double intervalKm,
) {
  if (polyline.isEmpty) return const <LatLng>[];
  final samples = <LatLng>[polyline.first];
  double accumulated = 0;
  for (var i = 1; i < polyline.length; i++) {
    final prev = polyline[i - 1];
    final curr = polyline[i];
    accumulated += geo.distanceKm(
      prev.latitude,
      prev.longitude,
      curr.latitude,
      curr.longitude,
    );
    if (accumulated >= intervalKm) {
      samples.add(curr);
      accumulated = 0;
    }
  }
  if (samples.last != polyline.last) {
    samples.add(polyline.last);
  }
  return samples;
}
