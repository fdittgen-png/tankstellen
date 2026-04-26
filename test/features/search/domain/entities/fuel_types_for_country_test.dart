import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Behaviour-preservation tests for the declarative `_countryFuels` map
/// (closes #1112). Each expected list below is hard-coded from the
/// pre-refactor `switch` in `fuel_type.dart` so that any drift from the
/// historical mapping fails loudly here. Order matters: the UI fuel-type
/// selector renders in the order returned, so we assert via `equals(...)`
/// (exact list equality) rather than `contains(...)`.
void main() {
  group('fuelTypesForCountry — exact per-country lists (#1112)', () {
    test('DE — E5, E10, Diesel, Electric, All', () {
      expect(
        fuelTypesForCountry('DE'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.diesel,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('FR — E10 first, then E5/E98/Diesel/E85/LPG', () {
      expect(
        fuelTypesForCountry('FR'),
        equals(<FuelType>[
          FuelType.e10,
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.e85,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('AT — E5, E10, Diesel, Electric, All', () {
      expect(
        fuelTypesForCountry('AT'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.diesel,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('ES — includes Diesel Premium and LPG', () {
      expect(
        fuelTypesForCountry('ES'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.e98,
          FuelType.diesel,
          FuelType.dieselPremium,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('IT — Benzina, Diesel, LPG, CNG (Metano)', () {
      expect(
        fuelTypesForCountry('IT'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.diesel,
          FuelType.lpg,
          FuelType.cng,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('LU — E5, E10, E98, Diesel, LPG (#574)', () {
      expect(
        fuelTypesForCountry('LU'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.e98,
          FuelType.diesel,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('SI — NMB-95/100, Diesel, Diesel Premium, LPG (#575)', () {
      expect(
        fuelTypesForCountry('SI'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.dieselPremium,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('KR — OPINET Gasoline / Premium / Diesel / LPG (#597)', () {
      expect(
        fuelTypesForCountry('KR'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('CL — CNE Gasolina 93/95/97, Diésel, LPG (#596)', () {
      expect(
        fuelTypesForCountry('CL'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('GR — Αμόλυβδη 95/100, Diesel, LPG (#576)', () {
      expect(
        fuelTypesForCountry('GR'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('RO — Benzină Standard/Premium, Motorină Standard/Premium, GPL (#577)',
        () {
      expect(
        fuelTypesForCountry('RO'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e98,
          FuelType.diesel,
          FuelType.dieselPremium,
          FuelType.lpg,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('XX (unknown) — falls back to default minimal set', () {
      expect(
        fuelTypesForCountry('XX'),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.diesel,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('empty country code falls back to default minimal set', () {
      expect(
        fuelTypesForCountry(''),
        equals(<FuelType>[
          FuelType.e5,
          FuelType.e10,
          FuelType.diesel,
          FuelType.electric,
          FuelType.all,
        ]),
      );
    });

    test('every country returns a list ending in electric, all', () {
      const codes = [
        'DE', 'FR', 'AT', 'ES', 'IT', 'LU', 'SI', 'KR', 'CL', 'GR', 'RO',
      ];
      for (final code in codes) {
        final list = fuelTypesForCountry(code);
        expect(list.length, greaterThanOrEqualTo(2),
            reason: '$code list should be non-trivial');
        expect(list[list.length - 2], FuelType.electric,
            reason: '$code list should end with electric, all');
        expect(list.last, FuelType.all,
            reason: '$code list should end with electric, all');
      }
    });
  });
}
