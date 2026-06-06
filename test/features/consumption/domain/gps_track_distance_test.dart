// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  group('GpsTrackDistance accuracy + teleport gates (#2963)', () {
    // A deterministic ~25 m idle scatter around one coordinate. Each hop is
    // ~10-25 m apart (ABOVE the 3 m jitter floor, so the old code summed it
    // into phantom kilometres) but every fix reports poor accuracy ~25 m.
    List<GpsTrackPoint> idleScatter({double? hAccuracyM, DateTime? base}) {
      final start = base ?? DateTime.utc(2026, 4, 22, 12);
      // Deterministic pseudo-jitter: a fixed offset table around 45.0/5.0.
      const dLat = <double>[0, 0.00018, -0.00012, 0.00022, -0.00020, 0.00015];
      const dLon = <double>[0, -0.00021, 0.00019, -0.00014, 0.00023, -0.00017];
      return [
        for (var i = 0; i < 22; i++)
          GpsTrackPoint(
            45.0 + dLat[i % dLat.length],
            5.0 + dLon[i % dLon.length],
            hAccuracyM: hAccuracyM,
            at: start.add(Duration(seconds: i)),
          ),
      ];
    }

    test(
        'poor-accuracy idle scatter (the field bug) collapses to ~0 km, but '
        'the SAME scatter WITHOUT accuracy would have summed phantom km', () {
      // Sanity: with NO accuracy reported (null = accept) the legacy sum is
      // non-trivial — proving the scatter is large enough to matter (this is
      // exactly what corrupted the 22 s trip into 0.945 km).
      final phantom = GpsTrackDistance.haversineKm(idleScatter());
      expect(phantom, greaterThan(0.4),
          reason: 'jitter exceeds the 3 m floor → old code accumulates it');

      // With the real poor accuracy each fix carried (~30 m, worse than the
      // 25 m gate — a parked phone's reported accuracy is itself noisy and
      // sits above the gate), every segment is rejected and the track
      // collapses below the resolver's 50 m floor.
      final gated =
          GpsTrackDistance.haversineKm(idleScatter(hAccuracyM: 30.0));
      expect(gated, lessThan(0.05));
    });

    test('a single poor-accuracy endpoint drops only its adjacent segments',
        () {
      final base = DateTime.utc(2026, 4, 22, 12);
      final track = [
        GpsTrackPoint(45.0, 5.0, hAccuracyM: 8.0, at: base),
        // ~111 m north, but reported at 40 m accuracy → both its segments drop.
        GpsTrackPoint(45.001, 5.0,
            hAccuracyM: 40.0, at: base.add(const Duration(seconds: 10))),
        GpsTrackPoint(45.002, 5.0,
            hAccuracyM: 8.0, at: base.add(const Duration(seconds: 20))),
      ];
      // Both legs touch the bad middle fix → total is 0.
      expect(GpsTrackDistance.haversineKm(track), 0.0);
    });

    test('teleport gate drops a cold-start jump but keeps the real drive', () {
      final base = DateTime.utc(2026, 4, 22, 12);
      final track = [
        // Cold-start: a ~22 km jump (0.2 deg lat) in 1 s → ~80 000 km/h.
        GpsTrackPoint(45.0, 5.0, hAccuracyM: 8.0, at: base),
        GpsTrackPoint(45.2, 5.0,
            hAccuracyM: 8.0, at: base.add(const Duration(seconds: 1))),
        // Then a real ~111 m / 10 s leg = ~40 km/h, plausible → kept.
        GpsTrackPoint(45.201, 5.0,
            hAccuracyM: 8.0, at: base.add(const Duration(seconds: 11))),
      ];
      final km = GpsTrackDistance.haversineKm(track);
      // The ~22 km teleport is rejected; only the ~0.111 km real leg counts.
      expect(km, closeTo(0.111, 0.01));
    });

    test('a normal moving track (good accuracy, plausible speed) is unaffected',
        () {
      final base = DateTime.utc(2026, 4, 22, 12);
      // 4 fixes 0.001 deg apart (~111 m) at 10 s spacing = ~40 km/h, good
      // accuracy — must still sum to ~334 m exactly like the no-gate path.
      final track = [
        for (var i = 0; i < 4; i++)
          GpsTrackPoint(45.0 + i * 0.001, 5.0,
              hAccuracyM: 6.0, at: base.add(Duration(seconds: i * 10))),
      ];
      expect(GpsTrackDistance.haversineKm(track), closeTo(0.3336, 0.01));
    });

    test('null accuracy + null timestamps behave exactly as before (no gate)',
        () {
      // Backward-compatibility: a lat/lon-only track is unchanged.
      final track = [
        for (var i = 0; i < 4; i++) GpsTrackPoint(45.0 + i * 0.001, 5.0),
      ];
      expect(GpsTrackDistance.haversineKm(track), closeTo(0.3336, 0.01));
    });
  });
}
