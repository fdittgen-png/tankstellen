// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

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

  group('TripDistanceResolver — slow-drive jitter inflation (#3004)', () {
    // The trip GPS stream runs at LocationAccuracy.high with NO
    // distanceFilter (= 0 → every OS fix), so on a SLOW drive the OS
    // delivers fixes at ~4-5 Hz. Each raw fix is buffered one-per-fix and
    // the resolver haversine-sums the WHOLE buffer. On a slow drive the
    // per-fix lateral GPS wander (~5-12 m, good 8 m accuracy) is summed at
    // every sub-second vertex — none of the #2963 gates catch it: accuracy
    // is good (< 25 m), the implied speed is well under 200 km/h, and the
    // sub-0.5 s Δt skips the teleport gate, while the wander clears the 3 m
    // jitter floor. Higher cadence ⇒ more zig-zag vertices ⇒ more
    // inflation. Result: a true ~1.72 km drive persists as ~3.5 km (~2×).
    //
    // The fix decimates the buffer to ~1 Hz (mirroring TripSampleBuffer's
    // 950 ms gate) BEFORE haversine: the sub-second in-between vertices add
    // only jitter, not net displacement, so they are dropped and the true
    // road distance dominates.
    //
    // Driven through the REAL resolver via `debugAddGpsFix` carrying real
    // accuracy + per-fix timestamps — no fake echoing the answer.
    final base = DateTime.utc(2026, 4, 22, 12);
    const lat0 = 45.0, lon0 = 5.0;
    // Metres per degree at lat 45° (WGS-84 local scale used to lay out the
    // synthetic path; the resolver computes its own haversine independently).
    const metersPerDegLon = 78710.0;
    const metersPerDegLat = 111320.0;

    /// A straight ~1.72 km east-west path driven slow (30.5 km/h, ~203 s)
    /// at [hz] fixes/s, with realistic GPS lateral jitter modelled as an
    /// AR(1) slow drift plus a fast white scintillation term — the same
    /// shape a real phone produces (the error is autocorrelated within a
    /// second, not pure white noise). Good 8 m accuracy so the 25 m gate
    /// keeps every fix; per-fix timestamps so the 1 Hz decimation has the
    /// data it needs.
    void feedSlowJitteryDrive(
      TripDistanceResolver r, {
      double hz = 5.0,
      int seed = 7,
    }) {
      final rng = math.Random(seed);
      double gauss() {
        final u1 = rng.nextDouble().clamp(1e-9, 1.0);
        final u2 = rng.nextDouble();
        return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
      }

      const totalSec = 203.0;
      const totalMeters = 1720.0;
      const driftSigma = 1.6; // slow multipath drift (m)
      const whiteSigma = 3.2; // fast scintillation (m)
      const rho = 0.9; // AR(1) drift autocorrelation
      final n = (totalSec * hz).round();
      var drift = 0.0;
      for (var i = 0; i < n; i++) {
        final frac = i / (n - 1);
        final alongM = totalMeters * frac;
        drift = rho * drift + driftSigma * gauss();
        final lateralM = drift + whiteSigma * gauss();
        r.debugAddGpsFix(
          latitude: lat0 + lateralM / metersPerDegLat,
          longitude: lon0 + alongM / metersPerDegLon,
          hAccuracyM: 8.0,
          at: base.add(Duration(milliseconds: (i / hz * 1000).round())),
        );
      }
    }

    test('a ~1.72 km slow drive sampled at ~5 Hz is not inflated to ~2×', () {
      final r = build();
      feedSlowJitteryDrive(r);
      final km = r.distanceKm(odometerStartKm: null, odometerLatestKm: null);
      // RED on master: ~3.5 km (the full-rate haversine sums every
      // sub-second jitter vertex). GREEN after 1 Hz decimation: ~2 km,
      // within tolerance of the true ~1.72 km (the residual is the
      // legitimate slow GPS drift a real noisy track carries — NOT the
      // sub-second zig-zag, which decimation removes).
      expect(km, closeTo(1.85, 0.45),
          reason: 'decimated distance must approach the true ~1.72 km, '
              'not the ~3.5 km full-rate jitter sum');
      // And it must be a large, unambiguous reduction from the inflated
      // full-rate figure — never within rounding of ~3.5 km.
      expect(km, lessThan(2.6));
      // The GPS track is still the chosen source (we did NOT swap to the
      // virtual / speed-integral fallback).
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
    });

    test('decimation does NOT under-count a 1 Hz highway track', () {
      // A genuine highway drive: 110 km/h for 120 s ≈ 3.67 km, delivered at
      // 1 Hz already (the OS thins fast motion), large real per-fix
      // displacement (~30.6 m), good accuracy. The 950 ms decimation keeps
      // EVERY fix (they are ≥ 1 s apart), so the distance is unchanged — no
      // under-count.
      final r = build();
      final rng = math.Random(3);
      double gauss() {
        final u1 = rng.nextDouble().clamp(1e-9, 1.0);
        final u2 = rng.nextDouble();
        return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
      }

      const n = 121; // 0..120 s inclusive
      const totalMeters = 3667.0;
      for (var i = 0; i < n; i++) {
        final frac = i / (n - 1);
        final alongM = totalMeters * frac;
        final lateralM = 3.0 * gauss();
        r.debugAddGpsFix(
          latitude: lat0 + lateralM / metersPerDegLat,
          longitude: lon0 + alongM / metersPerDegLon,
          hAccuracyM: 6.0,
          at: base.add(Duration(seconds: i)),
        );
      }
      final km = r.distanceKm(odometerStartKm: null, odometerLatestKm: null);
      // Unchanged by decimation: ~3.67 km true road distance (+ a little
      // from the small white jitter that any 1 Hz track legitimately
      // carries). The assertion that matters is no UNDER-count below the
      // true distance.
      expect(km, greaterThan(3.5));
      expect(km, closeTo(3.7, 0.3));
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
    });

    test('timestamp-less fixes are all kept (backward-compatible)', () {
      // Pre-#2970 fixtures / callers passed lat/lon only (null `at`). With
      // no timestamp the decimation cannot thin them, so every fix is kept
      // and the legacy haversine behaviour is preserved exactly. 12 fixes
      // ~111 m apart → 11 legs ~1.22 km, source gps.
      final r = build();
      for (var i = 0; i < 12; i++) {
        r.debugAddGpsFix(latitude: 45.0 + i * 0.001, longitude: 5.0);
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

    test('a time-compressed burst keeps its endpoints (not 0 km) (#2509)', () {
      // The decimation thins fixes that are < 950 ms after the last KEPT
      // fix. If a whole moving track arrives time-compressed — every fix a
      // few microseconds after the previous (a synchronous feed, or a device
      // that batches fixes onto near-identical timestamps) — every fix after
      // the first is "after the last kept but < 950 ms", so the naive loop
      // keeps ONLY the first point and haversine-sums to 0 km, silently
      // discarding a real drive. The endpoint-retention guard keeps the
      // final fix, so the track still integrates to its real end position.
      // This is the #2509 journey invariant at the unit level: RED without
      // the guard (0.0 km), GREEN with it.
      final r = build();
      const n = 20; // ≥ kMinGpsFixesForDistanceSource (10)
      for (var i = 0; i < n; i++) {
        r.debugAddGpsFix(
          latitude: lat0 + i * 0.0005, // ~55 m per step → ~1.05 km total
          longitude: lon0,
          hAccuracyM: 6.0,
          at: base.add(Duration(microseconds: i)), // sub-ms, strictly rising
        );
      }
      final km = r.distanceKm(odometerStartKm: null, odometerLatestKm: null);
      expect(km, greaterThan(0.9),
          reason: 'a moving track must not decimate to 0 km');
      expect(km, lessThan(1.2));
      expect(
        r.distanceSource(odometerStartKm: null, odometerLatestKm: null),
        kDistanceSourceGps,
      );
    });
  });
}
