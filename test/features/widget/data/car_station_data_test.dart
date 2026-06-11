// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/price_band_colors.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/widget/data/car_station_data.dart';

/// Android Auto v1 (#2948 / epic #2946) — proves the car-data write helper
/// serializes the Search / Radar station lists to the JSON contract the native
/// Kotlin car screens read (id / name / brand / lat / lng / price / band /
/// bandColor / distance / fuelLabel), driven by real [Station] fixtures.
void main() {
  Station station({
    required String id,
    required String brand,
    required double lat,
    required double lng,
    required double dist,
    double? e10,
    double? diesel,
    String street = 'Main St 1',
    String postCode = '10115',
    String place = 'Berlin',
  }) =>
      Station(
        id: id,
        name: '$brand forecourt',
        brand: brand,
        street: street,
        postCode: postCode,
        place: place,
        lat: lat,
        lng: lng,
        dist: dist,
        e10: e10,
        diesel: diesel,
        isOpen: true,
      );

  int argb(Color c) {
    int ch(double v) => (v * 255.0).round() & 0xff;
    return (ch(c.a) << 24) | (ch(c.r) << 16) | (ch(c.g) << 8) | ch(c.b);
  }

  group('CarStationData.encode', () {
    test('serializes the full per-station contract', () {
      final json = CarStationData.encode(
        [station(id: 's1', brand: 'Aral', lat: 52.5, lng: 13.4, dist: 1.23, e10: 1.799)],
        FuelType.e10,
      );
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      expect(rows, hasLength(1));
      final r = rows.single;
      expect(r['id'], 's1');
      expect(r['brand'], 'Aral');
      expect(r['name'], 'Aral'); // displayName prefers brand
      expect(r['lat'], 52.5);
      expect(r['lng'], 13.4);
      expect(r['price'], 1.799);
      expect(r['priceText'], '1.799');
      expect(r['fuelLabel'], 'E10');
      expect(r['distanceKm'], 1.2); // rounded to 1 dp
      expect(r.containsKey('band'), isTrue);
      expect(r.containsKey('bandColor'), isTrue);
      // #2947 slice 3 — street + city address subtitle, like the in-app card.
      expect(r['address'], 'Main St 1, 10115 Berlin');
    });

    test('address collapses empty parts (no orphan comma, #2704)', () {
      // No street → city only.
      final cityOnly = CarStationData.encode(
        [
          station(id: 'a', brand: 'A', lat: 1, lng: 1, dist: 1, e10: 1.5,
              street: '', postCode: '10117', place: 'Berlin'),
        ],
        FuelType.e10,
      );
      expect(
        (jsonDecode(cityOnly) as List).cast<Map<String, dynamic>>().single['address'],
        '10117 Berlin',
      );

      // No street and no city → empty address (the Kotlin row shows no subtitle).
      final none = CarStationData.encode(
        [
          station(id: 'b', brand: 'B', lat: 1, lng: 1, dist: 1, e10: 1.5,
              street: '', postCode: '', place: ''),
        ],
        FuelType.e10,
      );
      expect(
        (jsonDecode(none) as List).cast<Map<String, dynamic>>().single['address'],
        '',
      );
    });

    test('cheapest station is the cheap band, most expensive the expensive band',
        () {
      final json = CarStationData.encode(
        [
          station(id: 'cheap', brand: 'A', lat: 1, lng: 1, dist: 0.5, e10: 1.50),
          station(id: 'mid', brand: 'B', lat: 2, lng: 2, dist: 1.0, e10: 1.70),
          station(id: 'exp', brand: 'C', lat: 3, lng: 3, dist: 2.0, e10: 1.90),
        ],
        FuelType.e10,
      );
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      expect(rows[0]['band'], 'cheap');
      expect(rows[0]['bandColor'], argb(PriceBandColors.cheap));
      expect(rows[2]['band'], 'expensive');
      expect(rows[2]['bandColor'], argb(PriceBandColors.expensive));
    });

    test('unpriced station → null price, empty priceText, unknown band', () {
      final json = CarStationData.encode(
        [station(id: 'x', brand: 'Z', lat: 1, lng: 1, dist: 1.0, diesel: 1.6)],
        FuelType.e10, // station has no e10
      );
      final r = (jsonDecode(json) as List).cast<Map<String, dynamic>>().single;
      expect(r['price'], isNull);
      expect(r['priceText'], '');
      expect(r['band'], 'unknown');
    });

    test('uses the selected fuel for the price + label', () {
      final json = CarStationData.encode(
        [station(id: 'd', brand: 'D', lat: 1, lng: 1, dist: 1.0, e10: 1.8, diesel: 1.6)],
        FuelType.diesel,
      );
      final r = (jsonDecode(json) as List).cast<Map<String, dynamic>>().single;
      expect(r['price'], 1.6);
      expect(r['fuelLabel'], 'Diesel');
    });

    test('caps the list at maxStations', () {
      final many = List.generate(
        CarStationData.maxStations + 5,
        (i) => station(id: 's$i', brand: 'B$i', lat: 1, lng: 1, dist: i.toDouble(), e10: 1.5),
      );
      final rows = (jsonDecode(CarStationData.encode(many, FuelType.e10)) as List);
      expect(rows, hasLength(CarStationData.maxStations));
    });

    test('empty list serializes to an empty JSON array', () {
      expect(CarStationData.encode(const [], FuelType.e10), '[]');
    });
  });
}
