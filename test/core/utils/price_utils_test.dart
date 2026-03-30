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

    test('falls back to place when brand is empty', () {
      final station = _makeStation(brand: '', place: 'München');
      expect(station.displayName, equals('München'));
    });

    test('falls back to place when brand is "Station"', () {
      final station = _makeStation(brand: 'Station', place: 'Hamburg');
      expect(station.displayName, equals('Hamburg'));
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
}
