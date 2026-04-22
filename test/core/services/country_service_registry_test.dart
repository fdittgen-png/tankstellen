import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/service_result.dart';

void main() {
  group('CountryServiceRegistry', () {
    group('entries', () {
      test('has an entry for every country in Countries.all', () {
        final registeredCodes = CountryServiceRegistry.registeredCountryCodes;
        for (final country in Countries.all) {
          expect(
            registeredCodes.contains(country.code),
            isTrue,
            reason: '${country.code} (${country.name}) is in Countries.all '
                'but missing from CountryServiceRegistry.entries',
          );
        }
      });

      test('each entry has a non-empty country code', () {
        for (final entry in CountryServiceRegistry.entries) {
          expect(entry.countryCode, isNotEmpty);
        }
      });

      test('each entry has a valid ServiceSource', () {
        for (final entry in CountryServiceRegistry.entries) {
          expect(entry.errorSource, isA<ServiceSource>());
          expect(entry.errorSource.displayName, isNotEmpty);
        }
      });

      test('no duplicate country codes', () {
        final codes = CountryServiceRegistry.entries
            .map((e) => e.countryCode)
            .toList();
        expect(codes.toSet().length, equals(codes.length),
            reason: 'Duplicate country codes found in registry');
      });

      test('entry count matches Countries.all count', () {
        expect(
          CountryServiceRegistry.entries.length,
          equals(Countries.all.length),
          reason: 'Registry entries and Countries.all should have '
              'the same number of entries',
        );
      });
    });

    group('entryFor', () {
      test('returns entry for registered country', () {
        final entry = CountryServiceRegistry.entryFor('FR');
        expect(entry, isNotNull);
        expect(entry!.countryCode, equals('FR'));
        expect(entry.errorSource, equals(ServiceSource.prixCarburantsApi));
      });

      test('returns null for unregistered country', () {
        final entry = CountryServiceRegistry.entryFor('XX');
        expect(entry, isNull);
      });

      test('returns correct entry for each registered country', () {
        for (final entry in CountryServiceRegistry.entries) {
          final found = CountryServiceRegistry.entryFor(entry.countryCode);
          expect(found, isNotNull);
          expect(found!.countryCode, equals(entry.countryCode));
          expect(found.errorSource, equals(entry.errorSource));
        }
      });
    });

    group('registeredCountryCodes', () {
      test('returns all codes from entries', () {
        final codes = CountryServiceRegistry.registeredCountryCodes;
        expect(codes.length, equals(CountryServiceRegistry.entries.length));
        for (final entry in CountryServiceRegistry.entries) {
          expect(codes.contains(entry.countryCode), isTrue);
        }
      });
    });

    group('requiresApiKey', () {
      test('DE and KR require API keys', () {
        final keyed = CountryServiceRegistry.entries
            .where((e) => e.requiresApiKey)
            .map((e) => e.countryCode)
            .toSet();
        expect(keyed, equals({'DE', 'KR'}));
      });

      test('FR does not require API key', () {
        final entry = CountryServiceRegistry.entryFor('FR');
        expect(entry!.requiresApiKey, isFalse);
      });
    });

    group('assertAllCountriesRegistered', () {
      test('does not throw when all countries are registered', () {
        // This should not throw since we keep them in sync
        expect(
          () => CountryServiceRegistry.assertAllCountriesRegistered(),
          returnsNormally,
        );
      });
    });

    group('buildService', () {
      test('returns DemoStationService for unknown country code', () {
        // buildService needs a Ref, but for unknown countries it returns
        // DemoStationService without using Ref. We can test this via
        // service_providers_test.dart for the full Riverpod integration.
        // Here we just verify the entry lookup returns null.
        final entry = CountryServiceRegistry.entryFor('ZZ');
        expect(entry, isNull);
      });
    });

    group('error source mapping', () {
      test('DE maps to tankerkoenigApi', () {
        final entry = CountryServiceRegistry.entryFor('DE');
        expect(entry!.errorSource, equals(ServiceSource.tankerkoenigApi));
      });

      test('FR maps to prixCarburantsApi', () {
        final entry = CountryServiceRegistry.entryFor('FR');
        expect(entry!.errorSource, equals(ServiceSource.prixCarburantsApi));
      });

      test('AT maps to eControlApi', () {
        final entry = CountryServiceRegistry.entryFor('AT');
        expect(entry!.errorSource, equals(ServiceSource.eControlApi));
      });

      test('ES maps to mitecoApi', () {
        final entry = CountryServiceRegistry.entryFor('ES');
        expect(entry!.errorSource, equals(ServiceSource.mitecoApi));
      });

      test('IT maps to miseApi', () {
        final entry = CountryServiceRegistry.entryFor('IT');
        expect(entry!.errorSource, equals(ServiceSource.miseApi));
      });

      test('DK maps to denmarkApi', () {
        final entry = CountryServiceRegistry.entryFor('DK');
        expect(entry!.errorSource, equals(ServiceSource.denmarkApi));
      });

      test('AR maps to argentinaApi', () {
        final entry = CountryServiceRegistry.entryFor('AR');
        expect(entry!.errorSource, equals(ServiceSource.argentinaApi));
      });

      test('PT maps to portugalApi', () {
        final entry = CountryServiceRegistry.entryFor('PT');
        expect(entry!.errorSource, equals(ServiceSource.portugalApi));
      });

      test('GB maps to ukApi', () {
        final entry = CountryServiceRegistry.entryFor('GB');
        expect(entry!.errorSource, equals(ServiceSource.ukApi));
      });

      test('AU maps to australiaApi', () {
        final entry = CountryServiceRegistry.entryFor('AU');
        expect(entry!.errorSource, equals(ServiceSource.australiaApi));
      });

      test('MX maps to mexicoApi', () {
        final entry = CountryServiceRegistry.entryFor('MX');
        expect(entry!.errorSource, equals(ServiceSource.mexicoApi));
      });
    });
  });
}
