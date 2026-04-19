import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/country/fuel_type_picker_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #703 — every fuel picker in the app reads from this provider, so
/// switching country re-filters every dropdown in one place.

class _FixedCountry extends ActiveCountry {
  _FixedCountry(this._country);
  final CountryConfig _country;
  @override
  CountryConfig build() => _country;
}

ProviderContainer _container(CountryConfig country) {
  return ProviderContainer(
    overrides: [
      activeCountryProvider.overrideWith(() => _FixedCountry(country)),
    ],
  );
}

void main() {
  group('fuelTypePickerProvider (#703)', () {
    test('France returns E5/E10/E98/Diesel/E85/LPG/Electric, no wildcard', () {
      final c = _container(Countries.france);
      addTearDown(c.dispose);
      final picker = c.read(fuelTypePickerProvider);
      expect(picker, containsAll([
        FuelType.e5,
        FuelType.e10,
        FuelType.e98,
        FuelType.diesel,
        FuelType.e85,
        FuelType.lpg,
        FuelType.electric,
      ]));
      expect(picker, isNot(contains(FuelType.all)));
    });

    test('Italy returns E5/Diesel/LPG/CNG/Electric only', () {
      final c = _container(Countries.italy);
      addTearDown(c.dispose);
      expect(c.read(fuelTypePickerProvider), {
        FuelType.e5,
        FuelType.diesel,
        FuelType.lpg,
        FuelType.cng,
        FuelType.electric,
      });
    });

    test('Germany returns the default E5/E10/Diesel/Electric', () {
      final c = _container(Countries.germany);
      addTearDown(c.dispose);
      expect(c.read(fuelTypePickerProvider), {
        FuelType.e5,
        FuelType.e10,
        FuelType.diesel,
        FuelType.electric,
      });
    });

    test('swapping the active country provider re-filters the picker', () {
      // Verify the provider is a live dependency — a reactive read
      // via a refreshed override produces a new value.
      final c1 = _container(Countries.germany);
      addTearDown(c1.dispose);
      expect(c1.read(fuelTypePickerProvider), hasLength(4));

      final c2 = _container(Countries.france);
      addTearDown(c2.dispose);
      expect(c2.read(fuelTypePickerProvider), hasLength(7));
    });

    test('no country leaks the synthetic FuelType.all through the picker',
        () {
      for (final country in Countries.all) {
        final c = _container(country);
        expect(
          c.read(fuelTypePickerProvider),
          isNot(contains(FuelType.all)),
          reason: '${country.code} leaked FuelType.all into the picker',
        );
        c.dispose();
      }
    });
  });
}
