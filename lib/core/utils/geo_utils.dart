import 'dart:math';

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
