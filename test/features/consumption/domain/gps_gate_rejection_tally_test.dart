// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/gps_track_distance.dart';

/// #3253 — per-gate rejection tally on [GpsTrackDistance.haversineKm].
/// The #2963 accuracy/teleport gates and the #1979 jitter floor used to
/// drop segments SILENTLY (`continue` with no counter), so a "the trip
/// lost 2 km" field report was not decomposable. The optional
/// [GpsGateRejectionTally] out-param now records which gate ate how many
/// segments / km — and passing no tally keeps the distance byte-identical.
void main() {
  final base = DateTime.utc(2026, 6, 1, 8);

  group('GpsGateRejectionTally — accuracy gate', () {
    test('a poor-accuracy endpoint books both touching segments', () {
      // Three ~111 m legs; the middle point reports 40 m accuracy (> the
      // 25 m gate), so legs 1-2 and 2-3 are rejected and booked.
      final track = <GpsTrackPoint>[
        const GpsTrackPoint(45.000, 5.0, hAccuracyM: 6),
        const GpsTrackPoint(45.001, 5.0, hAccuracyM: 40),
        const GpsTrackPoint(45.002, 5.0, hAccuracyM: 6),
        const GpsTrackPoint(45.003, 5.0, hAccuracyM: 6),
      ];
      final tally = GpsGateRejectionTally();
      final km = GpsTrackDistance.haversineKm(track, tally: tally);
      expect(km, closeTo(0.111, 0.005), reason: 'only the clean leg counts');
      expect(tally.accuracyRejectedSegments, 2);
      expect(tally.accuracyRejectedKm, closeTo(0.222, 0.01));
      expect(tally.jitterRejectedSegments, 0);
      expect(tally.teleportRejectedSegments, 0);
    });
  });

  group('GpsGateRejectionTally — jitter floor', () {
    test('sub-3 m hops are booked as jitter', () {
      // Two ~1 m hops (below the 0.003 km floor) between two real legs.
      final track = <GpsTrackPoint>[
        const GpsTrackPoint(45.000, 5.0),
        const GpsTrackPoint(45.001, 5.0), // ~111 m — kept
        const GpsTrackPoint(45.001009, 5.0), // ~1 m — jitter
        const GpsTrackPoint(45.001, 5.0), // ~1 m — jitter
        const GpsTrackPoint(45.002, 5.0), // ~111 m — kept
      ];
      final tally = GpsGateRejectionTally();
      final km = GpsTrackDistance.haversineKm(track, tally: tally);
      expect(km, closeTo(0.222, 0.01));
      expect(tally.jitterRejectedSegments, 2);
      expect(tally.jitterRejectedKm, lessThan(0.003 * 2 + 1e-9));
      expect(tally.jitterRejectedKm, greaterThan(0));
      expect(tally.accuracyRejectedSegments, 0);
      expect(tally.teleportRejectedSegments, 0);
    });
  });

  group('GpsGateRejectionTally — teleport gate', () {
    test('an implausible-speed jump is booked as teleport', () {
      // ~1.1 km in 1 s (≈ 4000 km/h) between two plausible ~22 m/1 s legs.
      final track = <GpsTrackPoint>[
        GpsTrackPoint(45.0000, 5.0, at: base),
        GpsTrackPoint(45.0002, 5.0, at: base.add(const Duration(seconds: 1))),
        GpsTrackPoint(45.0102, 5.0, at: base.add(const Duration(seconds: 2))),
        GpsTrackPoint(45.0104, 5.0, at: base.add(const Duration(seconds: 3))),
      ];
      final tally = GpsGateRejectionTally();
      final km = GpsTrackDistance.haversineKm(track, tally: tally);
      expect(km, closeTo(0.044, 0.005), reason: 'the jump must not count');
      expect(tally.teleportRejectedSegments, 1);
      expect(tally.teleportRejectedKm, closeTo(1.11, 0.05));
      expect(tally.accuracyRejectedSegments, 0);
      expect(tally.jitterRejectedSegments, 0);
    });
  });

  group('GpsGateRejectionTally — neutrality + export shape', () {
    test('passing a tally never changes the returned distance', () {
      final track = <GpsTrackPoint>[
        GpsTrackPoint(45.0000, 5.0, hAccuracyM: 6, at: base),
        GpsTrackPoint(45.0002, 5.0,
            hAccuracyM: 40, at: base.add(const Duration(seconds: 1))),
        GpsTrackPoint(45.0102, 5.0,
            hAccuracyM: 6, at: base.add(const Duration(seconds: 2))),
        GpsTrackPoint(45.0104, 5.0,
            hAccuracyM: 6, at: base.add(const Duration(seconds: 3))),
      ];
      final plain = GpsTrackDistance.haversineKm(track);
      final tallied =
          GpsTrackDistance.haversineKm(track, tally: GpsGateRejectionTally());
      expect(tallied, plain);
    });

    test('a clean track books nothing and exports an empty map', () {
      final track = <GpsTrackPoint>[
        for (var i = 0; i < 5; i++)
          GpsTrackPoint(45.0 + i * 0.001, 5.0,
              hAccuracyM: 6, at: base.add(Duration(seconds: i * 10))),
      ];
      final tally = GpsGateRejectionTally();
      GpsTrackDistance.haversineKm(track, tally: tally);
      expect(tally.accuracyRejectedSegments, 0);
      expect(tally.jitterRejectedSegments, 0);
      expect(tally.teleportRejectedSegments, 0);
      expect(tally.toCounterIncrements(), isEmpty,
          reason: 'zero rows are omitted so the counter box stays sparse');
    });

    test('toCounterIncrements exports metres as ints under trips.gps.*', () {
      final tally = GpsGateRejectionTally()
        ..accuracyRejectedSegments = 2
        ..accuracyRejectedKm = 0.2224
        ..decimationDroppedFixes = 40
        ..decimationCollapsedKm = 1.7;
      expect(tally.toCounterIncrements(), {
        'trips.gps.accuracyRejectedSegments': 2,
        'trips.gps.accuracyRejectedMeters': 222,
        'trips.gps.decimationDroppedFixes': 40,
        'trips.gps.decimationCollapsedMeters': 1700,
      });
    });
  });
}
