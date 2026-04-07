import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('FuelType.fromString', () {
    test('parses all known fuel type strings correctly', () {
      expect(FuelType.fromString('e5'), FuelType.e5);
      expect(FuelType.fromString('e10'), FuelType.e10);
      expect(FuelType.fromString('e98'), FuelType.e98);
      expect(FuelType.fromString('diesel'), FuelType.diesel);
      expect(FuelType.fromString('diesel_premium'), FuelType.dieselPremium);
      expect(FuelType.fromString('e85'), FuelType.e85);
      expect(FuelType.fromString('lpg'), FuelType.lpg);
      expect(FuelType.fromString('cng'), FuelType.cng);
      expect(FuelType.fromString('hydrogen'), FuelType.hydrogen);
      expect(FuelType.fromString('electric'), FuelType.electric);
      expect(FuelType.fromString('all'), FuelType.all);
    });

    test('is case-insensitive', () {
      expect(FuelType.fromString('E5'), FuelType.e5);
      expect(FuelType.fromString('E10'), FuelType.e10);
      expect(FuelType.fromString('DIESEL'), FuelType.diesel);
      expect(FuelType.fromString('Diesel_Premium'), FuelType.dieselPremium);
      expect(FuelType.fromString('LPG'), FuelType.lpg);
      expect(FuelType.fromString('CNG'), FuelType.cng);
      expect(FuelType.fromString('ELECTRIC'), FuelType.electric);
    });

    test('returns FuelType.all for unknown string', () {
      expect(FuelType.fromString('unknown'), FuelType.all);
      expect(FuelType.fromString(''), FuelType.all);
      expect(FuelType.fromString('petrol'), FuelType.all);
      expect(FuelType.fromString('gasoline'), FuelType.all);
    });
  });

  group('FuelType.displayName', () {
    test('returns non-empty string for all types', () {
      for (final type in FuelType.values) {
        expect(type.displayName, isNotEmpty,
            reason: '${type.name} should have a non-empty displayName');
      }
    });

    test('returns expected display names', () {
      expect(FuelType.e5.displayName, 'Super E5');
      expect(FuelType.e10.displayName, 'Super E10');
      expect(FuelType.e98.displayName, 'Super 98');
      expect(FuelType.diesel.displayName, 'Diesel');
      expect(FuelType.dieselPremium.displayName, 'Diesel Premium');
      expect(FuelType.e85.displayName, 'E85 / Bio\u00e9thanol');
      expect(FuelType.lpg.displayName, 'GPL / LPG');
      expect(FuelType.cng.displayName, 'GNV / CNG');
      expect(FuelType.hydrogen.displayName, 'Hydrog\u00e8ne / H2');
      expect(FuelType.electric.displayName, 'Electric \u26a1');
      expect(FuelType.all.displayName, 'All');
    });
  });

  group('FuelType.apiValue', () {
    test('returns lowercase api value for all types', () {
      for (final type in FuelType.values) {
        expect(type.apiValue, isNotEmpty,
            reason: '${type.name} should have a non-empty apiValue');
        expect(type.apiValue, type.apiValue.toLowerCase(),
            reason: '${type.name} apiValue should be lowercase');
      }
    });

    test('roundtrips through fromString', () {
      for (final type in FuelType.values) {
        expect(FuelType.fromString(type.apiValue), type,
            reason:
                '${type.name} should roundtrip through fromString(apiValue)');
      }
    });
  });

  group('fuelTypesForCountry', () {
    test('Germany returns correct fuel types', () {
      final types = fuelTypesForCountry('DE');
      expect(types, contains(FuelType.e5));
      expect(types, contains(FuelType.e10));
      expect(types, contains(FuelType.diesel));
      expect(types, contains(FuelType.electric));
      expect(types, contains(FuelType.all));
      // Germany does not have E98 or LPG
      expect(types, isNot(contains(FuelType.e98)));
      expect(types, isNot(contains(FuelType.lpg)));
    });

    test('France returns correct fuel types', () {
      final types = fuelTypesForCountry('FR');
      expect(types, contains(FuelType.e10));
      expect(types, contains(FuelType.e5));
      expect(types, contains(FuelType.e98));
      expect(types, contains(FuelType.diesel));
      expect(types, contains(FuelType.e85));
      expect(types, contains(FuelType.lpg));
      expect(types, contains(FuelType.electric));
      expect(types, contains(FuelType.all));
    });

    test('Austria returns correct fuel types', () {
      final types = fuelTypesForCountry('AT');
      expect(types, contains(FuelType.e5));
      expect(types, contains(FuelType.e10));
      expect(types, contains(FuelType.diesel));
      expect(types, contains(FuelType.electric));
      expect(types, contains(FuelType.all));
    });

    test('Spain returns correct fuel types including premium diesel',
        () {
      final types = fuelTypesForCountry('ES');
      expect(types, contains(FuelType.dieselPremium));
      expect(types, contains(FuelType.e98));
      expect(types, contains(FuelType.lpg));
    });

    test('Italy returns CNG', () {
      final types = fuelTypesForCountry('IT');
      expect(types, contains(FuelType.cng));
      expect(types, contains(FuelType.lpg));
    });

    test('unknown country returns default set', () {
      final types = fuelTypesForCountry('XX');
      expect(types, contains(FuelType.e5));
      expect(types, contains(FuelType.e10));
      expect(types, contains(FuelType.diesel));
      expect(types, contains(FuelType.electric));
      expect(types, contains(FuelType.all));
    });

    test('all countries return at least one fuel type', () {
      for (final code in ['DE', 'FR', 'AT', 'ES', 'IT', 'XX']) {
        final types = fuelTypesForCountry(code);
        expect(types, isNotEmpty,
            reason: 'Country $code should have at least one fuel type');
      }
    });
  });

  group('Sealed class properties', () {
    test('each fuel type has an icon', () {
      for (final type in FuelType.values) {
        expect(type.icon, isA<IconData>(),
            reason: '${type.name} should have an icon');
      }
    });

    test('each fuel type has a category', () {
      for (final type in FuelType.values) {
        expect(type.category, isA<FuelCategory>(),
            reason: '${type.name} should have a category');
      }
    });

    test('conventional fuel types are classified correctly', () {
      expect(FuelType.e5.isConventional, isTrue);
      expect(FuelType.e10.isConventional, isTrue);
      expect(FuelType.e98.isConventional, isTrue);
      expect(FuelType.diesel.isConventional, isTrue);
      expect(FuelType.dieselPremium.isConventional, isTrue);
    });

    test('alternative fuel types are classified correctly', () {
      expect(FuelType.e85.isAlternative, isTrue);
      expect(FuelType.lpg.isAlternative, isTrue);
      expect(FuelType.cng.isAlternative, isTrue);
      expect(FuelType.hydrogen.isAlternative, isTrue);
      expect(FuelType.electric.isAlternative, isTrue);
    });

    test('meta fuel types are classified correctly', () {
      expect(FuelType.all.category, FuelCategory.meta);
      expect(FuelType.all.isConventional, isFalse);
      expect(FuelType.all.isAlternative, isFalse);
    });

    test('each fuel type has a unit', () {
      expect(FuelType.e5.unit, 'EUR/L');
      expect(FuelType.diesel.unit, 'EUR/L');
      expect(FuelType.lpg.unit, 'EUR/L');
      expect(FuelType.cng.unit, 'EUR/kg');
      expect(FuelType.hydrogen.unit, 'EUR/kg');
      expect(FuelType.electric.unit, 'EUR/kWh');
      expect(FuelType.all.unit, isEmpty);
    });

    test('sealed class enables exhaustive pattern matching', () {
      // Verify all subtypes are distinct and pattern-matchable
      for (final type in FuelType.values) {
        final matched = switch (type) {
          FuelTypeE5() => 'e5',
          FuelTypeE10() => 'e10',
          FuelTypeE98() => 'e98',
          FuelTypeDiesel() => 'diesel',
          FuelTypeDieselPremium() => 'dieselPremium',
          FuelTypeE85() => 'e85',
          FuelTypeLpg() => 'lpg',
          FuelTypeCng() => 'cng',
          FuelTypeHydrogen() => 'hydrogen',
          FuelTypeElectric() => 'electric',
          FuelTypeAll() => 'all',
        };
        expect(matched, isNotEmpty,
            reason: '${type.name} should be pattern-matchable');
      }
    });

    test('values list contains all 11 fuel types', () {
      expect(FuelType.values.length, 11);
    });

    test('identity equality works correctly', () {
      expect(FuelType.e5 == FuelType.e5, isTrue);
      expect(FuelType.e5 == FuelType.e10, isFalse);
      expect(FuelType.fromString('e5') == FuelType.e5, isTrue);
      expect(identical(FuelType.fromString('e5'), FuelType.e5), isTrue);
    });

    test('toString returns readable representation', () {
      expect(FuelType.e5.toString(), 'FuelType.e5');
      expect(FuelType.diesel.toString(), 'FuelType.diesel');
      expect(FuelType.dieselPremium.toString(), 'FuelType.diesel_premium');
    });
  });

  group('FuelTypeJsonConverter', () {
    const converter = FuelTypeJsonConverter();

    test('toJson returns apiValue', () {
      expect(converter.toJson(FuelType.e5), 'e5');
      expect(converter.toJson(FuelType.diesel), 'diesel');
      expect(converter.toJson(FuelType.dieselPremium), 'diesel_premium');
      expect(converter.toJson(FuelType.lpg), 'lpg');
      expect(converter.toJson(FuelType.cng), 'cng');
      expect(converter.toJson(FuelType.hydrogen), 'hydrogen');
    });

    test('fromJson parses apiValue strings', () {
      expect(converter.fromJson('e5'), FuelType.e5);
      expect(converter.fromJson('diesel'), FuelType.diesel);
      expect(converter.fromJson('diesel_premium'), FuelType.dieselPremium);
      expect(converter.fromJson('lpg'), FuelType.lpg);
    });

    test('fromJson handles legacy camelCase names', () {
      expect(converter.fromJson('dieselPremium'), FuelType.dieselPremium);
    });

    test('roundtrips through JSON', () {
      for (final type in FuelType.values) {
        final json = converter.toJson(type);
        final parsed = converter.fromJson(json);
        expect(parsed, type,
            reason: '${type.name} should roundtrip through JSON converter');
      }
    });

    test('works with json encode/decode', () {
      final map = {'fuelType': converter.toJson(FuelType.cng)};
      final encoded = jsonEncode(map);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(converter.fromJson(decoded['fuelType'] as String), FuelType.cng);
    });
  });

  group('Backward compatibility', () {
    test('fromString accepts legacy enum names', () {
      // The old json_serializable generated code used enum names (camelCase)
      expect(FuelType.fromString('dieselPremium'), FuelType.dieselPremium);
    });

    test('static const instances are accessible like enum values', () {
      // Verify the API surface matches the old enum
      expect(FuelType.e5, isNotNull);
      expect(FuelType.e10, isNotNull);
      expect(FuelType.e98, isNotNull);
      expect(FuelType.diesel, isNotNull);
      expect(FuelType.dieselPremium, isNotNull);
      expect(FuelType.e85, isNotNull);
      expect(FuelType.lpg, isNotNull);
      expect(FuelType.cng, isNotNull);
      expect(FuelType.hydrogen, isNotNull);
      expect(FuelType.electric, isNotNull);
      expect(FuelType.all, isNotNull);
    });
  });
}
