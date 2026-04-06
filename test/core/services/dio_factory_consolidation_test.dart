import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioFactory consolidation regression', () {
    test('no Dio(BaseOptions outside DioFactory and background_service', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('.g.dart'))
          .where((f) => !f.path.contains('.freezed.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final relPath = file.path.replaceAll('\\', '/');
        // DioFactory itself is allowed to use Dio(BaseOptions)
        if (relPath.contains('dio_factory.dart')) continue;
        // Background service runs in a separate isolate — may use direct Dio
        if (relPath.contains('background_service.dart')) continue;

        final content = file.readAsStringSync();
        if (content.contains('Dio(BaseOptions')) {
          violations.add(relPath);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'These files use Dio(BaseOptions) instead of DioFactory.create(): '
            '${violations.join(', ')}',
      );
    });

    test('key service files import dio_factory.dart', () {
      final filesToCheck = [
        'lib/core/services/service_providers.dart',
        'lib/core/services/location_search_service.dart',
        'lib/core/services/impl/osm_brand_enricher.dart',
        'lib/core/services/impl/nominatim_geocoding_provider.dart',
        'lib/core/error_tracing/upload/trace_uploader.dart',
        'lib/features/setup/data/api_key_validator.dart',
        'lib/core/sync/ntfy_service.dart',
      ];

      for (final path in filesToCheck) {
        final content = File(path).readAsStringSync();
        expect(
          content.contains('dio_factory'),
          isTrue,
          reason: '$path should import dio_factory.dart',
        );
      }
    });
  });
}
