import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';

void main() {
  group('Station amenities field', () {
    test('defaults to empty set', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );

      expect(station.amenities, isEmpty);
    });

    test('can be set via constructor', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
        amenities: {StationAmenity.shop, StationAmenity.carWash},
      );

      expect(station.amenities, hasLength(2));
      expect(station.amenities, contains(StationAmenity.shop));
      expect(station.amenities, contains(StationAmenity.carWash));
    });

    test('JSON roundtrip preserves amenities', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
        amenities: {
          StationAmenity.shop,
          StationAmenity.carWash,
          StationAmenity.toilet,
        },
      );

      final json = station.toJson();
      final roundtripped = Station.fromJson(json);

      expect(roundtripped.amenities, hasLength(3));
      expect(roundtripped.amenities, contains(StationAmenity.shop));
      expect(roundtripped.amenities, contains(StationAmenity.carWash));
      expect(roundtripped.amenities, contains(StationAmenity.toilet));
    });

    test('JSON serializes amenities as list of name strings', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
        amenities: {StationAmenity.shop},
      );

      final json = station.toJson();
      expect(json['amenities'], isA<List>());
      expect(json['amenities'], contains('shop'));
    });

    test('fromJson handles missing amenities field', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'brand': 'Test',
        'street': 'St.',
        'postCode': '10115',
        'place': 'Berlin',
        'lat': 52.0,
        'lng': 13.0,
        'isOpen': true,
      };

      final station = Station.fromJson(json);
      expect(station.amenities, isEmpty);
    });

    test('fromJson ignores unknown amenity names', () {
      final json = {
        'id': 'test',
        'name': 'Test',
        'brand': 'Test',
        'street': 'St.',
        'postCode': '10115',
        'place': 'Berlin',
        'lat': 52.0,
        'lng': 13.0,
        'isOpen': true,
        'amenities': ['shop', 'unknownAmenity', 'toilet'],
      };

      final station = Station.fromJson(json);
      expect(station.amenities, hasLength(2));
      expect(station.amenities, contains(StationAmenity.shop));
      expect(station.amenities, contains(StationAmenity.toilet));
    });

    test('copyWith preserves amenities', () {
      const station = Station(
        id: 'test',
        name: 'Test',
        brand: 'Test',
        street: 'St.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
        amenities: {StationAmenity.shop},
      );

      final modified = station.copyWith(e5: 1.999);
      expect(modified.amenities, contains(StationAmenity.shop));
    });
  });
}
