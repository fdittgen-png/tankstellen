import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/australia_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';

void main() {
  const service = AustraliaStationService();

  group('AustraliaStationService (public surface)', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => service.getStationDetail('au-123'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getPrices returns empty map with correct source', () async {
      final result = await service.getPrices(['au-1', 'au-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.australiaApi);
    });

    test('getPrices returns empty map for empty id list', () async {
      final result = await service.getPrices([]);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.australiaApi);
    });
  });

  group('searchStations (#504 unavailable stop-gap)', () {
    const params = SearchParams(lat: -33.87, lng: 151.21, radiusKm: 5);

    test('throws ApiException on every call', () async {
      expect(
        () => service.searchStations(params),
        throwsA(isA<ApiException>()),
      );
    });

    test('error message names OAuth2 and links the tracking issue',
        () async {
      try {
        await service.searchStations(params);
        fail('expected ApiException');
      } on ApiException catch (e) {
        // These strings drive the error UI + the #500 report body, so
        // pin them explicitly.
        expect(e.message, contains('NSW FuelCheck'));
        expect(e.message, contains('OAuth2'));
        expect(e.message, contains('#504'));
      }
    });

    test('unavailableMessage constant matches the thrown message', () async {
      try {
        await service.searchStations(params);
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.message, AustraliaStationService.unavailableMessage);
      }
    });
  });
}
