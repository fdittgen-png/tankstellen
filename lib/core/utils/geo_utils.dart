import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Haversine distance between two coordinates in kilometers.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  if (lat1 == 0 && lng1 == 0) return 0;
  if (lat2 == 0 && lng2 == 0) return 0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLng / 2) * sin(dLng / 2);
  return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Computes how far along a polyline a given point is (in km from start).
///
/// Walks the polyline segments, accumulating distance. Returns the cumulative
/// distance to the polyline vertex closest to [lat]/[lng]. For performance,
/// steps through every [step]th vertex on long polylines.
double distanceAlongPolyline(
  double lat,
  double lng,
  List<LatLng> polyline, {
  int? step,
}) {
  if (polyline.isEmpty) return double.infinity;
  final effectiveStep = step ?? (polyline.length > 300 ? 3 : 1);

  double minDist = double.infinity;
  double cumulativeKm = 0;
  double bestCumulativeKm = 0;

  LatLng? prev;
  for (int i = 0; i < polyline.length; i += effectiveStep) {
    final p = polyline[i];
    if (prev != null) {
      cumulativeKm += distanceKm(
        prev.latitude, prev.longitude,
        p.latitude, p.longitude,
      );
    }
    final d = distanceKm(lat, lng, p.latitude, p.longitude);
    if (d < minDist) {
      minDist = d;
      bestCumulativeKm = cumulativeKm;
    }
    prev = p;
  }
  return bestCumulativeKm;
}
