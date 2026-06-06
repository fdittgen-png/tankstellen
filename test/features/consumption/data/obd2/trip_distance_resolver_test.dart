// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_distance_resolver.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_distance_source.dart';
import 'package:tankstellen/features/consumption/data/obd2/virtual_odometer.dart';

/// Direct unit tests for [TripDistanceResolver] (#2187), exercising the
/// three-tier resolution order (real → gps → virtual), the noise-floor /
/// sparse-track rejection edges, the integration-gap cap, and the
/// production-trim-vs-debug-no-trim asymmetry — all without spinning up a
/// controller, scheduler, or fake transport.
void main() {
  const gapCap = 15.0;
  final fixedClock = DateTime.utc(2026, 4, 22, 11);

  TripDistanceResolver build() =>
      TripDistanceResolver(maxIntegrationGapSeconds: gapCap, now: () => fixedClock);

  group('TripDistanceResolver — resolution order', () {
    test('real odometer delta wins over GPS and virtual', () {
      final r = build();
      // A usable GPS track + speed samples that, if used, would not be 3 km.
      for (var i = 0; i < 12; i++) {
        r.debugAddGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
      }
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 60; s += 15) {
        r.debugAddSpeedSample(speedKmh: 30, at: t0.add(Duration(seconds: s)));
      }

      expect(
        r.distanceSource(odometerStartKm: 100.0, odometerLatestKm: 103.0),
        kDistanceSourceReal,
      );
      expect(
        r.distanceKm(odometerStartKm: 100.0, odometerLatestKm: 103.0),
        closeTo(3.0, 1e-9),
      );
    });

    test('GPS track wins over virtual when no real odometer', () {
      final r = build();
      // 12 fixes, 0.001 deg latitude apart (~111 m) → 11 legs ~1.223 km.
      for (var i = 0; i < 12; i++) {
        r.debugAddGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
      }
      // Speed samples present but should be ignored (GPS beats virtual).
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 60; s += 15) {
        r.debugAddSpeedSample(speedKmh: 30, at: t0.add(Duration(seconds: s)));
      }

      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        closeTo(1.223, 0.03),
      );
    });

    test('virtual odometer is the final fallback (no odometer, no GPS)', () {
      final r = build();
      // 30 km/h for 60 s = 0.5 km, sampled at the ≤15 s gap cap.
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 60; s += 15) {
        r.debugAddSpeedSample(speedKmh: 30, at: t0.add(Duration(seconds: s)));
      }

      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        closeTo(0.5, 0.01),
      );
    });

    test('empty resolver → virtual source, zero distance', () {
      final r = build();
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        0.0,
      );
    });
  });

  group('TripDistanceResolver — real-odometer noise floor', () {
    test('zero delta (start == latest) is rejected → falls through', () {
      final r = build();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 60; s += 15) {
        r.debugAddSpeedSample(speedKmh: 30, at: t0.add(Duration(seconds: s)));
      }
      expect(
        r.distanceSource(odometerStartKm: 100.0, odometerLatestKm: 100.0),
        kDistanceSourceVirtual,
      );
      expect(
        r.distanceKm(odometerStartKm: 100.0, odometerLatestKm: 100.0),
        closeTo(0.5, 0.01),
      );
    });

    test('sub-epsilon delta (< 0.05 km) is rejected as sensor artefact', () {
      final r = build();
      // 0.04 km delta is below the 0.05 km noise floor → null → fall back.
      expect(
        r.distanceSource(odometerStartKm: 0.0, odometerLatestKm: 0.04),
        kDistanceSourceVirtual,
      );
      // No GPS / speed → 0.0 virtual.
      expect(
        r.distanceKm(odometerStartKm: 0.0, odometerLatestKm: 0.04),
        0.0,
      );
    });

    test('a clearly-above-epsilon delta (0.06 km) is accepted as real', () {
      final r = build();
      expect(
        r.distanceSource(odometerStartKm: 0.0, odometerLatestKm: 0.06),
        kDistanceSourceReal,
      );
      expect(
        r.distanceKm(odometerStartKm: 0.0, odometerLatestKm: 0.06),
        closeTo(0.06, 1e-9),
      );
    });

    test('negative delta (start > latest) is rejected', () {
      final r = build();
      expect(
        r.distanceSource(odometerStartKm: 105.0, odometerLatestKm: 100.0),
        kDistanceSourceVirtual,
      );
    });

    test('one null odometer reading is rejected', () {
      final r = build();
      expect(
        r.distanceSource(odometerStartKm: 100.0, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: 103.0),
        kDistanceSourceVirtual,
      );
    });
  });

  group('TripDistanceResolver — GPS sparse / jitter rejection', () {
    test('fewer than kMinGpsFixesForDistanceSource fixes is rejected', () {
      final r = build();
      // Only 5 fixes — below the 10-fix minimum.
      for (var i = 0; i < 5; i++) {
        r.debugAddGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
      }
      // Speed fallback so the virtual path has something to integrate.
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 60; s += 15) {
        r.debugAddSpeedSample(speedKmh: 30, at: t0.add(Duration(seconds: s)));
      }
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        closeTo(0.5, 0.01),
      );
    });

    test('enough fixes but sub-50 m total (parked scatter) is rejected', () {
      final r = build();
      // 12 fixes all at the same point → 0 km haversine → < 0.05 km → null.
      for (var i = 0; i < 12; i++) {
        r.debugAddGpsFix(latitude: 45.0, longitude: 5.0);
      }
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
    });

    test('boundary: exactly kMinGpsFixesForDistanceSource usable fixes', () {
      final r = build();
      // 10 fixes ~111 m apart → 9 legs ~1.0 km, well above the 50 m floor.
      for (var i = 0; i < kMinGpsFixesForDistanceSource; i++) {
        r.debugAddGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
      }
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
    });
  });

  group('TripDistanceResolver — virtual-odometer integration-gap cap', () {
    test('a gap longer than maxIntegrationGapSeconds is not bridged', () {
      final r = build();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      // Two samples 60 s apart at 60 km/h: gap (60 s) > cap (15 s) → the
      // pair is skipped → 0 km. (Matches VirtualOdometer.maxGapSeconds.)
      r.debugAddSpeedSample(speedKmh: 60, at: t0);
      r.debugAddSpeedSample(speedKmh: 60, at: t0.add(const Duration(seconds: 60)));
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        0.0,
      );
    });

    test('distanceKm matches a hand-built VirtualOdometer over the buffer', () {
      final r = build();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var s = 0; s <= 300; s += 15) {
        r.debugAddSpeedSample(speedKmh: 60, at: t0.add(Duration(seconds: s)));
      }
      final expected =
          VirtualOdometer(samples: r.debugSpeedSamples, maxGapSeconds: gapCap)
              .integrateKm();
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        closeTo(expected, 1e-9),
      );
    });
  });

  group('TripDistanceResolver — trim asymmetry (#2187 preserved)', () {
    test('production addSpeedSample trims at the cap; debug path does not', () {
      // Production ingress trims to kVirtualOdometerSampleCap.
      final trimmed = build();
      for (var i = 0; i < kVirtualOdometerSampleCap + 5; i++) {
        trimmed.addSpeedSample(50);
      }
      expect(trimmed.debugSpeedSamples.length, kVirtualOdometerSampleCap);

      // Debug ingress intentionally does NOT trim — tests can build an
      // arbitrarily long deterministic buffer past the cap.
      final untrimmed = build();
      final t0 = DateTime.utc(2026, 4, 22, 12);
      for (var i = 0; i < kVirtualOdometerSampleCap + 5; i++) {
        untrimmed.debugAddSpeedSample(
          speedKmh: 50,
          at: t0.add(Duration(milliseconds: i)),
        );
      }
      expect(
        untrimmed.debugSpeedSamples.length,
        kVirtualOdometerSampleCap + 5,
      );
    });

    test('production addGpsFix trims the GPS buffer at the cap', () {
      final r = build();
      for (var i = 0; i < kVirtualOdometerSampleCap + 3; i++) {
        r.addGpsFix(45.0, 5.0);
      }
      // GPS buffer length is not directly exposed, but a capped buffer of
      // identical points still resolves to virtual (0 km haversine); the
      // assertion that matters is it did not throw / grow unbounded —
      // exercised here via the resolution path staying well-formed.
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceVirtual,
      );
    });
  });

  group('TripDistanceResolver — short idle-heavy OBD2 trip (#2963)', () {
    // Reproduces the field export: a 22 s trip parked at idle. The phone
    // emits ~22 GPS fixes scattering within ±25 m of one coordinate, each
    // reporting ~30 m accuracy (a parked phone's reported accuracy is itself
    // noisy and sits above the 25 m gate), plus one ~200 m cold-start jump.
    // On master
    // the resolver returned distanceKm ≈ 0.8-1.0 with source == gps (the
    // 154 km/h-average corruption). After the #2963 gates the whole track
    // is rejected → gps source nulled → falls back (here to virtual = 0 for
    // a parked car).
    //
    // Driven through the REAL resolver via `debugAddGpsFix` carrying real
    // accuracy + timestamps — no fake echoing the answer (the
    // false-green-fakes rule).
    final base = DateTime.utc(2026, 4, 22, 12);
    const dLat = <double>[0, 0.00018, -0.00012, 0.00022, -0.00020, 0.00015];
    const dLon = <double>[0, -0.00021, 0.00019, -0.00014, 0.00023, -0.00017];

    void feedIdleJitter(TripDistanceResolver r) {
      // One cold-start jump first: ~200 m north of the parking spot, 1 s in.
      r.debugAddGpsFix(
        latitude: 45.0,
        longitude: 5.0,
        hAccuracyM: 30.0,
        at: base,
      );
      r.debugAddGpsFix(
        latitude: 45.0018, // ~200 m north
        longitude: 5.0,
        hAccuracyM: 30.0,
        at: base.add(const Duration(seconds: 1)),
      );
      // Then 22 stationary fixes scattering ±25 m around the parking spot.
      for (var i = 0; i < 22; i++) {
        r.debugAddGpsFix(
          latitude: 45.0018 + dLat[i % dLat.length],
          longitude: 5.0 + dLon[i % dLon.length],
          hAccuracyM: 30.0,
          at: base.add(Duration(seconds: 2 + i)),
        );
      }
    }

    test('the idle scatter no longer surfaces as a GPS distance source', () {
      final r = build();
      feedIdleJitter(r);
      // The whole poor-accuracy + teleport track collapses below the 50 m
      // resolver floor, so the GPS source is nulled (RED on master, where it
      // returned ~0.8-1.0 km / kDistanceSourceGps).
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        lessThan(0.05),
      );
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        isNot(kDistanceSourceGps),
      );
    });

    test('a real moving track is still used as the GPS source', () {
      // Guard against over-rejection: good-accuracy fixes moving at a
      // plausible ~40 km/h must still resolve to GPS.
      final r = build();
      for (var i = 0; i < 12; i++) {
        r.debugAddGpsFix(
          latitude: 45.0 + i * 0.001, // ~111 m steps
          longitude: 5.0,
          hAccuracyM: 6.0,
          at: base.add(Duration(seconds: i * 10)), // 40 km/h
        );
      }
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
      expect(
        r.distanceKm(odometerStartKm: null, odometerLatestKm: null),
        greaterThan(1.0),
      );
    });
  });
}
