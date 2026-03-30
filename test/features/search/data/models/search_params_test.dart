import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('SearchParams', () {
    test('requires lat and lng', () {
      const params = SearchParams(lat: 52.52, lng: 13.405);
      expect(params.lat, equals(52.52));
      expect(params.lng, equals(13.405));
    });

    test('has default radiusKm of 10.0', () {
      const params = SearchParams(lat: 0, lng: 0);
      expect(params.radiusKm, equals(10.0));
    });

    test('has default fuelType of FuelType.all', () {
      const params = SearchParams(lat: 0, lng: 0);
      expect(params.fuelType, equals(FuelType.all));
    });

    test('has default sortBy of SortBy.price', () {
      const params = SearchParams(lat: 0, lng: 0);
      expect(params.sortBy, equals(SortBy.price));
    });

    test('postalCode is null by default', () {
      const params = SearchParams(lat: 0, lng: 0);
      expect(params.postalCode, isNull);
    });

    test('locationName is null by default', () {
      const params = SearchParams(lat: 0, lng: 0);
      expect(params.locationName, isNull);
    });

    test('accepts optional postalCode', () {
      const params = SearchParams(
        lat: 52.52,
        lng: 13.405,
        postalCode: '10115',
      );
      expect(params.postalCode, equals('10115'));
    });

    test('accepts optional locationName', () {
      const params = SearchParams(
        lat: 52.52,
        lng: 13.405,
        locationName: 'Berlin',
      );
      expect(params.locationName, equals('Berlin'));
    });

    test('accepts all optional parameters together', () {
      const params = SearchParams(
        lat: 48.856,
        lng: 2.352,
        radiusKm: 15.0,
        fuelType: FuelType.diesel,
        sortBy: SortBy.distance,
        postalCode: '75001',
        locationName: 'Paris',
      );
      expect(params.lat, equals(48.856));
      expect(params.lng, equals(2.352));
      expect(params.radiusKm, equals(15.0));
      expect(params.fuelType, equals(FuelType.diesel));
      expect(params.sortBy, equals(SortBy.distance));
      expect(params.postalCode, equals('75001'));
      expect(params.locationName, equals('Paris'));
    });
  });

  group('SearchParams - copyWith', () {
    test('copyWith preserves unchanged fields', () {
      const original = SearchParams(
        lat: 52.52,
        lng: 13.405,
        radiusKm: 10.0,
        fuelType: FuelType.e10,
        sortBy: SortBy.price,
        postalCode: '10115',
        locationName: 'Berlin',
      );

      final modified = original.copyWith(radiusKm: 25.0);
      expect(modified.lat, equals(52.52));
      expect(modified.lng, equals(13.405));
      expect(modified.radiusKm, equals(25.0));
      expect(modified.fuelType, equals(FuelType.e10));
      expect(modified.sortBy, equals(SortBy.price));
      expect(modified.postalCode, equals('10115'));
      expect(modified.locationName, equals('Berlin'));
    });

    test('copyWith can change fuelType', () {
      const original = SearchParams(lat: 0, lng: 0);
      final modified = original.copyWith(fuelType: FuelType.diesel);
      expect(modified.fuelType, equals(FuelType.diesel));
    });

    test('copyWith can change sortBy', () {
      const original = SearchParams(lat: 0, lng: 0);
      final modified = original.copyWith(sortBy: SortBy.distance);
      expect(modified.sortBy, equals(SortBy.distance));
    });

    test('copyWith can change lat and lng', () {
      const original = SearchParams(lat: 0, lng: 0);
      final modified = original.copyWith(lat: 48.0, lng: 2.0);
      expect(modified.lat, equals(48.0));
      expect(modified.lng, equals(2.0));
    });

    test('copyWith can set postalCode to a value', () {
      const original = SearchParams(lat: 0, lng: 0);
      final modified = original.copyWith(postalCode: '80331');
      expect(modified.postalCode, equals('80331'));
    });
  });

  group('SearchParams - equality', () {
    test('two SearchParams with same values are equal', () {
      const a = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      const b = SearchParams(lat: 52.52, lng: 13.405, radiusKm: 10.0);
      expect(a, equals(b));
    });

    test('two SearchParams with different values are not equal', () {
      const a = SearchParams(lat: 52.52, lng: 13.405);
      const b = SearchParams(lat: 48.856, lng: 2.352);
      expect(a, isNot(equals(b)));
    });
  });

  group('SortBy', () {
    test('price has correct apiValue and displayName', () {
      expect(SortBy.price.apiValue, equals('price'));
      expect(SortBy.price.displayName, equals('Price'));
    });

    test('distance has correct apiValue and displayName', () {
      expect(SortBy.distance.apiValue, equals('dist'));
      expect(SortBy.distance.displayName, equals('Distance'));
    });

    test('has exactly two values', () {
      expect(SortBy.values.length, equals(2));
    });
  });
}
