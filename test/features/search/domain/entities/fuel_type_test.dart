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
}
