import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/portugal_station_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';

void main() {
  late PortugalStationService service;

  setUp(() {
    service = PortugalStationService();
  });

  group('PortugalStationService', () {
    test('implements StationService interface', () {
      expect(service, isA<StationService>());
    });

    test('getStationDetail throws ApiException', () {
      expect(
        () => service.getStationDetail('pt-123'),
        throwsA(isA<Exception>()),
      );
    });

    test('getPrices returns empty map', () async {
      final result = await service.getPrices(['pt-1', 'pt-2']);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.portugalApi);
    });
  });
}
