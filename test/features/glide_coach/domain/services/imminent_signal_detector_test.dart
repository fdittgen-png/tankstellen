// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/glide_coach/data/osm_traffic_signal_client.dart';
import 'package:tankstellen/features/glide_coach/data/traffic_signal_repository.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/traffic_signal.dart';
import 'package:tankstellen/features/glide_coach/domain/services/imminent_signal_detector.dart';

/// Test double for [TrafficSignalRepository] that lets each test stub
/// the bbox response (or an error) without spinning up Hive. The real
/// repo is exercised by `traffic_signal_repository_test.dart`; here we
/// only care about the detector's filtering / ranking behaviour.
class _StubRepo implements TrafficSignalRepository {
  List<TrafficSignal> response;
  Object? errorToThrow;
  int callCount = 0;

  ({double south, double west, double north, double east})? lastBbox;

  _StubRepo({this.response = const <TrafficSignal>[], this.errorToThrow});

  @override
  Future<List<TrafficSignal>> getSignalsForBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    callCount++;
    lastBbox = (south: south, west: west, north: north, east: east);
    final err = errorToThrow;
    if (err != null) throw err;
    return response;
  }

  // The remaining repo members are not exercised by the detector;
  // `noSuchMethod` lets this stub stay resilient to future repo
  // additions without forcing us to mirror them all here.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Convert a metre offset along a compass `bearingDeg` (0=N, 90=E)
/// into a `(dLat, dLng)` increment around `lat`. Mirrors the
/// flat-earth approximation the bbox helper uses; accurate enough at
/// ≤ 200 m to keep test inputs deterministic without depending on
/// the production geodesy.
({double dLat, double dLng}) _metreOffset({
  required double lat,
  required double metres,
  required double bearingDeg,
}) {
  const metresPerDegLat = 111320.0;
  final bearingRad = bearingDeg * math.pi / 180.0;
  final cosLat = math.cos(lat * math.pi / 180.0);
  final dLat = (metres * math.cos(bearingRad)) / metresPerDegLat;
  final dLng = (metres * math.sin(bearingRad)) / (metresPerDegLat * cosLat);
  return (dLat: dLat, dLng: dLng);
}

void main() {
  // Reference points used by the geodesy tests below. Values come
  // from standard great-circle references; tolerated to ±2° / ±1 %
  // per the test plan in the issue brief.
  const paris = LatLng(48.8566, 2.3522);
  const london = LatLng(51.5074, -0.1278);
  const berlin = LatLng(52.5200, 13.4050);

  group('ImminentSignalDetector.bearingDegrees', () {
    test('Paris → London is roughly 332° (NNW)', () {
      final bearing = ImminentSignalDetector.bearingDegrees(paris, london);
      expect(bearing, closeTo(332, 2));
    });

    test('Paris → Berlin is roughly 60° (ENE)', () {
      final bearing = ImminentSignalDetector.bearingDegrees(paris, berlin);
      expect(bearing, closeTo(60, 2));
    });

    test('identical points return 0.0 (no NaN)', () {
      final bearing = ImminentSignalDetector.bearingDegrees(paris, paris);
      expect(bearing, 0.0);
      expect(bearing.isFinite, isTrue);
    });

    test('antipodal points return a finite bearing', () {
      // Antipode of Paris, give or take.
      const antipodeOfParis = LatLng(-48.8566, -177.6478);
      final bearing = ImminentSignalDetector.bearingDegrees(
        paris,
        antipodeOfParis,
      );
      expect(bearing.isFinite, isTrue);
      expect(bearing, inInclusiveRange(0, 360));
    });

    test('result is always in [0, 360)', () {
      // A point due south crosses the 180° boundary.
      const south = LatLng(40.0, 2.3522);
      final bearing = ImminentSignalDetector.bearingDegrees(paris, south);
      expect(bearing, inInclusiveRange(0, 360));
      expect(bearing, lessThan(360));
      expect(bearing, closeTo(180, 1));
    });
  });

  group('ImminentSignalDetector.distanceMeters', () {
    test('Paris → London is ~344 km within 1%', () {
      final d = ImminentSignalDetector.distanceMeters(paris, london);
      expect(d, closeTo(344000, 3440));
    });

    test('Paris → Berlin is ~877 km within 1%', () {
      final d = ImminentSignalDetector.distanceMeters(paris, berlin);
      expect(d, closeTo(877000, 8770));
    });

    test('same point returns 0', () {
      expect(ImminentSignalDetector.distanceMeters(paris, paris), 0.0);
    });

    test('symmetric: A→B == B→A', () {
      final ab = ImminentSignalDetector.distanceMeters(paris, london);
      final ba = ImminentSignalDetector.distanceMeters(london, paris);
      expect(ab, closeTo(ba, 0.001));
    });
  });

  group('ImminentSignalDetector.bearingDeltaDegrees', () {
    test('wraps around 360°: delta(355, 5) = 10', () {
      expect(ImminentSignalDetector.bearingDeltaDegrees(355, 5), 10);
    });

    test('reverse: delta(5, 355) = 10', () {
      expect(ImminentSignalDetector.bearingDeltaDegrees(5, 355), 10);
    });

    test('opposite: delta(180, 0) = 180', () {
      expect(ImminentSignalDetector.bearingDeltaDegrees(180, 0), 180);
    });

    test('zero: delta(42, 42) = 0', () {
      expect(ImminentSignalDetector.bearingDeltaDegrees(42, 42), 0);
    });

    test('symmetric: delta(a, b) == delta(b, a)', () {
      expect(
        ImminentSignalDetector.bearingDeltaDegrees(120, 250),
        ImminentSignalDetector.bearingDeltaDegrees(250, 120),
      );
    });

    test('result is always in [0, 180]', () {
      const pairs = <(double, double)>[
        (10.0, 350.0),
        (90.0, 270.0),
        (45.0, 135.0),
        (0.0, 359.99),
      ];
      for (final pair in pairs) {
        final delta = ImminentSignalDetector.bearingDeltaDegrees(
          pair.$1,
          pair.$2,
        );
        expect(
          delta,
          inInclusiveRange(0, 180),
          reason: 'pair=${pair.$1},${pair.$2} delta=$delta',
        );
      }
    });
  });

  group('ImminentSignalDetector.searchBoundingBox', () {
    test('contains the centre point', () {
      final bbox = ImminentSignalDetector.searchBoundingBox(paris, 200);
      expect(bbox.south, lessThan(paris.latitude));
      expect(bbox.north, greaterThan(paris.latitude));
      expect(bbox.west, lessThan(paris.longitude));
      expect(bbox.east, greaterThan(paris.longitude));
    });

    test('lat-delta scales with horizon', () {
      final small = ImminentSignalDetector.searchBoundingBox(paris, 100);
      final big = ImminentSignalDetector.searchBoundingBox(paris, 1000);
      final smallLat = small.north - small.south;
      final bigLat = big.north - big.south;
      expect(bigLat, greaterThan(smallLat));
    });

    test('does not divide by zero at the equator', () {
      const equator = LatLng(0.0, 0.0);
      final bbox = ImminentSignalDetector.searchBoundingBox(equator, 200);
      expect(bbox.south.isFinite, isTrue);
      expect(bbox.north.isFinite, isTrue);
      expect(bbox.east.isFinite, isTrue);
      expect(bbox.west.isFinite, isTrue);
    });

    test('does not divide by zero near the poles', () {
      const nearPole = LatLng(89.999999, 0.0);
      final bbox = ImminentSignalDetector.searchBoundingBox(nearPole, 200);
      expect(bbox.south.isFinite, isTrue);
      expect(bbox.north.isFinite, isTrue);
      expect(bbox.east.isFinite, isTrue);
      expect(bbox.west.isFinite, isTrue);
    });

    test('horizon=200 m yields ~250 m of lat padding (within 10%)', () {
      // padded = 200 + 50 = 250 m. 250 / 111 320 ≈ 0.002245°.
      // Lat-delta is 2 × that.
      final bbox = ImminentSignalDetector.searchBoundingBox(paris, 200);
      final latDelta = bbox.north - bbox.south;
      expect(latDelta, closeTo(0.00449, 0.0005));
    });
  });

  group('ImminentSignalDetector.nextSignalAhead (#1125 phase 2)', () {
    // Hand-built user reading: Paris reference point, heading due
    // north (0°). We synthesise candidate signals at chosen
    // bearings/distances via _metreOffset.
    const userLat = 48.8566;
    const userLng = 2.3522;
    const headingNorth = 0.0;
    const headingEast = 90.0;

    GpsReading reading({double heading = headingNorth}) =>
        (latitude: userLat, longitude: userLng, headingDegrees: heading);

    TrafficSignal signalAt({
      required String id,
      required double metres,
      required double bearing,
    }) {
      final off = _metreOffset(
        lat: userLat,
        metres: metres,
        bearingDeg: bearing,
      );
      return TrafficSignal(
        id: id,
        lat: userLat + off.dLat,
        lng: userLng + off.dLng,
      );
    }

    test('no signals in bbox → null', () async {
      final repo = _StubRepo(response: const []);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
      expect(repo.callCount, 1);
    });

    test('one signal directly ahead within horizon → returned', () async {
      final ahead = signalAt(id: 'ahead', metres: 100, bearing: 0);
      final repo = _StubRepo(response: [ahead]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNotNull);
      expect(result!.id, 'ahead');
    });

    test('one signal directly behind → null (outside forward cone)', () async {
      final behind = signalAt(id: 'behind', metres: 100, bearing: 180);
      final repo = _StubRepo(response: [behind]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
    });

    test('one signal 90° off to the side → null', () async {
      final side = signalAt(id: 'side', metres: 100, bearing: 90);
      final repo = _StubRepo(response: [side]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
    });

    test('signal slightly off-cone (15°, within ±20°) → returned', () async {
      final slight = signalAt(id: 'slight', metres: 100, bearing: 15);
      final repo = _StubRepo(response: [slight]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNotNull);
      expect(result!.id, 'slight');
    });

    test('signal at 25° (just outside cone) → null', () async {
      final justOut = signalAt(id: 'justOut', metres: 100, bearing: 25);
      final repo = _StubRepo(response: [justOut]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
    });

    test('signal beyond the horizon → null', () async {
      final tooFar = signalAt(id: 'tooFar', metres: 350, bearing: 0);
      final repo = _StubRepo(response: [tooFar]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
    });

    test('multiple signals ahead → closest is returned', () async {
      final near = signalAt(id: 'near', metres: 80, bearing: 5);
      final mid = signalAt(id: 'mid', metres: 120, bearing: 0);
      final far = signalAt(id: 'far', metres: 180, bearing: -5);
      final repo = _StubRepo(response: [far, mid, near]);
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNotNull);
      expect(result!.id, 'near');
    });

    test(
      'heading wrap: due-east heading picks signal due east, not north',
      () async {
        final east = signalAt(id: 'east', metres: 100, bearing: 90);
        final north = signalAt(id: 'north', metres: 100, bearing: 0);
        final repo = _StubRepo(response: [north, east]);
        final detector = ImminentSignalDetector(repo: repo);
        final result = await detector.nextSignalAhead(
          reading(heading: headingEast),
        );
        expect(result, isNotNull);
        expect(result!.id, 'east');
      },
    );

    test('repo throws → returns null (under-trigger preference)', () async {
      final repo = _StubRepo(
        errorToThrow: const OsmTrafficSignalException('overpass down'),
      );
      final detector = ImminentSignalDetector(repo: repo);
      final result = await detector.nextSignalAhead(reading());
      expect(result, isNull);
      expect(repo.callCount, 1);
    });

    test(
      'custom horizon respected (50 m horizon excludes 100 m signal)',
      () async {
        final ahead = signalAt(id: 'ahead', metres: 100, bearing: 0);
        final repo = _StubRepo(response: [ahead]);
        final detector = ImminentSignalDetector(repo: repo, horizonMeters: 50);
        final result = await detector.nextSignalAhead(reading());
        expect(result, isNull);
      },
    );

    test('detector forwards a sane bbox to the repository', () async {
      final repo = _StubRepo(response: const []);
      final detector = ImminentSignalDetector(repo: repo);
      await detector.nextSignalAhead(reading());

      final bbox = repo.lastBbox;
      expect(bbox, isNotNull);
      expect(bbox!.south, lessThan(userLat));
      expect(bbox.north, greaterThan(userLat));
      expect(bbox.west, lessThan(userLng));
      expect(bbox.east, greaterThan(userLng));
    });
  });

  // The hive-backed repository contract is exercised separately in
  // traffic_signal_repository_test.dart. This sanity check pins the
  // stub against the same interface so a future refactor that breaks
  // the contract surfaces here too.
  test('_StubRepo implements TrafficSignalRepository', () {
    final repo = _StubRepo();
    expect(repo, isA<TrafficSignalRepository>());
  });
}
