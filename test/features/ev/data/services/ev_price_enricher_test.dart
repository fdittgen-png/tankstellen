// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/ev/data/services/ev_price_enricher.dart';
import 'package:tankstellen/features/ev/data/services/fr_irve_price_service.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';

class MockDio extends Mock implements Dio {}

void main() {
  // The EvPriceEnricher.enrich contract is documented "never thrown":
  // a fault in the underlying source must degrade to the un-enriched
  // input, never propagate. These tests inject the fault and assert the
  // call returns normally (#2349 never-throws ratchet).
  const paris = ChargingStation(
    id: 'ocm-fr',
    name: 'FR Hub',
    latitude: 48.8566,
    longitude: 2.3522,
  );

  group('EvPriceEnricher never-throws contract', () {
    test('NoopEvPriceEnricher returns the input unchanged and completes',
        () async {
      const enricher = NoopEvPriceEnricher();
      await expectLater(enricher.enrich(const [paris]), completes);
      expect(await enricher.enrich(const [paris]), equals(const [paris]));
    });

    test('FR enricher swallows a thrown network fault (returnsNormally)',
        () async {
      final dio = MockDio();
      when(() => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/records'),
        type: DioExceptionType.connectionError,
      ));
      final EvPriceEnricher enricher = FrIrvePriceService(dio: dio);

      // The fault must not propagate — the call completes with the
      // un-enriched input.
      await expectLater(enricher.enrich(const [paris]), completes);
      final out = await enricher.enrich(const [paris]);
      expect(out.single.isFranceIrveEnriched, isFalse);
    });

    test('FR enricher tolerates a malformed payload', () async {
      final dio = MockDio();
      when(() => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/records'),
            statusCode: 200,
            data: 'not-a-json-object',
          ));
      final EvPriceEnricher enricher = FrIrvePriceService(dio: dio);

      await expectLater(enricher.enrich(const [paris]), completes);
      final out = await enricher.enrich(const [paris]);
      expect(out.single, equals(paris));
    });
  });
}
