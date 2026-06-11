// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/ev/data/services/fr_irve_price_service.dart';
import 'package:tankstellen/core/domain/ev/charging_station.dart';
import 'package:tankstellen/core/domain/ev/ev_access_cost.dart';

class MockDio extends Mock implements Dio {}

void main() {
  // A captured-shape ODRÉ `bornes-irve/records` response. Field shapes
  // and the messy `gratuit` casing mirror the live dataset (#2618):
  //   distinct gratuit values observed: null, 0, 1, FALSE, False, TRUE,
  //   True, false, true.
  Map<String, dynamic> ocmResponse(List<Map<String, dynamic>> results) => {
        'total_count': results.length,
        'results': results,
      };

  Map<String, dynamic> irveRow({
    required double lat,
    required double lng,
    Object? gratuit,
    String? tarification,
  }) =>
      {
        'nom_station': 'Test station',
        'id_station_itinerance': 'FRTEST0001',
        'gratuit': gratuit,
        'tarification': tarification,
        'consolidated_latitude': lat,
        'consolidated_longitude': lng,
      };

  // A station in Paris (clearly inside the FR bounding box).
  ChargingStation frStation({double lat = 48.8566, double lng = 2.3522}) =>
      ChargingStation(
        id: 'ocm-1',
        name: 'OCM Hub',
        latitude: lat,
        longitude: lng,
      );

  MockDio dioReturning(Map<String, dynamic> data) {
    final dio = MockDio();
    when(() => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/records'),
          statusCode: 200,
          data: data,
        ));
    return dio;
  }

  group('FrIrvePriceService.enrich', () {
    test('non-FR station → no-op, NO HTTP call', () async {
      final dio = MockDio();
      final service = FrIrvePriceService(dio: dio);

      // Berlin — outside the FR bounding box.
      const berlin = ChargingStation(
        id: 'ocm-de',
        name: 'DE Hub',
        latitude: 52.52,
        longitude: 13.405,
      );

      final out = await service.enrich([berlin]);

      expect(out, equals([berlin]));
      verifyNever(() => dio.get<dynamic>(any(),
          queryParameters: any(named: 'queryParameters')));
    });

    test('match within 75 m + gratuit "True" → free (clears pay flag)',
        () async {
      final station = frStation();
      final dio = dioReturning(ocmResponse([
        // ~10 m away.
        irveRow(lat: 48.85661, lng: 2.35221, gratuit: 'True'),
      ]));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([
        station.copyWith(isPayAtLocation: true),
      ]);

      expect(out.single.isFranceIrveEnriched, isTrue);
      // Confirmed-free → explicit `false`, which reads as a free badge.
      expect(out.single.isPayAtLocation, isFalse);
      expect(out.single.accessCost.kind, EvAccessCostKind.free);
    });

    test('match + gratuit "False" + tarification → paid + indicative text',
        () async {
      final station = frStation();
      final dio = dioReturning(ocmResponse([
        irveRow(
          lat: 48.85662,
          lng: 2.35222,
          gratuit: 'False',
          tarification: '0,40 €/kWh',
        ),
      ]));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([station]);

      expect(out.single.isFranceIrveEnriched, isTrue);
      expect(out.single.isPayAtLocation, isTrue);
      expect(out.single.usageCost, '0,40 €/kWh');
      expect(out.single.accessCost.kind, EvAccessCostKind.paid);
    });

    test('tarification null leaves the original usageCost intact', () async {
      final station = frStation().copyWith(usageCost: 'Ask operator');
      final dio = dioReturning(ocmResponse([
        irveRow(lat: 48.85661, lng: 2.35221, gratuit: 'True', tarification: null),
      ]));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([station]);

      expect(out.single.usageCost, 'Ask operator');
      expect(out.single.isFranceIrveEnriched, isTrue);
    });

    test('"Inconnu" tarification is treated as no-value', () async {
      final station = frStation().copyWith(usageCost: 'keep me');
      final dio = dioReturning(ocmResponse([
        irveRow(
          lat: 48.85661,
          lng: 2.35221,
          gratuit: 'False',
          tarification: 'Inconnu',
        ),
      ]));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([station]);

      expect(out.single.usageCost, 'keep me');
      expect(out.single.isPayAtLocation, isTrue);
    });

    test('no record within 75 m → station unchanged', () async {
      final station = frStation();
      final dio = dioReturning(ocmResponse([
        // ~1.5 km away (well outside 75 m).
        irveRow(lat: 48.870, lng: 2.352, gratuit: 'True'),
      ]));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([station]);

      expect(out.single.isFranceIrveEnriched, isFalse);
      expect(out.single, equals(station));
    });

    test('HTTP error → graceful no-enrichment, does NOT throw', () async {
      final station = frStation();
      final dio = MockDio();
      when(() => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/records'),
        type: DioExceptionType.connectionError,
      ));
      final service = FrIrvePriceService(dio: dio);

      final out = await service.enrich([station]);

      expect(out.single, equals(station));
      expect(out.single.isFranceIrveEnriched, isFalse);
    });

    group('gratuit normalization table', () {
      // Every casing observed in the live dataset.
      const freeValues = <Object?>['True', 'true', 'TRUE', '1'];
      const paidValues = <Object?>['False', 'false', 'FALSE', '0'];
      const unknownValues = <Object?>[null, '', 'maybe', 'Inconnu'];

      for (final v in freeValues) {
        test('gratuit "$v" → free', () async {
          final dio = dioReturning(ocmResponse([
            irveRow(lat: 48.85661, lng: 2.35221, gratuit: v),
          ]));
          final out = await FrIrvePriceService(dio: dio)
              .enrich([frStation().copyWith(isPayAtLocation: true)]);
          expect(out.single.isPayAtLocation, isFalse, reason: '$v');
          expect(out.single.isFranceIrveEnriched, isTrue);
        });
      }

      for (final v in paidValues) {
        test('gratuit "$v" → paid', () async {
          final dio = dioReturning(ocmResponse([
            irveRow(lat: 48.85661, lng: 2.35221, gratuit: v),
          ]));
          final out =
              await FrIrvePriceService(dio: dio).enrich([frStation()]);
          expect(out.single.isPayAtLocation, isTrue, reason: '$v');
        });
      }

      for (final v in unknownValues) {
        test('gratuit "$v" → unknown (pay flag untouched)', () async {
          final dio = dioReturning(ocmResponse([
            irveRow(lat: 48.85661, lng: 2.35221, gratuit: v),
          ]));
          final out = await FrIrvePriceService(dio: dio)
              .enrich([frStation()]); // original isPayAtLocation == null
          // Enriched (matched) but the free/paid signal stays unknown.
          expect(out.single.isFranceIrveEnriched, isTrue, reason: '$v');
          expect(out.single.isPayAtLocation, isNull, reason: '$v');
        });
      }
    });

    test('one bbox query covers a multi-station result set', () async {
      final dio = dioReturning(ocmResponse([
        irveRow(lat: 48.85661, lng: 2.35221, gratuit: 'True'),
        irveRow(lat: 48.860, lng: 2.340, gratuit: 'False'),
      ]));
      final service = FrIrvePriceService(dio: dio);

      await service.enrich([
        frStation(),
        frStation(lat: 48.860, lng: 2.340),
      ]);

      // A single viewport query, not one per station.
      verify(() => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });

    test('second identical viewport is served from cache (no 2nd HTTP)',
        () async {
      final dio = dioReturning(ocmResponse([
        irveRow(lat: 48.85661, lng: 2.35221, gratuit: 'True'),
      ]));
      final service = FrIrvePriceService(dio: dio);

      await service.enrich([frStation()]);
      await service.enrich([frStation()]);

      verify(() => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).called(1);
    });
  });
}
