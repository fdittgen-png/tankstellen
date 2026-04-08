import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';

void main() {
  group('amenityIcon', () {
    test('returns distinct icon for each amenity', () {
      final icons = StationAmenity.values.map(amenityIcon).toSet();
      expect(icons.length, StationAmenity.values.length,
          reason: 'Each amenity should have a unique icon');
    });

    test('returns expected icons', () {
      expect(amenityIcon(StationAmenity.shop), Icons.store);
      expect(amenityIcon(StationAmenity.carWash), Icons.local_car_wash);
      expect(amenityIcon(StationAmenity.airPump), Icons.tire_repair);
      expect(amenityIcon(StationAmenity.toilet), Icons.wc);
      expect(amenityIcon(StationAmenity.restaurant), Icons.restaurant);
      expect(amenityIcon(StationAmenity.atm), Icons.atm);
      expect(amenityIcon(StationAmenity.wifi), Icons.wifi);
      expect(amenityIcon(StationAmenity.ev), Icons.ev_station);
    });
  });

  group('amenityLabel', () {
    test('returns non-empty label for each amenity', () {
      for (final a in StationAmenity.values) {
        expect(amenityLabel(a), isNotEmpty,
            reason: '${a.name} should have a label');
      }
    });
  });

  group('parseAmenitiesFromServices', () {
    test('returns empty set for empty services list', () {
      expect(parseAmenitiesFromServices([]), isEmpty);
    });

    test('detects shop from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Boutique alimentaire',
        'Vente de fioul domestique',
      ]);
      expect(result, contains(StationAmenity.shop));
    });

    test('detects car wash from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Lavage automatique',
        'Lavage manuel',
      ]);
      expect(result, contains(StationAmenity.carWash));
    });

    test('detects air pump from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Station de gonflage',
      ]);
      expect(result, contains(StationAmenity.airPump));
    });

    test('detects toilet from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Toilettes publiques',
      ]);
      expect(result, contains(StationAmenity.toilet));
    });

    test('detects restaurant from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Restauration à emporter',
      ]);
      expect(result, contains(StationAmenity.restaurant));
    });

    test('detects ATM from French service strings', () {
      final result = parseAmenitiesFromServices([
        'DAB (Distributeur automatique de billets)',
      ]);
      expect(result, contains(StationAmenity.atm));
    });

    test('detects WiFi from service strings', () {
      final result = parseAmenitiesFromServices(['Wifi gratuit']);
      expect(result, contains(StationAmenity.wifi));
    });

    test('detects EV charging from French service strings', () {
      final result = parseAmenitiesFromServices([
        'Borne electrique',
      ]);
      expect(result, contains(StationAmenity.ev));
    });

    test('detects multiple amenities from mixed services', () {
      final result = parseAmenitiesFromServices([
        'Boutique alimentaire',
        'Lavage automatique',
        'Station de gonflage',
        'Toilettes publiques',
        'Restauration à emporter',
      ]);
      expect(result, containsAll([
        StationAmenity.shop,
        StationAmenity.carWash,
        StationAmenity.airPump,
        StationAmenity.toilet,
        StationAmenity.restaurant,
      ]));
    });

    test('returns empty set when no keywords match', () {
      final result = parseAmenitiesFromServices([
        'Piste poids lourds',
        'Location de véhicule',
      ]);
      expect(result, isEmpty);
    });

    test('is case-insensitive', () {
      final result = parseAmenitiesFromServices([
        'BOUTIQUE ALIMENTAIRE',
        'LAVAGE AUTOMATIQUE',
      ]);
      expect(result, contains(StationAmenity.shop));
      expect(result, contains(StationAmenity.carWash));
    });

    test('detects German keywords', () {
      final result = parseAmenitiesFromServices([
        'Shop',
        'Waschanlage',
        'Luftdruck',
      ]);
      expect(result, containsAll([
        StationAmenity.shop,
        StationAmenity.carWash,
        StationAmenity.airPump,
      ]));
    });
  });
}
