import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Standardized error recovery pattern', () {
    /// All country station services that use StationServiceHelpers should
    /// call throwApiException in their searchStations catch blocks instead
    /// of manually constructing and throwing ApiException.
    final serviceFiles = [
      'lib/core/services/impl/tankerkoenig_station_service.dart',
      'lib/core/services/impl/argentina_station_service.dart',
      'lib/core/services/impl/mise_station_service.dart',
      'lib/core/services/impl/econtrol_station_service.dart',
      'lib/core/services/impl/miteco_station_service.dart',
      'lib/core/services/impl/denmark_station_service.dart',
      // UK service intentionally omitted: it fans out to many retailer
      // feeds and isolates DioException per-feed instead of bubbling
      // through a single `throwApiException` at the top level.
      'lib/core/services/impl/australia_station_service.dart',
      'lib/core/services/impl/mexico_station_service.dart',
      'lib/core/services/impl/portugal_station_service.dart',
    ];

    for (final path in serviceFiles) {
      final name = path.split('/').last.replaceAll('_station_service.dart', '');

      test('$name service uses throwApiException in searchStations', () {
        final source = File(path).readAsStringSync();

        // Find the searchStations method and its DioException catch
        final searchStart = source.indexOf('searchStations');
        if (searchStart == -1) return; // some services don't have searchStations

        final afterSearch = source.substring(searchStart);
        final catchBlock = afterSearch.indexOf('on DioException catch');
        if (catchBlock == -1) return;

        // Check the catch block uses throwApiException, not throw ApiException(
        final catchArea = afterSearch.substring(
          catchBlock,
          catchBlock + 200 < afterSearch.length
              ? catchBlock + 200
              : afterSearch.length,
        );

        expect(
          catchArea.contains('throwApiException'),
          isTrue,
          reason: '$name service should use throwApiException mixin in '
              'searchStations catch block, not manual throw ApiException',
        );
      });
    }
  });
}
