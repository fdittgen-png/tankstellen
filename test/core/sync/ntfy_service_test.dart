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

    test(
        'sendTestNotification — 200 → NtfyPostResult(success=true, '
        'statusCode=200, reason="ok") (#2001 rich return)', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
          ));

      final result = await service.sendTestNotification('test-topic');
      expect(result.success, isTrue);
      expect(result.statusCode, 200);
      expect(result.topic, 'test-topic');
      expect(result.reason, 'ok');
    });

    test(
        'sendTestNotification — non-200 status surfaces as success=false '
        'with the unexpected status reason (#2001)', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 429,
          ));

      final result = await service.sendTestNotification('test-topic');
      expect(result.success, isFalse);
      expect(result.statusCode, 429);
      expect(result.reason, contains('429'));
    });

    test(
        'sendTestNotification — DioException → success=false + reason '
        'carries the dio error type so the foreground snackbar can show '
        'a real cause (#2001)', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionError,
            message: 'No route to host',
          ));

      final result = await service.sendTestNotification('test-topic');
      expect(result.success, isFalse);
      expect(result.topic, 'test-topic');
      // statusCode is null because the connection never reached the
      // server — that's the signal for "your device cannot talk to
      // ntfy.sh", not "ntfy.sh rejected the request".
      expect(result.statusCode, isNull);
      expect(result.reason, contains('No route to host'));
    });
  });
}
