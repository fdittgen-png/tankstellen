// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_utils.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Helper to create a Station with sensible defaults and optional price overrides.
Station _makeStation({
  String id = 'test-id',
  String name = 'Test Station',
  String brand = 'TestBrand',
  String street = 'Teststraße',
  String? houseNumber,
  String postCode = '10115',
  String place = 'Berlin',
  double lat = 52.52,
  double lng = 13.405,
  double dist = 1.0,
  double? e5,
  double? e10,
  double? e98,
  double? diesel,
  double? dieselPremium,
  double? e85,
  double? lpg,
  double? cng,
  bool isOpen = true,
}) {
  return Station(
    id: id,
    name: name,
    brand: brand,
    street: street,
    houseNumber: houseNumber,
    postCode: postCode,
    place: place,
    lat: lat,
    lng: lng,
    dist: dist,
    e5: e5,
    e10: e10,
    e98: e98,
    diesel: diesel,
    dieselPremium: dieselPremium,
    e85: e85,
    lpg: lpg,
    cng: cng,
    isOpen: isOpen,
  );
}

void main() {
  // #2170 — priceForFuelType now delegates to Station.priceFor. This
  // parity test locks the two in lockstep so a new FuelType added to
  // only one switch can never silently diverge again.
  group('priceForFuelType ≡ Station.priceFor (single source)', () {
    test('agrees with the extension for every FuelType value', () {
      final s = _makeStation(
        e5: 1.659,
        e10: 1.599,
        e98: 1.899,
        diesel: 1.549,
        dieselPremium: 1.749,
        e85: 0.899,
        lpg: 0.799,
        cng: 1.199,
      );
      for (final ft in FuelType.values) {
        expect(
          priceForFuelType(s, ft),
          equals(s.priceFor(ft)),
          reason: 'priceForFuelType must delegate to priceFor for $ft',
        );
      }
    });
  });

  // #2182 — single source for the three (min,max) price-range loops.
  group('priceRange', () {
    test('returns (min, max) across stations', () {
      final stations = [
        _makeStation(e10: 1.799),
        _makeStation(e10: 1.659),
        _makeStation(e10: 1.899),
      ];
      expect(priceRange(stations, FuelType.e10), (1.659, 1.899));
    });

    test('returns (0, 0) when no station has a price', () {
      final stations = [_makeStation(), _makeStation()];
      expect(priceRange(stations, FuelType.e10), (0.0, 0.0));
    });

    test('default accepts any non-null price incl. zero/negative '
        '(map/driving behaviour)', () {
      final stations = [_makeStation(e10: 0.0), _makeStation(e10: 1.5)];
      // requirePositive defaults false → 0.0 is counted as the min.
      expect(priceRange(stations, FuelType.e10), (0.0, 1.5));
    });

    test('requirePositive excludes zero / sentinel prices '
        '(search-list behaviour)', () {
      final stations = [_makeStation(e10: 0.0), _makeStation(e10: 1.5)];
      expect(
        priceRange(stations, FuelType.e10, requirePositive: true),
        (1.5, 1.5),
      );
    });
  });

  group('priceForFuelType', () {
    test('returns e5 price for FuelType.e5', () {
      final station = _makeStation(e5: 1.659);
      expect(priceForFuelType(station, FuelType.e5), equals(1.659));
    });

    test('returns e10 price for FuelType.e10', () {
      final station = _makeStation(e10: 1.599);
      expect(priceForFuelType(station, FuelType.e10), equals(1.599));
    });

    test('returns e98 price for FuelType.e98', () {
      final station = _makeStation(e98: 1.899);
      expect(priceForFuelType(station, FuelType.e98), equals(1.899));
    });

    test('returns diesel price for FuelType.diesel', () {
      final station = _makeStation(diesel: 1.479);
      expect(priceForFuelType(station, FuelType.diesel), equals(1.479));
    });

    test('returns dieselPremium price for FuelType.dieselPremium', () {
      final station = _makeStation(dieselPremium: 1.559);
      expect(priceForFuelType(station, FuelType.dieselPremium), equals(1.559));
    });

    test('returns e85 price for FuelType.e85', () {
      final station = _makeStation(e85: 0.899);
      expect(priceForFuelType(station, FuelType.e85), equals(0.899));
    });

    test('returns lpg price for FuelType.lpg', () {
      final station = _makeStation(lpg: 0.729);
      expect(priceForFuelType(station, FuelType.lpg), equals(0.729));
    });

    test('returns cng price for FuelType.cng', () {
      final station = _makeStation(cng: 1.199);
      expect(priceForFuelType(station, FuelType.cng), equals(1.199));
    });

    test('returns null for FuelType.hydrogen (always)', () {
      final station = _makeStation(e5: 1.5, diesel: 1.4);
      expect(priceForFuelType(station, FuelType.hydrogen), isNull);
    });

    test('returns first available of e10/e5/diesel for FuelType.all', () {
      // Has e10 — should return e10
      final s1 = _makeStation(e10: 1.599, e5: 1.659, diesel: 1.479);
      expect(priceForFuelType(s1, FuelType.all), equals(1.599));

      // No e10, has e5 — should return e5
      final s2 = _makeStation(e5: 1.659, diesel: 1.479);
      expect(priceForFuelType(s2, FuelType.all), equals(1.659));

      // Only diesel — should return diesel
      final s3 = _makeStation(diesel: 1.479);
      expect(priceForFuelType(s3, FuelType.all), equals(1.479));

      // None — should return null
      final s4 = _makeStation();
      expect(priceForFuelType(s4, FuelType.all), isNull);
    });

    test('returns null when requested fuel type has no price', () {
      final station = _makeStation(diesel: 1.479); // only diesel set
      expect(priceForFuelType(station, FuelType.e5), isNull);
      expect(priceForFuelType(station, FuelType.e10), isNull);
      expect(priceForFuelType(station, FuelType.lpg), isNull);
    });
  });

  group('compareByPrice', () {
    test('station with lower price sorts first', () {
      final cheap = _makeStation(id: 'cheap', e10: 1.499);
      final expensive = _makeStation(id: 'expensive', e10: 1.699);
      expect(compareByPrice(cheap, expensive, FuelType.e10), lessThan(0));
    });

    test('stations with equal price compare as equal', () {
      final a = _makeStation(id: 'a', e10: 1.599);
      final b = _makeStation(id: 'b', e10: 1.599);
      expect(compareByPrice(a, b, FuelType.e10), equals(0));
    });

    test('station without price sorts last (uses 999)', () {
      final hasPrice = _makeStation(id: 'has', e10: 1.599);
      final noPrice = _makeStation(id: 'no');
      expect(compareByPrice(hasPrice, noPrice, FuelType.e10), lessThan(0));
      expect(compareByPrice(noPrice, hasPrice, FuelType.e10), greaterThan(0));
    });

    test('two stations without price compare as equal', () {
      final a = _makeStation(id: 'a');
      final b = _makeStation(id: 'b');
      expect(compareByPrice(a, b, FuelType.e10), equals(0));
    });
  });

  group('compareByName', () {
    test('alphabetical ordering by displayName', () {
      final aral = _makeStation(id: 'a', brand: 'Aral');
      final total = _makeStation(id: 't', brand: 'TotalEnergies');
      expect(compareByName(aral, total), lessThan(0));
      expect(compareByName(total, aral), greaterThan(0));
    });

    test('comparison is case-insensitive', () {
      final lower = _makeStation(id: 'l', brand: 'aral');
      final upper = _makeStation(id: 'u', brand: 'ARAL');
      expect(compareByName(lower, upper), equals(0));
    });

    test('same name compares as equal', () {
      final a = _makeStation(id: 'a', brand: 'Shell');
      final b = _makeStation(id: 'b', brand: 'Shell');
      expect(compareByName(a, b), equals(0));
    });
  });

  group('Station.displayName extension', () {
    test('uses brand when brand is non-empty and not "Station"', () {
      final station = _makeStation(brand: 'Aral', place: 'Berlin');
      expect(station.displayName, equals('Aral'));
    });

    test('falls back to street when brand is empty', () {
      final station = _makeStation(brand: '', place: 'München');
      expect(station.displayName, equals('Teststraße'));
    });

    test('falls back to street when brand is "Station"', () {
      final station = _makeStation(brand: 'Station', place: 'Hamburg');
      expect(station.displayName, equals('Teststraße'));
    });
  });

  group('Station.displayAddress extension', () {
    test('includes house number when present', () {
      final station = _makeStation(street: 'Hauptstraße', houseNumber: '42');
      expect(station.displayAddress, equals('Hauptstraße 42'));
    });

    test('returns only street when house number is null', () {
      final station = _makeStation(street: 'Bahnhofstraße', houseNumber: null);
      expect(station.displayAddress, equals('Bahnhofstraße'));
    });
  });

  group('Station.fullLocation extension', () {
    test('combines postCode and place', () {
      final station = _makeStation(postCode: '10115', place: 'Berlin');
      expect(station.fullLocation, equals('10115 Berlin'));
    });

    test('works with different postal codes', () {
      final station = _makeStation(postCode: '80331', place: 'München');
      expect(station.fullLocation, equals('80331 München'));
    });
  });

  group('bestDisplayPrice (#2400)', () {
    test('returns the selected fuel price when present, labelled as it', () {
      final s = _makeStation(e10: 1.599, diesel: 1.549);
      final r = bestDisplayPrice(s, FuelType.e10);
      expect(r, isNotNull);
      expect(r!.price, 1.599);
      expect(r.shownFuel, FuelType.e10);
    });

    test('falls back to the first available fuel when selected is null', () {
      // Diesel-only station while E10 is selected — the recurring "--"
      // case. Must resolve to the diesel price, labelled diesel.
      final s = _makeStation(diesel: 1.699);
      final r = bestDisplayPrice(s, FuelType.e10);
      expect(r, isNotNull);
      expect(r!.price, 1.699);
      expect(r.shownFuel, FuelType.diesel);
    });

    test('fallback honours E10→E5→Diesel→…→CNG priority order', () {
      // Selected = CNG (null); E5 + LPG present. E5 wins (earlier in the
      // priority order than LPG).
      final s = _makeStation(e5: 1.859, lpg: 0.799);
      final r = bestDisplayPrice(s, FuelType.cng);
      expect(r!.shownFuel, FuelType.e5);
      expect(r.price, 1.859);
    });

    test('returns null only when the station has no usable price', () {
      final s = _makeStation();
      expect(bestDisplayPrice(s, FuelType.e10), isNull);
    });
  });

  group('resolvedPriceRange (#2400)', () {
    test('ranges over each station\'s resolved display price', () {
      final stations = [
        _makeStation(id: 'a', diesel: 1.50), // E10 null → diesel 1.50
        _makeStation(id: 'b', e10: 1.70), // E10 present → 1.70
        _makeStation(id: 'c', e5: 1.90), // E10 null → e5 1.90
      ];
      final (min, max) = resolvedPriceRange(stations, FuelType.e10);
      expect(min, 1.50);
      expect(max, 1.90);
    });

    test('returns (0, 0) when no station resolves to a price', () {
      final stations = [_makeStation(id: 'x'), _makeStation(id: 'y')];
      expect(resolvedPriceRange(stations, FuelType.e10), (0, 0));
    });
  });

  group('shortFuelLabel (#2400)', () {
    test('maps fuels to their language-neutral pump codes', () {
      expect(shortFuelLabel(FuelType.e10), 'E10');
      expect(shortFuelLabel(FuelType.e5), 'E5');
      expect(shortFuelLabel(FuelType.diesel), 'Diesel');
      expect(shortFuelLabel(FuelType.dieselPremium), 'Diesel+');
      expect(shortFuelLabel(FuelType.lpg), 'GPL');
      expect(shortFuelLabel(FuelType.cng), 'GNV');
    });
  });
}
