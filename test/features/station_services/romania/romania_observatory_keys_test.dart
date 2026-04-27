import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/station_services/romania/romania_observatory_keys.dart';

/// Unit tests for [RomaniaObservatoryKeys].
///
/// The class is the single source of truth for translating the
/// upstream `pretcarburant.ro` `prices.{key}` map into canonical
/// [FuelType] → RON-per-litre pairs. These tests pin every documented
/// observatory key, the case-insensitive lookup contract, and every
/// rejection branch on `parseLeiPerLitre` so the parser cannot drift
/// silently.
void main() {
  group('RomaniaObservatoryKeys.lookup', () {
    test('every documented key maps to its canonical FuelType', () {
      expect(RomaniaObservatoryKeys.lookup('benzina_standard'), FuelType.e5);
      expect(RomaniaObservatoryKeys.lookup('benzina_premium'), FuelType.e98);
      expect(RomaniaObservatoryKeys.lookup('motorina_standard'), FuelType.diesel);
      expect(
        RomaniaObservatoryKeys.lookup('motorina_premium'),
        FuelType.dieselPremium,
      );
      expect(RomaniaObservatoryKeys.lookup('gpl'), FuelType.lpg);
    });

    test('upper-case input still resolves (case-insensitive)', () {
      expect(RomaniaObservatoryKeys.lookup('BENZINA_STANDARD'), FuelType.e5);
      expect(RomaniaObservatoryKeys.lookup('GPL'), FuelType.lpg);
    });

    test('mixed-case input still resolves (case-insensitive)', () {
      expect(
        RomaniaObservatoryKeys.lookup('Motorina_Standard'),
        FuelType.diesel,
      );
      expect(RomaniaObservatoryKeys.lookup('Gpl'), FuelType.lpg);
    });

    test('unknown key returns null', () {
      expect(RomaniaObservatoryKeys.lookup('hydrogen'), isNull);
      expect(RomaniaObservatoryKeys.lookup(''), isNull);
      expect(RomaniaObservatoryKeys.lookup('benzina'), isNull);
    });
  });

  group('RomaniaObservatoryKeys.parsePrices', () {
    test('empty Map returns empty Map', () {
      expect(RomaniaObservatoryKeys.parsePrices(<String, dynamic>{}), isEmpty);
    });

    test('null input returns empty Map', () {
      expect(RomaniaObservatoryKeys.parsePrices(null), isEmpty);
    });

    test('String input returns empty Map', () {
      expect(
        RomaniaObservatoryKeys.parsePrices('not a map'),
        isEmpty,
      );
    });

    test('int input returns empty Map', () {
      expect(RomaniaObservatoryKeys.parsePrices(42), isEmpty);
    });

    test('List input returns empty Map', () {
      expect(
        RomaniaObservatoryKeys.parsePrices(<dynamic>['a', 'b']),
        isEmpty,
      );
    });

    test('parses a complete, well-formed price map', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': 7.25,
        'benzina_premium': 7.89,
        'motorina_standard': 7.45,
        'motorina_premium': 7.95,
        'gpl': 3.85,
      });

      expect(result, <FuelType, double>{
        FuelType.e5: 7.25,
        FuelType.e98: 7.89,
        FuelType.diesel: 7.45,
        FuelType.dieselPremium: 7.95,
        FuelType.lpg: 3.85,
      });
    });

    test('drops unknown keys, keeps known ones', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': 7.25,
        'unknown_fuel': 9.99,
        'hydrogen': 12.0,
        'gpl': 3.85,
      });

      expect(result, <FuelType, double>{
        FuelType.e5: 7.25,
        FuelType.lpg: 3.85,
      });
    });

    test('drops zero prices', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': 0,
        'benzina_premium': 0.0,
        'gpl': 3.85,
      });

      expect(result, <FuelType, double>{FuelType.lpg: 3.85});
    });

    test('drops negative prices', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': -1.0,
        'motorina_standard': -7.45,
        'gpl': 3.85,
      });

      expect(result, <FuelType, double>{FuelType.lpg: 3.85});
    });

    test('drops non-numeric string prices', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': 'abc',
        'gpl': 'NaN-ish',
        'motorina_standard': '',
        'motorina_premium': 7.95,
      });

      expect(result, <FuelType, double>{FuelType.dieselPremium: 7.95});
    });

    test('parses numeric string prices', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'benzina_standard': '7.259',
        'gpl': '3.85',
      });

      expect(result, <FuelType, double>{
        FuelType.e5: 7.259,
        FuelType.lpg: 3.85,
      });
    });

    test('mixed-case keys still match (case-insensitive)', () {
      final result = RomaniaObservatoryKeys.parsePrices(<String, dynamic>{
        'BENZINA_STANDARD': 7.25,
        'Gpl': 3.85,
      });

      expect(result, <FuelType, double>{
        FuelType.e5: 7.25,
        FuelType.lpg: 3.85,
      });
    });

    test('non-String keys are tolerated via toString()', () {
      // Maps with int keys can occur if upstream JSON is decoded loosely;
      // the parser uses `entry.key.toString()` so it must not throw.
      final result = RomaniaObservatoryKeys.parsePrices(<dynamic, dynamic>{
        123: 5.0,
        'gpl': 3.85,
      });

      expect(result, <FuelType, double>{FuelType.lpg: 3.85});
    });
  });

  group('RomaniaObservatoryKeys.parseLeiPerLitre', () {
    test('positive double returns the value', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(7.259), 7.259);
    });

    test('positive int returns the value as double', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(7), 7.0);
    });

    test('int zero returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(0), isNull);
    });

    test('double zero returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(0.0), isNull);
    });

    test('negative num returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(-1), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(-7.259), isNull);
    });

    test('numeric String returns parsed double', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('7.259'), 7.259);
    });

    test('numeric String with surrounding whitespace is trimmed', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(' 7.259 '), 7.259);
    });

    test('empty String returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(''), isNull);
    });

    test('whitespace-only String returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('   '), isNull);
    });

    test('non-numeric String returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('abc'), isNull);
    });

    test('zero String returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('0'), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('0.0'), isNull);
    });

    test('negative String returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre('-7.259'), isNull);
    });

    test('null returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(null), isNull);
    });

    test('bool returns null', () {
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(true), isNull);
      expect(RomaniaObservatoryKeys.parseLeiPerLitre(false), isNull);
    });

    test('Map returns null', () {
      expect(
        RomaniaObservatoryKeys.parseLeiPerLitre(<String, dynamic>{'v': 7.25}),
        isNull,
      );
    });

    test('List returns null', () {
      expect(
        RomaniaObservatoryKeys.parseLeiPerLitre(<dynamic>[7.25]),
        isNull,
      );
    });
  });
}
