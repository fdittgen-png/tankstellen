import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_track_distance.dart';

void main() {
  group('GpsTrackDistance.haversineKm (#1979)', () {
    test('empty and single-point tracks have zero length', () {
      expect(GpsTrackDistance.haversineKm(const []), 0.0);
      expect(
        GpsTrackDistance.haversineKm(const [GpsTrackPoint(45.0, 5.0)]),
        0.0,
      );
    });

    test('a 0.5-degree latitude segment is ~55.6 km', () {
      final km = GpsTrackDistance.haversineKm(const [
        GpsTrackPoint(0.0, 0.0),
        GpsTrackPoint(0.5, 0.0),
      ]);
      expect(km, closeTo(55.6, 0.3));
    });

    test('a multi-segment track sums every leg', () {
      // 4 fixes 0.001 deg latitude apart (~111 m each) = 3 legs ~334 m.
      final track = [
        for (var i = 0; i < 4; i++) GpsTrackPoint(45.0 + i * 0.001, 5.0),
      ];
      expect(GpsTrackDistance.haversineKm(track), closeTo(0.3336, 0.01));
    });

    test('sub-floor jitter between near-identical fixes adds nothing', () {
      // ~2 m hops (below the 3 m jitter floor) — a parked car's GPS
      // scatter must not accumulate phantom distance.
      final jitter = [
        for (var i = 0; i < 20; i++) GpsTrackPoint(45.0 + i * 0.000018, 5.0),
      ];
      expect(GpsTrackDistance.haversineKm(jitter), 0.0);
    });
  });
}
