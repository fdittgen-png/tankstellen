import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_bounding_box.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

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
      test('DE, KR, and CL require API keys', () {
        final keyed = CountryServiceRegistry.entries
            .where((e) => e.requiresApiKey)
            .map((e) => e.countryCode)
            .toSet();
        expect(keyed, equals({'DE', 'KR', 'CL'}));
      });

      test('FR does not require API key', () {
        final entry = CountryServiceRegistry.entryFor('FR');
        expect(entry!.requiresApiKey, isFalse);
      });

      test('GR does not require API key (community API is free)', () {
        // Unlike KR / CL, the Greek Paratiritirio Timon feed is
        // exposed via a community FastAPI wrapper with no auth. #576
        final entry = CountryServiceRegistry.entryFor('GR');
        expect(entry, isNotNull);
        expect(entry!.requiresApiKey, isFalse);
      });

      test('RO does not require API key (public observatory feed)', () {
        // Monitorul Prețurilor is a government-mandated public feed —
        // no auth required. #577
        final entry = CountryServiceRegistry.entryFor('RO');
        expect(entry, isNotNull);
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

      test('CL maps to chileApi', () {
        final entry = CountryServiceRegistry.entryFor('CL');
        expect(entry!.errorSource, equals(ServiceSource.chileApi));
      });

      test('GR maps to greeceApi (#576)', () {
        final entry = CountryServiceRegistry.entryFor('GR');
        expect(entry, isNotNull);
        expect(entry!.errorSource, equals(ServiceSource.greeceApi));
      });

      test('RO maps to romaniaApi (#577)', () {
        final entry = CountryServiceRegistry.entryFor('RO');
        expect(entry, isNotNull);
        expect(entry!.errorSource, equals(ServiceSource.romaniaApi));
      });
    });

    // ── Bounding box and fuel-type fields (#1111) ──────────────────────
    group('boundingBox (#1111)', () {
      test('every entry has a bounding box that is a CountryBoundingBox', () {
        for (final entry in CountryServiceRegistry.entries) {
          expect(entry.boundingBox, isA<CountryBoundingBox>(),
              reason: '${entry.countryCode} entry must have a bounding box');
        }
      });

      test('every bounding box has minLat < maxLat and minLng < maxLng', () {
        for (final entry in CountryServiceRegistry.entries) {
          final bbox = entry.boundingBox;
          expect(bbox.minLat, lessThan(bbox.maxLat),
              reason: '${entry.countryCode}: minLat must be < maxLat');
          expect(bbox.minLng, lessThan(bbox.maxLng),
              reason: '${entry.countryCode}: minLng must be < maxLng');
        }
      });

      test('boundingBoxFor returns the entry box for a registered code', () {
        final box = CountryServiceRegistry.boundingBoxFor('DE');
        expect(box, isNotNull);
        expect(box!.contains(52.52, 13.41), isTrue, // Berlin
            reason: 'DE box must contain Berlin');
      });

      test('boundingBoxFor returns null for an unregistered code', () {
        expect(CountryServiceRegistry.boundingBoxFor('ZZ'), isNull);
      });

      test('entryByLatLng resolves a Berlin point to DE', () {
        final entry = CountryServiceRegistry.entryByLatLng(52.52, 13.41);
        expect(entry, isNotNull);
        expect(entry!.countryCode, equals('DE'));
      });

      test('entryByLatLng resolves a Lisbon point to PT (not ES)', () {
        // Tight-box ordering invariant: PT must be tested before ES.
        final entry = CountryServiceRegistry.entryByLatLng(38.72, -9.14);
        expect(entry, isNotNull);
        expect(entry!.countryCode, equals('PT'));
      });

      test('entryByLatLng returns null for the Atlantic', () {
        expect(CountryServiceRegistry.entryByLatLng(0.0, -30.0), isNull);
      });
    });

    group('availableFuelTypes (#1111)', () {
      test('every entry exposes a non-empty fuel-type list', () {
        for (final entry in CountryServiceRegistry.entries) {
          expect(entry.availableFuelTypes, isNotEmpty,
              reason:
                  '${entry.countryCode} must publish at least one fuel type');
        }
      });

      test('every fuel-type list ends with electric, all', () {
        for (final entry in CountryServiceRegistry.entries) {
          final list = entry.availableFuelTypes;
          expect(list.length, greaterThanOrEqualTo(2),
              reason: '${entry.countryCode}: list should be non-trivial');
          expect(list[list.length - 2], FuelType.electric,
              reason: '${entry.countryCode} must end with electric, all');
          expect(list.last, FuelType.all,
              reason: '${entry.countryCode} must end with electric, all');
        }
      });

      test('fuelTypesFor returns the entry list for a registered code', () {
        final list = CountryServiceRegistry.fuelTypesFor('FR');
        // FR's first fuel is E10 (most common at French pumps).
        expect(list.first, equals(FuelType.e10));
      });

      test('fuelTypesFor returns the default minimal set for unknown codes',
          () {
        final list = CountryServiceRegistry.fuelTypesFor('XX');
        expect(
          list,
          equals(<FuelType>[
            FuelType.e5,
            FuelType.e10,
            FuelType.diesel,
            FuelType.electric,
            FuelType.all,
          ]),
        );
      });
    });
  });
}
