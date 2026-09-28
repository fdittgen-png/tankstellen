// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/utils/route_projection.dart';

/// #4432 — the one along-route calculation. At lat 48°, 0.1° of
/// longitude is ~7.44 km and 0.05° of latitude ~5.56 km; the fixtures
/// below are built from those two numbers.
void main() {
  /// One sparse 74 km segment, west → east along lat 48.
  final sparse = RouteProjection(const [LatLng(48.0, 2.0), LatLng(48.0, 3.0)]);

  /// Out east along lat 48.0, a 5.6 km hop north, back west along
  /// lat 48.05 — the U-turn shape.
  final uTurn = RouteProjection(const [
    LatLng(48.0, 2.0),
    LatLng(48.0, 3.0),
    LatLng(48.05, 3.0),
    LatLng(48.05, 2.0),
  ]);

  /// East to lng 2.6, north, west to lng 2.3, then south THROUGH the
  /// first leg at (48.0, 2.3): the route crosses itself there, first at
  /// ~22 km and again at ~111 km.
  final crossing = RouteProjection(const [
    LatLng(48.0, 2.0),
    LatLng(48.0, 2.6),
    LatLng(48.2, 2.6),
    LatLng(48.2, 2.3),
    LatLng(47.8, 2.3),
  ]);

  group('segment projection', () {
    test(
        'a station midway along a sparse segment has near-zero offset and '
        'intermediate progress', () {
      final at = sparse.project(48.0, 2.5);
      expect(at.offRouteKm, lessThan(0.05),
          reason: 'it sits ON the segment; the nearest VERTEX is 37 km away');
      expect(at.alongKm, closeTo(sparse.totalKm / 2, 0.2));
    });

    test('a small lateral offset is measured to the segment, not a vertex',
        () {
      final at = sparse.project(48.01, 2.5); // ~1.1 km north of the road
      expect(at.offRouteKm, closeTo(1.11, 0.05));
      expect(at.alongKm, closeTo(sparse.totalKm / 2, 0.2));
    });

    test('pointAtKm walks the same cumulative table', () {
      final mid = sparse.pointAtKm(sparse.totalKm / 2);
      expect(mid.longitude, closeTo(2.5, 0.001));
      expect(sparse.pointAtKm(-5), const LatLng(48.0, 2.0));
      expect(sparse.pointAtKm(1e6), const LatLng(48.0, 3.0));
    });
  });

  group('start and destination', () {
    test(
        'a candidate clamped to progress zero from BEHIND the start is not '
        'eligible, although its progress is >= 0', () {
      // ~7.4 km behind the start, on the extension of the first leg —
      // well inside a 15 km corridor.
      final pass = sparse.occurrences(48.0, 1.9).single;
      expect(pass.alongKm, 0, reason: 'the clamp the contract warns about');
      expect(pass.status, RouteProjectionStatus.beforeStart);
      expect(pass.overhangKm, closeTo(7.44, 0.1));
      expect(pass.isBehindStart, isTrue);
      expect(sparse.itineraryOccurrence(48.0, 1.9, corridorKm: 15), isNull);
    });

    test('a reachable stop AT the origin is not blanket-rejected', () {
      // 150 m behind the start (inside the GPS tolerance) and one 200 m
      // to the side of it: both are where the driver is.
      final justBehind =
          sparse.itineraryOccurrence(48.0, 1.998, corridorKm: 15);
      expect(justBehind, isNotNull);
      expect(justBehind!.alongKm, 0);

      final beside = sparse.itineraryOccurrence(48.0018, 2.0, corridorKm: 15);
      expect(beside, isNotNull);
      expect(beside!.status, RouteProjectionStatus.onRoute);
    });

    test(
        'behind-start rejection follows the heading the driver leaves on, '
        'not a stub first segment', () {
      // A 20 m stub pointing NORTH out of a car park, then the route
      // runs east. A station 3 km west is behind the driver's heading
      // even though it is beside the stub.
      final stub = RouteProjection(const [
        LatLng(48.0, 2.0),
        LatLng(48.00018, 2.0),
        LatLng(48.00018, 3.0),
      ]);
      expect(stub.itineraryOccurrence(48.00018, 1.96, corridorKm: 15),
          isNull);
    });

    test(
        'a candidate past the destination keeps its pass at the end, with '
        'the overhang counted as offset', () {
      // ~3.7 km beyond the end of the route.
      final pass = sparse.itineraryOccurrence(48.0, 3.05, corridorKm: 15);
      expect(pass, isNotNull);
      expect(pass!.status, RouteProjectionStatus.beyondEnd);
      expect(pass.alongKm, closeTo(sparse.totalKm, 0.01));
      expect(pass.offRouteKm, closeTo(3.72, 0.1));
      // A tighter corridor excludes it on that same offset.
      expect(sparse.itineraryOccurrence(48.0, 3.05, corridorKm: 2), isNull);
    });
  });

  group('repeated passes', () {
    test('a U-turn route passes a roadside station twice', () {
      final passes = uTurn.occurrences(48.0, 2.2, withinKm: 15);
      expect(passes, hasLength(2));
      expect(passes.first.alongKm, closeTo(14.9, 0.3));
      expect(passes.first.offRouteKm, lessThan(0.05));
      expect(passes.last.alongKm, greaterThan(130));
      expect(passes.last.offRouteKm, closeTo(5.56, 0.1));
    });

    test('from the start, the first pass orders the station', () {
      final pass = uTurn.itineraryOccurrence(48.0, 2.2, corridorKm: 15);
      expect(pass!.alongKm, closeTo(14.9, 0.3));
    });

    test(
        'once the first pass is retired, the station stays eligible on the '
        'return leg — it is not resurrected at the old progress, nor lost',
        () {
      final pass = uTurn.itineraryOccurrence(48.0, 2.2,
          corridorKm: 15, fromKm: 30);
      expect(pass, isNotNull);
      expect(pass!.alongKm, greaterThan(130));
    });

    test(
        'a much closer LATER pass is not shadowed by a distant first brush',
        () {
      // Beside the RETURN leg, 5.6 km from the outbound one.
      final pass = uTurn.itineraryOccurrence(48.05, 2.2, corridorKm: 15);
      expect(pass!.offRouteKm, lessThan(0.05));
      expect(pass.alongKm, greaterThan(130));
    });

    test(
        'at a crossing the same point is two occurrences at different '
        'progress, and the later one survives retirement of the first', () {
      final passes = crossing.occurrences(48.0, 2.3, withinKm: 1);
      expect(passes, hasLength(2));
      expect(passes.first.alongKm, closeTo(22.3, 0.3));
      expect(passes.last.alongKm, closeTo(111.4, 0.6));

      final later =
          crossing.itineraryOccurrence(48.0, 2.3, corridorKm: 15, fromKm: 60);
      expect(later!.alongKm, closeTo(111.4, 0.6),
          reason: 'geographically behind a driver at km 60, but the route '
              'legitimately meets it again later');
    });

    test('project() reports the itinerary pass, not a global nearest vertex',
        () {
      final at = uTurn.project(48.05, 2.2);
      expect(at.alongKm, greaterThan(130));
      expect(at.offRouteKm, lessThan(0.05));
    });
  });

  test('empty and single-point routes do not throw', () {
    final empty = RouteProjection(const []);
    expect(empty.project(48, 2), (alongKm: 0.0, offRouteKm: 0.0));
    expect(empty.occurrences(48, 2), isEmpty);
    expect(empty.itineraryOccurrence(48, 2), isNull);

    final single = RouteProjection(const [LatLng(48, 2)]);
    expect(single.project(48, 2.1).offRouteKm, closeTo(7.44, 0.1));
  });
}
