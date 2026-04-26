import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that the new-country documentation references all required
/// touchpoints for adding a country. If a developer adds a new required
/// file but forgets to update the guide, this test will fail.
void main() {
  group('New-country guide completeness', () {
    late String guideContent;
    late String contributingContent;

    setUpAll(() {
      final guideFile = File('docs/guides/NEW_COUNTRY.md');
      expect(guideFile.existsSync(), isTrue,
          reason: 'docs/guides/NEW_COUNTRY.md must exist');
      guideContent = guideFile.readAsStringSync();

      final contributingFile = File('docs/CONTRIBUTING.md');
      expect(contributingFile.existsSync(), isTrue,
          reason: 'docs/CONTRIBUTING.md must exist');
      contributingContent = contributingFile.readAsStringSync();
    });

    group('NEW_COUNTRY.md references all required files', () {
      final requiredPaths = <String, String>{
        'lib/core/services/impl/': 'station service implementation directory',
        'lib/core/services/service_providers.dart': 'service registry',
        'lib/core/services/service_result.dart': 'ServiceSource enum',
        'lib/core/country/country_config.dart': 'country configuration',
        'lib/core/country/country_bounding_box.dart': 'bounding box',
        'lib/features/search/domain/entities/fuel_type.dart':
            'fuel type mapping',
      };

      for (final entry in requiredPaths.entries) {
        test('mentions ${entry.value} (${entry.key})', () {
          expect(guideContent, contains(entry.key),
              reason:
                  'NEW_COUNTRY.md must reference ${entry.key} (${entry.value})');
        });
      }
    });

    group('NEW_COUNTRY.md references key patterns', () {
      final requiredPatterns = <String, String>{
        'StationService': 'the abstract service interface',
        'StationServiceHelpers': 'the helpers mixin',
        'ServiceSource': 'the service source enum',
        'CountryConfig': 'the country config class',
        'CountryBoundingBox': 'the bounding box class',
        'fuelTypesForCountry': 'the fuel type mapping function',
        'StationServiceChain': 'the service chain wrapper',
        'DioFactory': 'the Dio factory',
        'Countries.all': 'the all-countries list',
      };

      for (final entry in requiredPatterns.entries) {
        test('mentions ${entry.value} (${entry.key})', () {
          expect(guideContent, contains(entry.key),
              reason:
                  'NEW_COUNTRY.md must reference ${entry.key} (${entry.value})');
        });
      }
    });

    group('NEW_COUNTRY.md mentions testing', () {
      test('mentions writing tests', () {
        expect(guideContent, contains('test'),
            reason: 'Guide must mention testing');
      });

      test('mentions flutter analyze', () {
        expect(guideContent, contains('flutter analyze'),
            reason: 'Guide must mention running flutter analyze');
      });

      test('mentions flutter test', () {
        expect(guideContent, contains('flutter test'),
            reason: 'Guide must mention running flutter test');
      });
    });

    group('docs/CONTRIBUTING.md completeness', () {
      test('references NEW_COUNTRY.md', () {
        expect(contributingContent, contains('NEW_COUNTRY.md'),
            reason: 'docs/CONTRIBUTING.md must link to the new-country guide');
      });

      test('contains new-country checklist', () {
        // Every required file must appear in the checklist
        final requiredChecklist = [
          'station_service.dart',
          'service_providers.dart',
          'service_result.dart',
          'country_config.dart',
          'country_bounding_box.dart',
          'fuel_type.dart',
        ];

        for (final item in requiredChecklist) {
          expect(contributingContent, contains(item),
              reason: 'docs/CONTRIBUTING.md checklist must mention $item');
        }
      });

      test('mentions conventional commits', () {
        expect(contributingContent, contains('conventional commit'),
            reason: 'docs/CONTRIBUTING.md must mention conventional commits');
      });

      test('mentions flutter analyze', () {
        expect(contributingContent, contains('flutter analyze'),
            reason: 'docs/CONTRIBUTING.md must mention running flutter analyze');
      });
    });

    group('All existing country services have registry entries', () {
      test('every service in impl/ has a factory entry or DE special case', () {
        final implDir = Directory('lib/core/services/impl');
        if (!implDir.existsSync()) return;

        final serviceProviders =
            File('lib/core/services/service_providers.dart')
                .readAsStringSync();
        final registryFile =
            File('lib/core/services/country_service_registry.dart');
        final registryContent = registryFile.existsSync()
            ? registryFile.readAsStringSync()
            : '';

        final serviceFiles = implDir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.endsWith('_station_service.dart') &&
                !f.path.contains('demo_station_service'))
            .toList();

        for (final file in serviceFiles) {
          final fileName = file.uri.pathSegments.last;

          // Check that the file is imported in service_providers.dart or registry
          expect(
            serviceProviders.contains(fileName) ||
                registryContent.contains(fileName),
            isTrue,
            reason:
                'service_providers.dart or country_service_registry.dart must import $fileName',
          );
        }
      });
    });
  });
}
