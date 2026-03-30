import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/uk_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';

void main() {
  late UkStationService service;

  setUp(() {
    service = UkStationService();
  });

  group('UkStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => service.getStationDetail('uk-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map', () async {
      final result = await service.getPrices(['uk-1', 'uk-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.ukApi);
    });
  });
}
