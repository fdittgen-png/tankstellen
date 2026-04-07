import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/station_extensions.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';

void main() {
  group('Station.fromJson roundtrip', () {
    test('Station.fromJson then toJson roundtrips correctly', () {
      final json = testStation.toJson();
      final roundtripped = Station.fromJson(json);

      expect(roundtripped.id, testStation.id);
      expect(roundtripped.name, testStation.name);
      expect(roundtripped.brand, testStation.brand);
      expect(roundtripped.street, testStation.street);
      expect(roundtripped.houseNumber, testStation.houseNumber);
      expect(roundtripped.postCode, testStation.postCode);
      expect(roundtripped.place, testStation.place);
      expect(roundtripped.lat, testStation.lat);
      expect(roundtripped.lng, testStation.lng);
      expect(roundtripped.e5, testStation.e5);
      expect(roundtripped.e10, testStation.e10);
      expect(roundtripped.diesel, testStation.diesel);
      expect(roundtripped.isOpen, testStation.isOpen);
    });

    test('toJson produces valid map with all required fields', () {
      final json = testStation.toJson();

      expect(json['id'], isNotNull);
      expect(json['name'], isA<String>());
      expect(json['brand'], isA<String>());
      expect(json['lat'], isA<double>());
      expect(json['lng'], isA<double>());
      expect(json['isOpen'], isA<bool>());
    });
  });

  group('Station.priceFor', () {
    test('returns correct price for each fuel type', () {
      expect(testStation.priceFor(FuelType.e5), 1.859);
      expect(testStation.priceFor(FuelType.e10), 1.799);
      expect(testStation.priceFor(FuelType.diesel), 1.659);
    });

    test('returns null for unavailable fuel types', () {
      expect(testStation.priceFor(FuelType.e98), isNull);
      expect(testStation.priceFor(FuelType.lpg), isNull);
      expect(testStation.priceFor(FuelType.cng), isNull);
      expect(testStation.priceFor(FuelType.hydrogen), isNull);
      expect(testStation.priceFor(FuelType.electric), isNull);
    });

    test('FuelType.all returns first available: E10 priority', () {
      // testStation has e10 = 1.799, so "all" should return e10
      expect(testStation.priceFor(FuelType.all), 1.799);
    });

    test('FuelType.all falls back to E5 when E10 is null', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        e5: 1.899,
        e10: null,
        diesel: 1.699,
        isOpen: true,
      );
      expect(station.priceFor(FuelType.all), 1.899);
    });

    test('FuelType.all falls back to diesel when E10 and E5 are null', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        e5: null,
        e10: null,
        diesel: 1.699,
        isOpen: true,
      );
      expect(station.priceFor(FuelType.all), 1.699);
    });

    test('FuelType.all returns null when no prices available', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: false,
      );
      expect(station.priceFor(FuelType.all), isNull);
    });

    test('handles station with all prices set', () {
      const station = Station(
        id: 'test',
        name: 'Full Station',
        brand: 'FULL',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        e5: 1.859,
        e10: 1.799,
        e98: 1.999,
        diesel: 1.659,
        dieselPremium: 1.759,
        e85: 0.899,
        lpg: 0.799,
        cng: 1.299,
        isOpen: true,
      );

      expect(station.priceFor(FuelType.e5), 1.859);
      expect(station.priceFor(FuelType.e10), 1.799);
      expect(station.priceFor(FuelType.e98), 1.999);
      expect(station.priceFor(FuelType.diesel), 1.659);
      expect(station.priceFor(FuelType.dieselPremium), 1.759);
      expect(station.priceFor(FuelType.e85), 0.899);
      expect(station.priceFor(FuelType.lpg), 0.799);
      expect(station.priceFor(FuelType.cng), 1.299);
    });
  });

  group('Station.displayName', () {
    test('returns brand when brand is meaningful', () {
      expect(testStation.displayName, 'STAR');
    });

    test('returns street when brand is empty', () {
      const station = Station(
        id: 'test',
        name: 'Name',
        brand: '',
        street: 'Hauptstr.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station.displayName, 'Hauptstr.');
    });

    test('returns street when brand is generic "Station"', () {
      const station = Station(
        id: 'test',
        name: 'Name',
        brand: 'Station',
        street: 'Hauptstr.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station.displayName, 'Hauptstr.');
    });

    test('returns name when brand and street are empty', () {
      const station = Station(
        id: 'test',
        name: 'My Station',
        brand: '',
        street: '',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station.displayName, 'My Station');
    });

    test('returns place as last fallback', () {
      const station = Station(
        id: 'test',
        name: '',
        brand: '',
        street: '',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station.displayName, 'Berlin');
    });
  });

  group('Station.displayAddress', () {
    test('includes house number when available', () {
      expect(testStation.displayAddress, 'Hauptstr. 12');
    });

    test('returns only street when no house number', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'Berliner Str.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station.displayAddress, 'Berliner Str.');
    });
  });

  group('Station.fullLocation', () {
    test('combines postcode and place', () {
      expect(testStation.fullLocation, '10115 Berlin');
    });
  });

  group('Station null prices', () {
    test('all price fields default to null', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: false,
      );

      expect(station.e5, isNull);
      expect(station.e10, isNull);
      expect(station.e98, isNull);
      expect(station.diesel, isNull);
      expect(station.dieselPremium, isNull);
      expect(station.e85, isNull);
      expect(station.lpg, isNull);
      expect(station.cng, isNull);
    });
  });

  group('Station equality', () {
    test('stations with same data are equal (freezed)', () {
      const station1 = Station(
        id: 'same-id',
        name: 'Test',
        brand: 'Brand',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      const station2 = Station(
        id: 'same-id',
        name: 'Test',
        brand: 'Brand',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );
      expect(station1, equals(station2));
    });

    test('copyWith creates a modified copy', () {
      final modified = testStation.copyWith(e5: 1.999);
      expect(modified.e5, 1.999);
      expect(modified.id, testStation.id);
      expect(modified.name, testStation.name);
    });
  });
}
