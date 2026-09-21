// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/fill_ups/domain/services/next_fill_offers.dart';

/// #4324 — where the next-fill prices come from: the last search's stations
/// (with a distance, so the detour is priced), else the favourites.
Station _station(String id, {double dist = 0, double? e10, double? e85}) =>
    Station(
      id: id,
      name: id,
      brand: 'B',
      street: 'S',
      postCode: '00000',
      place: 'P',
      lat: 0,
      lng: 0,
      dist: dist,
      isOpen: true,
      e10: e10,
      e85: e85,
    );

void main() {
  const grades = [FuelGrade.e10, FuelGrade.e85];

  group('nearbySearchOffers', () {
    test('one offer per station and priced grade, naming station + km', () {
      final offers = nearbySearchOffers(grades, [
        FuelStationResult(_station('a', dist: 2.4, e10: 1.85, e85: 1.09)),
        FuelStationResult(_station('b', dist: 7.0, e85: 0.99)),
      ]);
      expect([
        for (final o in offers)
          (o.grade, o.pricePerLitre, o.station!.stationId, o.station!.oneWayKm)
      ], [
        (FuelGrade.e10, 1.85, 'a', 2.4),
        (FuelGrade.e85, 1.09, 'a', 2.4),
        (FuelGrade.e85, 0.99, 'b', 7.0),
      ]);
      expect(offerSourceOf(offers), NextFillOfferSource.nearbySearch);
    });

    test('grades the car cannot take and unusable distances are skipped', () {
      final offers = nearbySearchOffers(const [FuelGrade.e85], [
        FuelStationResult(_station('a', dist: 3, e10: 1.85)),
        FuelStationResult(_station('b', dist: double.nan, e85: 1.0)),
        FuelStationResult(_station('c', dist: -1, e85: 1.0)),
      ]);
      expect(offers, isEmpty);
    });
  });

  group('favouriteOffers', () {
    test('the cheapest price per grade, with no station attached', () {
      final offers = favouriteOffers(grades, [
        _station('a', e10: 1.899, e85: 1.099),
        _station('b', e10: 1.849, e85: 1.149),
      ]);
      expect({for (final o in offers) o.grade: o.pricePerLitre},
          {FuelGrade.e10: 1.849, FuelGrade.e85: 1.099});
      expect(offers.every((o) => o.station == null), isTrue);
      expect(offerSourceOf(offers), NextFillOfferSource.favourites);
    });
  });
}
