// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/telemetry/collectors/app_state_collector.dart';
import 'package:tankstellen/features/search/providers/last_search_breadcrumb.dart';

/// #2320 — search-failure traces carry an anonymised breadcrumb of the last
/// search. #4235 — the format and the PII contract are EXECUTED against
/// [lastSearchBreadcrumb]; only the wiring (every entry point records it)
/// stays a static wiring guard, because the entry points need real HTTP,
/// geocoding and GPS services flutter_test cannot stand up.
void main() {
  group('lastSearchBreadcrumb (#2320, executable since #4235)', () {
    test('carries mode, fuel, radius and sort — and nothing else', () {
      final crumb = lastSearchBreadcrumb('gps',
          fuelType: FuelType.diesel, radiusKm: 10.4, sortBy: SortBy.price);
      expect(crumb,
          'mode=gps fuel=${FuelType.diesel.name} radiusKm=10 sort=${SortBy.price.apiValue}');
      expect(
          crumb.split(' ').map((token) => token.split('=').first).toList(),
          ['mode', 'fuel', 'radiusKm', 'sort'],
          reason: 'no other field can leak into an error trace');
    });

    test('unset filters read "default"', () {
      expect(lastSearchBreadcrumb('zip'),
          'mode=zip fuel=default radiusKm=default sort=default');
    });

    test('the collector stores what it is given', () {
      expect(
          () => AppStateCollector.updateLastSearch(
              lastSearchBreadcrumb('coordinates', radiusKm: 5)),
          returnsNormally);
    });
  });

  group('static wiring guard: every entry point records its search', () {
    late String src;

    setUpAll(() {
      src = File('lib/features/search/providers/search_provider.dart')
          .readAsStringSync();
    });

    test('each search entry records the last search', () {
      for (final entry in [
        'searchByGps',
        'searchByZipCode',
        'searchByCoordinates'
      ]) {
        final start = src.indexOf('Future<void> $entry');
        expect(start, isNonNegative, reason: '$entry must exist');
        final next = src.indexOf('Future<void> ', start + 1);
        final body = src.substring(start, next < 0 ? src.length : next);
        expect(body, contains('_recordLastSearch'),
            reason: '$entry must record its search');
      }
    });

    test('the recorder routes the formatter into the collector', () {
      expect(
          src,
          contains('AppStateCollector.updateLastSearch(lastSearchBreadcrumb('),
          reason: 'the executable formatter above is what reaches traces');
    });
  });
}
