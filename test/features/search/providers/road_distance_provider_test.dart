// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3634 — real road distances: the OSRM /table parser, and the
// enrichment notifier's movement/time gate + merge + silent degrade.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/route_search/data/services/routing_service.dart';
import 'package:tankstellen/features/search/providers/road_distance_provider.dart';

import '../../../helpers/silence_error_logger.dart';

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
  silenceErrorLoggerSpool();

  group('parseOsrmTableDistancesKm', () {
    test('happy matrix: metres → km, origin cell skipped', () {
      final r = parseOsrmTableDistancesKm({
        'code': 'Ok',
        'distances': [
          [0, 12300.0, 4500.0],
        ],
      }, destinationCount: 2);
      expect(r, [12.3, 4.5]);
    });

    test('unreachable destination is null, others survive', () {
      final r = parseOsrmTableDistancesKm({
        'code': 'Ok',
        'distances': [
          [0, null, 800.0],
        ],
      }, destinationCount: 2);
      expect(r, [null, 0.8]);
    });

    test('missing matrix / bad code / short row → all null (never '
        'durations-as-distance)', () {
      expect(
        parseOsrmTableDistancesKm({'code': 'Ok'}, destinationCount: 2),
        [null, null],
      );
      expect(
        parseOsrmTableDistancesKm(
            {'code': 'NoTable', 'distances': <List<num?>>[]},
            destinationCount: 1),
        [null],
      );
      expect(
        parseOsrmTableDistancesKm({
          'code': 'Ok',
          'distances': [
            [0, 500.0],
          ],
        }, destinationCount: 3),
        [0.5, null, null],
      );
    });
  });

  group('RoadDistances notifier', () {
    test('fetches the top-N, merges by id, and gates the next refresh '
        'until moved/aged', () async {
      var calls = 0;
      final container = ProviderContainer(overrides: [
        roadDistanceFetcherProvider.overrideWithValue(
          (lat, lng, bearing, dests) async {
            calls++;
            return [for (var i = 0; i < dests.length; i++) 10.0 + i];
          },
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(roadDistancesProvider.notifier);
      final ranked = [
        _station('a', 43.01, 3.0),
        _station('b', 43.02, 3.0),
      ];

      await notifier.refresh(lat: 43.0, lng: 3.0, ranked: ranked);
      expect(calls, 1);
      expect(container.read(roadDistancesProvider),
          {'a': 10.0, 'b': 11.0});

      // Same spot, immediately: gated.
      await notifier.refresh(lat: 43.0001, lng: 3.0, ranked: ranked);
      expect(calls, 1, reason: '<500 m and <60 s — no refetch');

      // Moved 1 km: refetches and merges.
      await notifier.refresh(lat: 43.009, lng: 3.0, ranked: ranked);
      expect(calls, 2);
    });

    test('a fetch failure is silent — existing distances survive',
        () async {
      var fail = false;
      final container = ProviderContainer(overrides: [
        roadDistanceFetcherProvider.overrideWithValue(
          (lat, lng, bearing, dests) async {
            if (fail) throw Exception('osrm down');
            return [7.7];
          },
        ),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(roadDistancesProvider.notifier);
      final ranked = [_station('a', 43.01, 3.0)];

      await notifier.refresh(lat: 43.0, lng: 3.0, ranked: ranked);
      expect(container.read(roadDistancesProvider), {'a': 7.7});

      fail = true;
      await notifier.refresh(lat: 43.1, lng: 3.0, ranked: ranked);
      expect(container.read(roadDistancesProvider), {'a': 7.7},
          reason: 'routing is garnish — a failure must change nothing');
    });
  });

  group('#3637 direction-aware bearings', () {
    test('osrmTableParams: origin bearing + one empty entry per '
        'destination; absent when no bearing', () {
      final constrained = osrmTableParams(
          destinationCount: 3, originBearingDegrees: 271.6);
      expect(constrained['bearings'], '272,25;;;',
          reason: 'rounded heading, tolerance, 3 unconstrained slots');
      final free = osrmTableParams(destinationCount: 3);
      expect(free.containsKey('bearings'), isFalse);
      // Wrap-around + non-finite safety.
      expect(
          osrmTableParams(destinationCount: 1, originBearingDegrees: 365.0)[
              'bearings'],
          '5,25;');
      expect(
          osrmTableParams(
                  destinationCount: 1,
                  originBearingDegrees: double.nan)
              .containsKey('bearings'),
          isFalse);
    });

    test('osrmTableCoords is lon,lat ordered', () {
      expect(
        osrmTableCoords(43.0, 3.0, [(lat: 43.1, lng: 3.1)]),
        '3.0,43.0;3.1,43.1',
      );
    });

    test('the provider threads the heading to the fetch seam', () async {
      double? seenBearing;
      final container = ProviderContainer(overrides: [
        roadDistanceFetcherProvider.overrideWithValue(
          (lat, lng, bearing, dests) async {
            seenBearing = bearing;
            return [1.0];
          },
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(roadDistancesProvider.notifier).refresh(
        lat: 43.0,
        lng: 3.0,
        ranked: [_station('a', 43.01, 3.0)],
        headingDegrees: 88.0,
      );
      expect(seenBearing, 88.0);
    });
  });
}
