import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/setup/data/api_key_validator.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ApiKeyValidator validator;

  setUp(() {
    mockDio = MockDio();
    validator = ApiKeyValidator(dio: mockDio);
  });

  test('returns valid when API responds with ok=true', () async {
    when(() => mockDio.get(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {'ok': true, 'stations': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/list.php'),
            ));

    final result = await validator.validate('test-api-key');

    expect(result.isValid, true);
  });

  test('returns invalid with message when API responds with ok=false',
      () async {
    when(() => mockDio.get(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {'ok': false, 'message': 'apikey invalid'},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/list.php'),
            ));

    final result = await validator.validate('bad-key');

    expect(result.isValid, false);
    expect(result.errorMessage, contains('apikey invalid'));
  });

  test('returns invalid on DioException', () async {
    when(() => mockDio.get(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: '/list.php'),
      message: 'Connection refused',
    ));

    final result = await validator.validate('test-key');

    expect(result.isValid, false);
  });

  test('returns invalid on timeout', () async {
    when(() => mockDio.get(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
      type: DioExceptionType.connectionTimeout,
      requestOptions: RequestOptions(path: '/list.php'),
      message: 'Connection timeout',
    ));

    final result = await validator.validate('test-key');

    expect(result.isValid, false);
    expect(result.errorMessage, isNotNull);
  });

  test('includes error message from API response', () async {
    when(() => mockDio.get(any(),
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {
                'ok': false,
                'message': 'API rate limit exceeded',
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/list.php'),
            ));

    final result = await validator.validate('rate-limited-key');

    expect(result.isValid, false);
    expect(result.errorMessage, contains('API rate limit exceeded'));
  });

  test('uses default Dio when none provided', () {
    // Verify that constructing without a Dio parameter does not throw.
    final defaultValidator = ApiKeyValidator();
    expect(defaultValidator, isNotNull);
  });
}
