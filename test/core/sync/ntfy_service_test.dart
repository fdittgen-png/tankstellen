import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/sync/ntfy_service.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockDio mockDio;
  late NtfyService service;

  setUp(() {
    mockDio = MockDio();
    service = NtfyService(dio: mockDio);
  });

  setUpAll(() {
    registerFallbackValue(Options());
  });

  group('NtfyService', () {
    test('generateTopic returns correct format', () {
      final topic = service.generateTopic('abc-123');
      expect(topic, equals('tankstellen-abc-123'));
    });

    test('sendTestNotification returns true on success', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ));

      final result = await service.sendTestNotification('test-topic');
      expect(result, isTrue);
    });

    test('sendTestNotification returns false on DioException', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
          ));

      final result = await service.sendTestNotification('test-topic');
      expect(result, isFalse);
    });
  });
}
