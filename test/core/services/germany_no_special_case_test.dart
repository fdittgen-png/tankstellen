import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression tests for issue #425 — Germany used to be special-cased in
/// `service_providers.dart` (`if (countryCode == 'DE') ...`). The fix moved
/// that branch into the `CountryServiceRegistry` factory function so the
/// registry stays the single source of truth.
///
/// These are source-level tests (no Riverpod container) because the real
/// providers touch storage and Dio singletons that aren't available under
/// flutter_test without a device binding.
void main() {
  late String providersSource;
  late String registrySource;

  setUpAll(() {
    providersSource =
        File('lib/core/services/service_providers.dart').readAsStringSync();
    registrySource =
        File('lib/core/services/country_service_registry.dart')
            .readAsStringSync();
  });

  group('service_providers.dart no longer special-cases any country', () {
    test('no `countryCode == "DE"` branch in service_providers.dart', () {
      // Picks up both single- and double-quoted forms.
      expect(providersSource, isNot(matches(RegExp("countryCode\\s*==\\s*['\"]DE['\"]"))));
    });

    test('no other country code literal lurks in the resolver', () {
      // `_resolveServiceForCountry` should now be a one-liner that delegates
      // to the registry. Any country code string literal here would mean
      // we've reintroduced a special case.
      const codes = ['DE', 'FR', 'IT', 'ES', 'AT', 'BE', 'LU', 'GB', 'AR', 'PT', 'AU', 'MX', 'DK'];
      for (final code in codes) {
        expect(
          providersSource,
          isNot(matches(RegExp("countryCode\\s*==\\s*['\"]$code['\"]"))),
          reason: 'No special-case branch should reference $code',
        );
      }
    });

    test('_resolveServiceForCountry delegates to CountryServiceRegistry', () {
      expect(providersSource, contains('CountryServiceRegistry.buildService'));
    });

    test('service_providers.dart no longer imports DemoStationService or '
        'TankerkoenigStationService directly', () {
      // After the refactor those types live exclusively inside the registry.
      expect(providersSource,
          isNot(contains("import 'impl/demo_station_service.dart'")));
      expect(
          providersSource,
          isNot(contains(
              "import 'impl/tankerkoenig_station_service.dart'")));
    });
  });

  group('CountryServiceRegistry now owns the Germany factory', () {
    test('_createTankerkoenig is no longer an UnsupportedError stub', () {
      // The stub used to throw UnsupportedError because the registry had no
      // way to wire the API-key check. After #425 it returns Demo or the
      // real Tankerkoenig service depending on the storage state.
      expect(
        registrySource,
        isNot(contains('UnsupportedError')),
        reason: '_createTankerkoenig should be implemented, not a stub',
      );
    });

    test('Germany factory falls back to DemoStationService when no API key',
        () {
      expect(registrySource, contains('hasApiKey()'));
      expect(registrySource, contains("DemoStationService(countryCode: 'DE')"));
    });

    test('Germany factory uses tankerkoenigDioProvider when key present', () {
      expect(registrySource, contains('tankerkoenigDioProvider'));
      expect(registrySource, contains('TankerkoenigStationService(dio)'));
    });

    test('every supported country still has a registry entry', () {
      // Sanity check that the const list still holds the full set after
      // the refactor, since assertAllCountriesRegistered runs only at
      // app startup (in debug mode).
      const expected = [
        'DE', 'FR', 'AT', 'ES', 'IT', 'DK', 'AR',
        'PT', 'GB', 'AU', 'MX',
      ];
      for (final code in expected) {
        expect(
          registrySource,
          contains("countryCode: '$code'"),
          reason: '$code entry missing from CountryServiceRegistry',
        );
      }
    });
  });
}
