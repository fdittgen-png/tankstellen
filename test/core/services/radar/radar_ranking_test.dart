// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/core/services/radar/radar_ranking.dart';

/// #3267 — the single distance-ranking authority shared by every radar surface.
/// These pin the four guarantees the three providers used to each re-implement:
/// dedup (last wins), fuel-filter, live distance stamp, distance sort.
Station _s(String id, double lat, double lng, {double? e10, double? e85}) =>
    Station(
      id: id,
      name: id,
      brand: 'TEST',
      street: 'Teststr.',
      postCode: '00000',
      place: 'Test',
      lat: lat,
      lng: lng,
      e10: e10,
      e85: e85,
      isOpen: true,
    );

void main() {
  group('RadarRanking.rank', () {
    test('stamps live distance from the given point and sorts nearest-first',
        () {
      final out = RadarRanking.rank(
        [
          _s('FAR', 48.03, 2.0, e10: 1.8),
          _s('NEAR', 48.0, 2.0, e10: 1.6),
          _s('MID', 48.01, 2.0, e10: 1.7),
        ],
        lat: 48.0,
        lng: 2.0,
        fuel: FuelType.e10,
      );
      expect(out.map((s) => s.id), ['NEAR', 'MID', 'FAR']);
      expect(out.first.dist, lessThan(0.1));
      expect(out.last.dist, greaterThan(2.0));
    });

    test('dedups by id — the LATER (in-radius merge) row wins', () {
      final out = RadarRanking.rank(
        [
          _s('DUP', 48.0, 2.0, e10: 1.999), // corridor (first)
          _s('DUP', 48.0, 2.0, e10: 1.659), // in-radius (last) wins
        ],
        lat: 48.0,
        lng: 2.0,
        fuel: FuelType.e10,
      );
      expect(out, hasLength(1));
      expect(out.single.priceFor(FuelType.e10), 1.659);
    });

    test('default (requirePrice: false) uses the shared hard-fuel filter', () {
      final out = RadarRanking.rank(
        [
          _s('SELLS', 48.0, 2.0, e85: 0.84, e10: 1.77),
          _s('E10_ONLY', 48.01, 2.0, e10: 1.75), // no E85 → dropped
        ],
        lat: 48.0,
        lng: 2.0,
        fuel: FuelType.e85,
      );
      expect(out.map((s) => s.id), ['SELLS']);
    });

    test('FuelType.all keeps every station (requirePrice: false)', () {
      final out = RadarRanking.rank(
        [_s('A', 48.0, 2.0, e10: 1.5), _s('B', 48.01, 2.0)],
        lat: 48.0,
        lng: 2.0,
        fuel: FuelType.all,
      );
      expect(out.map((s) => s.id).toSet(), {'A', 'B'});
    });

    test('requirePrice: true drops rows unpriced for the fuel', () {
      final out = RadarRanking.rank(
        [
          _s('PRICED', 48.0, 2.0, e10: 1.6),
          _s('UNPRICED', 48.001, 2.0), // no price → dropped
        ],
        lat: 48.0,
        lng: 2.0,
        fuel: FuelType.e10,
        requirePrice: true,
      );
      expect(out.map((s) => s.id), ['PRICED']);
    });

    test('nearestPriced returns the closest priced station, else null', () {
      final stations = [
        _s('UNPRICED_NEAR', 48.0, 2.0), // closest but unpriced
        _s('PRICED_FAR', 48.02, 2.0, e10: 1.7),
      ];
      expect(
        RadarRanking.nearestPriced(stations, lat: 48.0, lng: 2.0, fuel: FuelType.e10)
            ?.id,
        'PRICED_FAR',
      );
      expect(
        RadarRanking.nearestPriced(
          [_s('NONE', 48.0, 2.0)],
          lat: 48.0,
          lng: 2.0,
          fuel: FuelType.e10,
        ),
        isNull,
      );
    });
  });
}
