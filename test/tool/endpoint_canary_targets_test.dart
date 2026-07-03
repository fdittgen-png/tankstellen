// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/romania/romania_station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_station_service.dart';

import '../../tool/endpoint_canary.dart';

/// #3457 — canary-vs-service endpoint drift guards.
///
/// The canary tool declares its probe URLs by hand (it cannot import the
/// Flutter-importing service classes), so nothing structural stopped the RO
/// probe from still pointing at the dead third-party `pretcarburant.ro` long
/// after #3193 rebased the service onto the official
/// `monitorulpreturilor.info` observatory — the weekly canary then reported a
/// bogus RO outage (#3409 run of 2026-06-29). These tests import BOTH sides
/// and fail on drift, so a service endpoint change without the matching
/// canary update can no longer ship.
void main() {
  CanaryTarget targetFor(String country) =>
      targets.singleWhere((t) => t.country == country);

  group('endpoint canary ↔ service endpoint drift (#3457)', () {
    test('RO probe mirrors RomaniaStationService.defaultBaseUrl + searchPath',
        () {
      final ro = targetFor('RO');
      expect(ro.skip, isNull, reason: 'RO has a live keyless endpoint');
      expect(
        ro.url,
        startsWith(
          '${RomaniaStationService.defaultBaseUrl}'
          '${RomaniaStationService.searchPath}',
        ),
      );
      // The observatory quirks (see the service docs): exactly ONE catalog
      // product id per request, and JSON only via content negotiation.
      expect(ro.url, contains('CSVGasCatalogProductIds=11'));
      expect(ro.headers['Accept'], 'application/json');
      expect(ro.bodyMarker, '"Stations"');
    });

    test('no probe references the dead third-party pretcarburant.ro', () {
      for (final t in targets) {
        expect(t.url ?? '', isNot(contains('pretcarburant')),
            reason: '${t.country} probe must not target the retired '
                'third-party mirror (#3193/#3457)');
      }
    });

    test('GB probe is one of the shipped legacy retailer feeds', () {
      final gb = targetFor('GB');
      expect(
        UkStationService.defaultCmaFeedUrls,
        contains(gb.url),
        reason: 'the GB sentinel must probe a feed the fallback fan-out '
            'actually calls (#3190)',
      );
    });
  });
}
