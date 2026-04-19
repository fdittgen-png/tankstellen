import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Typed [CountryConfig.supportedFuelTypes] catalog (#699). Pins every
/// shipped country's set so a country service migration can't silently
/// drop (or add) a fuel without the test catching it.
void main() {
  group('CountryConfig.supportedFuelTypes (#699)', () {
    test('Germany — E5, E10, Diesel, Electric', () {
      expect(Countries.germany.supportedFuelTypes, {
        FuelType.e5,
        FuelType.e10,
        FuelType.diesel,
        FuelType.electric,
      });
    });

    test('France — E5, E10, E98, Diesel, E85, LPG, Electric', () {
      expect(Countries.france.supportedFuelTypes, {
        FuelType.e5,
        FuelType.e10,
        FuelType.e98,
        FuelType.diesel,
        FuelType.e85,
        FuelType.lpg,
        FuelType.electric,
      });
    });

    test('Austria — E5, E10, Diesel, Electric (same as default)', () {
      expect(Countries.austria.supportedFuelTypes, {
        FuelType.e5,
        FuelType.e10,
        FuelType.diesel,
        FuelType.electric,
      });
    });

    test('Spain — E5, E10, E98, Diesel, Diesel Premium, LPG, Electric', () {
      expect(Countries.spain.supportedFuelTypes, {
        FuelType.e5,
        FuelType.e10,
        FuelType.e98,
        FuelType.diesel,
        FuelType.dieselPremium,
        FuelType.lpg,
        FuelType.electric,
      });
    });

    test('Italy — E5, Diesel, LPG, CNG (Metano), Electric', () {
      expect(Countries.italy.supportedFuelTypes, {
        FuelType.e5,
        FuelType.diesel,
        FuelType.lpg,
        FuelType.cng,
        FuelType.electric,
      });
    });

    test('every country includes Electric (OCM coverage is universal)', () {
      for (final country in Countries.all) {
        expect(
          country.supportedFuelTypes,
          contains(FuelType.electric),
          reason:
              '${country.code} must include FuelType.electric — OCM EV '
              'charging stations are universal. If a country legitimately '
              'has no EV stations, open a separate issue before removing.',
        );
      }
    });

    test('no country exposes the synthetic FuelType.all', () {
      // FuelType.all is a search-time wildcard — it must never appear
      // in a country's supported set or the profile picker would show
      // it as a "real" option.
      for (final country in Countries.all) {
        expect(
          country.supportedFuelTypes,
          isNot(contains(FuelType.all)),
          reason: '${country.code} leaked FuelType.all',
        );
      }
    });

    test('supported set has at least two entries for every country', () {
      // A single-fuel country would make the chip picker pointless. If
      // that is ever legitimately true, change this test — but require
      // an explicit human decision.
      for (final country in Countries.all) {
        expect(
          country.supportedFuelTypes.length,
          greaterThanOrEqualTo(2),
          reason: '${country.code} only lists ${country.supportedFuelTypes}',
        );
      }
    });
  });
}
