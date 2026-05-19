import 'dart:math' as math;

/// A single GPS fix on a recorded trip's track — latitude / longitude
/// in decimal degrees (#1979).
class GpsTrackPoint {
  final double latitude;
  final double longitude;

  const GpsTrackPoint(this.latitude, this.longitude);
}

/// Haversine-summed road distance over a sequence of GPS fixes (#1979).
///
/// Used as a distance source for the consumption calculation: the GPS
/// track is the true road distance, more accurate than the OBD
/// speed-sensor `virtual` odometer (the speedometer sensor over-reads).
class GpsTrackDistance {
  GpsTrackDistance._();

  /// Mean Earth radius (km) — the WGS-84 IUGG mean radius.
  static const double _earthRadiusKm = 6371.0088;

  /// Total polyline distance, in km, through [track].
  ///
  /// Each consecutive pair contributes a great-circle segment. A
  /// per-segment [jitterFloorKm] floor drops sub-floor hops so a
  /// stationary car's GPS scatter (typically a few metres of drift
  /// between fixes) does not accumulate phantom distance. A track with
  /// fewer than two points has zero length.
  static double haversineKm(
    List<GpsTrackPoint> track, {
    double jitterFloorKm = 0.003,
  }) {
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      final segment = _segmentKm(track[i - 1], track[i]);
      if (segment >= jitterFloorKm) total += segment;
    }
    return total;
  }

  /// Great-circle distance (km) between two fixes via the haversine
  /// formula.
  static double _segmentKm(GpsTrackPoint a, GpsTrackPoint b) {
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    // `min(1.0, …)` guards asin's domain against floating-point drift.
    return 2 * _earthRadiusKm * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180.0;
}
