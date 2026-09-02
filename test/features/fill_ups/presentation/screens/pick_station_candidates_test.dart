// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/pick_station_candidates.dart';

/// #3906 — the picker's three sections assembled from cached data.
Station _station(String id, {double lat = 43.60, double lng = 3.88, double dist = 0}) =>
    Station(
      id: id,
      name: 'Name $id',
      brand: 'Brand $id',
      street: 'Rue $id',
      postCode: '34000',
      place: 'MONTPELLIER',
      lat: lat,
      lng: lng,
      dist: dist,
      e10: 1.8,
      diesel: 1.7,
    );

FillUp _fillUp(String id, DateTime date,
        {String? stationId, String? vehicleId, bool correction = false}) =>
    FillUp(
      id: id,
      date: date,
      liters: 30,
      totalCost: 50,
      odometerKm: 100000,
      fuelType: FuelType.e10,
      stationId: stationId,
      stationName: stationId == null ? null : 'Name-from-fill-up $stationId',
      vehicleId: vehicleId,
      isCorrection: correction,
    );

void main() {
  group('buildPickStationCandidates — last station', () {
    test('picks the most recent fill-up of the active vehicle with a '
        'station; corrections and other vehicles are ignored', () {
      final c = buildPickStationCandidates(
        fillUps: [
          _fillUp('a', DateTime(2026, 8, 1), stationId: 's1', vehicleId: 'v1'),
          _fillUp('b', DateTime(2026, 8, 21), stationId: 's2', vehicleId: 'v2'),
          _fillUp('c', DateTime(2026, 8, 22),
              stationId: 's3', vehicleId: 'v1', correction: true),
          _fillUp('d', DateTime(2026, 8, 23), vehicleId: 'v1'), // no station
        ],
        vehicleId: 'v1',
        favorites: const [],
        searchResults: const [],
        position: null,
      );
      expect(c.last?.id, 's1');
      expect(c.last?.lastFillUpDate, DateTime(2026, 8, 1));
      // Unknown to favorites / cache: title falls back to the fill-up's
      // own station name, no address, no Station for price pre-fill.
      expect(c.last?.title, 'Name-from-fill-up s1');
      expect(c.last?.station, isNull);
      expect(c.last?.priceFor(FuelType.e10), isNull);
    });

    test('resolves the cached Station (favorites first) for price + address',
        () {
      final c = buildPickStationCandidates(
        fillUps: [_fillUp('a', DateTime(2026, 8, 1), stationId: 's1')],
        vehicleId: null,
        favorites: [_station('s1')],
        searchResults: const [],
        position: null,
      );
      expect(c.last?.title, 'Brand s1');
      expect(c.last?.address, 'Rue s1 • MONTPELLIER');
      expect(c.last?.priceFor(FuelType.e10), 1.8);
      expect(c.last?.priceFor(FuelType.diesel), 1.7);
      // Not repeated under Favorites.
      expect(c.favorites, isEmpty);
    });

    test('null without any station-bearing fill-up', () {
      final c = buildPickStationCandidates(
        fillUps: [_fillUp('d', DateTime(2026, 8, 23))],
        vehicleId: null,
        favorites: const [],
        searchResults: const [],
        position: null,
      );
      expect(c.last, isNull);
    });
  });

  group('buildPickStationCandidates — nearby', () {
    test('orders by distance from the position, caps at 10, excludes '
        'favorites and the last station', () {
      final results = [
        for (var i = 0; i < 14; i++)
          _station('n$i', lat: 43.60 + 0.01 * (14 - i)),
        _station('fav'),
        _station('last'),
      ];
      final c = buildPickStationCandidates(
        fillUps: [_fillUp('a', DateTime(2026, 8, 1), stationId: 'last')],
        vehicleId: null,
        favorites: [_station('fav')],
        searchResults: results,
        position: (lat: 43.60, lng: 3.88),
      );
      expect(c.nearby.length, kPickStationNearbyLimit);
      expect(c.nearby.first.id, 'n13');
      expect(c.nearby.map((e) => e.id), isNot(contains('fav')));
      expect(c.nearby.map((e) => e.id), isNot(contains('last')));
      expect(c.nearby.map((e) => e.id), isNot(contains('n0')));
      // Distances are monotonically non-decreasing.
      for (var i = 1; i < c.nearby.length; i++) {
        expect(c.nearby[i].distanceKm!,
            greaterThanOrEqualTo(c.nearby[i - 1].distanceKm!));
      }
      expect(c.nearby.first.distanceKm!, closeTo(1.11, 0.05));
    });

    test('without a position falls back to the result\'s own dist', () {
      final c = buildPickStationCandidates(
        fillUps: const [],
        vehicleId: null,
        favorites: const [],
        searchResults: [_station('far', dist: 5), _station('near', dist: 1.2)],
        position: null,
      );
      expect(c.nearby.map((e) => e.id), ['near', 'far']);
      expect(c.nearby.first.distanceKm, 1.2);
    });

    test('empty search cache → empty nearby (no network call implied)', () {
      final c = buildPickStationCandidates(
        fillUps: const [],
        vehicleId: null,
        favorites: [_station('fav')],
        searchResults: const [],
        position: (lat: 43.60, lng: 3.88),
      );
      expect(c.nearby, isEmpty);
      expect(c.favorites.single.id, 'fav');
      expect(c.favorites.single.distanceKm, isNotNull);
    });
  });
}
