// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3631 — highway mode: hysteresis on sustained speed, and the ahead
// filter that drops opposite-direction stations (the low-fuel-on-the-
// highway field report) while keeping same-carriageway services and
// next-exit candidates — with the never-empty safety fallback.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/radar/highway_mode.dart';

Station _station(String id, double lat, double lng) => Station(
      id: id,
      name: id,
      brand: '',
      street: '',
      place: '',
      postCode: '',
      lat: lat,
      lng: lng,
      dist: 0,
      isOpen: true,
    );

void main() {
  group('HighwayModeDetector hysteresis', () {
    final t0 = DateTime(2026, 7, 26, 10);

    test('engages only after sustained enter-speed, not a burst', () {
      final d = HighwayModeDetector();
      d.onFix(speedKmh: 120, at: t0);
      d.onFix(speedKmh: 120, at: t0.add(const Duration(seconds: 30)));
      expect(d.active, isFalse, reason: '30 s is not sustained');
      d.onFix(speedKmh: 120, at: t0.add(const Duration(seconds: 61)));
      expect(d.active, isTrue);
    });

    test('a slowdown burst (traffic, exit ramp) does not release it', () {
      final d = HighwayModeDetector();
      d.onFix(speedKmh: 120, at: t0);
      d.onFix(speedKmh: 120, at: t0.add(const Duration(seconds: 61)));
      d.onFix(speedKmh: 30, at: t0.add(const Duration(seconds: 100)));
      d.onFix(speedKmh: 30, at: t0.add(const Duration(seconds: 200)));
      expect(d.active, isTrue, reason: '100 s slow < the 180 s release');
      d.onFix(speedKmh: 110, at: t0.add(const Duration(seconds: 210)));
      d.onFix(speedKmh: 30, at: t0.add(const Duration(seconds: 300)));
      d.onFix(speedKmh: 30, at: t0.add(const Duration(seconds: 490)));
      expect(d.active, isFalse, reason: '190 s sustained slow releases');
    });

    test('a speed dip resets the ENTER clock', () {
      final d = HighwayModeDetector();
      d.onFix(speedKmh: 120, at: t0);
      d.onFix(speedKmh: 60, at: t0.add(const Duration(seconds: 40)));
      d.onFix(speedKmh: 120, at: t0.add(const Duration(seconds: 50)));
      d.onFix(speedKmh: 120, at: t0.add(const Duration(seconds: 100)));
      expect(d.active, isFalse,
          reason: 'the sustain window restarted at the dip');
    });
  });

  group('filterStationsAhead', () {
    // Heading due north from (43.0, 3.0). 1° lat ≈ 111 km;
    // 1° lng ≈ 111·cos(43°) ≈ 81 km.
    const lat = 43.0, lng = 3.0;

    test('keeps ahead + next-exit, drops behind and the opposite '
        'carriageway (right-hand traffic)', () {
      final ahead = _station('ahead', 43.09, 3.0); // 10 km due north
      final behind = _station('behind', 42.91, 3.0); // 10 km due south
      // ~5 km ahead, ~80 m LEFT of the carriageway — the opposite-
      // direction service area of the field report.
      final opposite = _station('opposite', 43.045, 2.999);
      // ~5 km ahead, ~80 m RIGHT — my side's service area.
      final myside = _station('myside', 43.045, 3.001);
      // ~6 km ahead, ~2.4 km left — a town off the next exit: reachable.
      final exitTown = _station('exit', 43.055, 2.97);

      final r = filterStationsAhead(
        stations: [ahead, behind, opposite, myside, exitTown],
        lat: lat,
        lng: lng,
        headingDegrees: 0,
        leftHandTraffic: false,
      );
      final ids = r.stations.map((s) => s.id).toList();
      expect(r.filtered, isTrue);
      expect(ids, containsAll(['ahead', 'myside', 'exit']));
      expect(ids, isNot(contains('behind')));
      expect(ids, isNot(contains('opposite')),
          reason: 'on-road + oncoming side = unreachable on a highway');
    });

    test('left-hand traffic inverts the oncoming side', () {
      final leftOfRoad = _station('left', 43.045, 2.999);
      final rightOfRoad = _station('right', 43.045, 3.001);
      final r = filterStationsAhead(
        stations: [leftOfRoad, rightOfRoad],
        lat: lat,
        lng: lng,
        headingDegrees: 0,
        leftHandTraffic: true,
      );
      final ids = r.stations.map((s) => s.id).toList();
      expect(ids, contains('left'));
      expect(ids, isNot(contains('right')));
    });

    test('SAFETY: a cone that would empty the list falls back to the '
        'unfiltered input', () {
      final behindOnly = _station('b', 42.9, 3.0);
      final r = filterStationsAhead(
        stations: [behindOnly],
        lat: lat,
        lng: lng,
        headingDegrees: 0,
        leftHandTraffic: false,
      );
      expect(r.filtered, isFalse);
      expect(r.stations, hasLength(1),
          reason: 'a low-fuel driver must never see zero stations '
              'because of a heuristic');
    });

    test('non-finite heading is a no-op', () {
      final s1 = _station('x', 42.9, 3.0);
      final r = filterStationsAhead(
        stations: [s1],
        lat: lat,
        lng: lng,
        headingDegrees: double.nan,
        leftHandTraffic: false,
      );
      expect(r.filtered, isFalse);
      expect(r.stations, hasLength(1));
    });
  });
}
