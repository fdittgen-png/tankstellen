// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/mixins/cached_dataset_mixin.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';

/// #2264 concern 7 — UK / PT / MX route their unsupported endpoints through
/// the shared StationServiceHelpers (throwDetailUnavailable / emptyPricesResult)
/// instead of inline throws + inline ServiceResults, and Mexico is on the
/// CachedDatasetMixin like the other bulk-dataset services.

void main() {
  group('Mexico migrated onto CachedDatasetMixin (#2264)', () {
    test('MexicoStationService is a CachedDatasetMixin', () {
      expect(MexicoStationService(), isA<CachedDatasetMixin>());
    });
  });

  group('Shared unsupported-endpoint helpers (#2264)', () {
    final services = <String, StationService>{
      'UK': UkStationService(),
      'PT': PortugalStationService(),
      'MX': MexicoStationService(),
    };

    for (final entry in services.entries) {
      test('${entry.key} getStationDetail throws the shared ApiException',
          () async {
        try {
          await entry.value.getStationDetail('${entry.key}-1');
          fail('Expected ApiException');
        } on ApiException catch (e) {
          // throwDetailUnavailable stamps a "Detail not available from …"
          // message — the shared helper's wording, not an inline literal.
          expect(e.message, contains('Detail not available from'),
              reason: '${entry.key} must use throwDetailUnavailable');
        }
      });

      test('${entry.key} getPrices returns the shared empty result', () async {
        final result = await entry.value.getPrices(['${entry.key}-1']);
        expect(result.data, isEmpty);
        expect(result.source, isA<ServiceSource>());
      });
    }
  });
}
