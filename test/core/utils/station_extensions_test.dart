import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  final station = Station(
    id: '1',
    name: 'Test Station',
    brand: 'Shell',
    street: 'Main St',
    postCode: '12345',
    place: 'Berlin',
    lat: 52.5,
    lng: 13.4,
    dist: 2.5,
    isOpen: true,
    e5: 1.859,
    e10: 1.799,
    e98: 1.999,
    diesel: 1.659,
    dieselPremium: 1.759,
    e85: 0.899,
    lpg: 0.799,
    cng: 1.199,
  );

  group('priceFor', () {
    test('returns e5 for FuelType.e5', () {
      expect(station.priceFor(FuelType.e5), 1.859);
    });

    test('returns e10 for FuelType.e10', () {
      expect(station.priceFor(FuelType.e10), 1.799);
    });

    test('returns e98 for FuelType.e98', () {
      expect(station.priceFor(FuelType.e98), 1.999);
    });

    test('returns diesel for FuelType.diesel', () {
      expect(station.priceFor(FuelType.diesel), 1.659);
    });

    test('returns dieselPremium for FuelType.dieselPremium', () {
      expect(station.priceFor(FuelType.dieselPremium), 1.759);
    });

    test('returns e85 for FuelType.e85', () {
      expect(station.priceFor(FuelType.e85), 0.899);
    });

    test('returns lpg for FuelType.lpg', () {
      expect(station.priceFor(FuelType.lpg), 0.799);
    });

    test('returns cng for FuelType.cng', () {
      expect(station.priceFor(FuelType.cng), 1.199);
    });

    test('returns null for FuelType.hydrogen', () {
      expect(station.priceFor(FuelType.hydrogen), isNull);
    });

    test('returns null for FuelType.electric', () {
      expect(station.priceFor(FuelType.electric), isNull);
    });

    test('returns first available for FuelType.all (e10 priority)', () {
      expect(station.priceFor(FuelType.all), 1.799); // e10
    });

    test('FuelType.all falls back to e5 when e10 is null', () {
      final s = station.copyWith(e10: null);
      expect(s.priceFor(FuelType.all), 1.859); // e5
    });

    test('FuelType.all falls back to diesel when e10 and e5 are null', () {
      final s = station.copyWith(e10: null, e5: null);
      expect(s.priceFor(FuelType.all), 1.659); // diesel
    });

    test('FuelType.all returns null when all 3 are null', () {
      final s = station.copyWith(e10: null, e5: null, diesel: null);
      expect(s.priceFor(FuelType.all), isNull);
    });

    test('returns null for missing price', () {
      final s = Station(
        id: '2',
        name: 'Empty',
        brand: '',
        street: '',
        postCode: '',
        place: '',
        lat: 0,
        lng: 0,
        isOpen: true,
      );
      expect(s.priceFor(FuelType.e5), isNull);
      expect(s.priceFor(FuelType.diesel), isNull);
      expect(s.priceFor(FuelType.e10), isNull);
      expect(s.priceFor(FuelType.e98), isNull);
      expect(s.priceFor(FuelType.dieselPremium), isNull);
      expect(s.priceFor(FuelType.e85), isNull);
      expect(s.priceFor(FuelType.lpg), isNull);
      expect(s.priceFor(FuelType.cng), isNull);
    });
  });

  group('displayName', () {
    test('returns brand when available', () {
      expect(station.displayName, 'Shell');
    });

    test('returns place when brand is empty', () {
      final s = station.copyWith(brand: '');
      expect(s.displayName, 'Berlin');
    });

    test('returns place when brand is "Station"', () {
      final s = station.copyWith(brand: 'Station');
      expect(s.displayName, 'Berlin');
    });
  });

  group('displayAddress', () {
    test('returns street when no house number', () {
      expect(station.displayAddress, 'Main St');
    });

    test('includes house number', () {
      final s = station.copyWith(houseNumber: '42');
      expect(s.displayAddress, 'Main St 42');
    });
  });

  group('fullLocation', () {
    test('combines postCode and place', () {
      expect(station.fullLocation, '12345 Berlin');
    });
  });
}
