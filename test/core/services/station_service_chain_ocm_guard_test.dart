// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/non_fuel_station_guard.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';

class MockStationService extends Mock implements StationService {}

class MockCacheManager extends Mock implements CacheManager {}

/// #3455 — the chain-level guard that makes the field-verified 400 storm
/// path structurally dead: an OpenChargeMap `ocm-*` EV id reaching
/// [StationServiceChain.getStationDetail] is rejected with a typed,
/// NON-RETRYING [NonFuelStationIdException] BEFORE the cache/retry
/// machinery — the upstream fuel detail endpoint is never contacted, no
/// cache entry is written, and the rejection lands as a breadcrumb (not
/// an ERROR-log flood at burst rate).
void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(ServiceSource.values.first);
  });
  late MockStationService primary;
  late MockCacheManager cache;
  late StationServiceChain chain;

  setUp(() {
    primary = MockStationService();
    cache = MockCacheManager();
    chain = StationServiceChain(
      primary,
      cache,
      countryCode: 'FR',
    );
  });

  group('non_fuel_station_guard unit contract', () {
    test('isNonFuelStationId recognises the OCM prefix only', () {
      expect(isNonFuelStationId('ocm-196522'), isTrue);
      expect(isNonFuelStationId('fr-12345'), isFalse);
      expect(isNonFuelStationId('de-abc'), isFalse);
      // No accidental substring match — the prefix must lead.
      expect(isNonFuelStationId('fr-ocm-1'), isFalse);
    });

    test('rejectNonFuelStationId throws typed + breadcrumbs for ocm ids', () {
      expect(
        () => rejectNonFuelStationId('ocm-196522', countryCode: 'FR'),
        throwsA(isA<NonFuelStationIdException>()
            .having((e) => e.stationId, 'stationId', 'ocm-196522')),
      );
      expect(
        BreadcrumbCollector.snapshot()
            .any((b) => b.action.contains('non-fuel id rejected')),
        isTrue,
        reason: 'the rejection must be an actionable breadcrumb (#3370 '
            'de-noise pattern), not silent',
      );
    });

    test('rejectNonFuelStationId is a no-op for fuel ids', () {
      expect(
        () => rejectNonFuelStationId('fr-12345', countryCode: 'FR'),
        returnsNormally,
      );
    });
  });

  group('StationServiceChain.getStationDetail ocm guard (#3455)', () {
    test('rejects an ocm id without EVER touching primary or cache', () async {
      await expectLater(
        chain.getStationDetail('ocm-196522'),
        throwsA(isA<NonFuelStationIdException>()),
      );

      // The 400-storm path is structurally dead: zero upstream calls,
      // zero cache reads/writes — nothing for a refresh loop to retry.
      verifyNever(() => primary.getStationDetail(any()));
      verifyZeroInteractions(cache);
    });

    test('the rejection is non-retrying: N calls → still zero upstream',
        () async {
      for (var i = 0; i < 3; i++) {
        await expectLater(
          chain.getStationDetail('ocm-196522'),
          throwsA(isA<NonFuelStationIdException>()),
        );
      }
      verifyNever(() => primary.getStationDetail(any()));
    });

    test('fuel ids still flow through the normal chain', () async {
      const detail = StationDetail(
        station: Station(
          id: 'fr-1',
          name: 'Total Alpha',
          brand: 'Total',
          street: 'Rue A',
          postCode: '75001',
          place: 'Paris',
          lat: 48.8,
          lng: 2.3,
          isOpen: true,
        ),
      );
      when(() => cache.getFresh(any())).thenReturn(null);
      when(() => cache.get(any())).thenReturn(null);
      when(() => cache.put(any(), any(),
          ttl: any(named: 'ttl'),
          source: any(named: 'source'))).thenAnswer((_) async {});
      when(() => primary.getStationDetail('fr-1')).thenAnswer(
        (_) async => ServiceResult(
          data: detail,
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        ),
      );

      final result = await chain.getStationDetail('fr-1');
      expect(result.data.station.id, 'fr-1');
      verify(() => primary.getStationDetail('fr-1')).called(1);
    });
  });
}
