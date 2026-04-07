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

  group('isValidUuidFormat', () {
    test('accepts valid UUID v4 format', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            '12345678-1234-1234-1234-123456789abc'),
        true,
      );
    });

    test('accepts uppercase hex characters', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            'ABCDEF01-2345-6789-ABCD-EF0123456789'),
        true,
      );
    });

    test('accepts mixed case hex characters', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            'abCDef01-2345-6789-AbCd-ef0123456789'),
        true,
      );
    });

    test('trims whitespace before validation', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            '  12345678-1234-1234-1234-123456789abc  '),
        true,
      );
    });

    test('rejects empty string', () {
      expect(ApiKeyValidator.isValidUuidFormat(''), false);
    });

    test('rejects string without dashes', () {
      expect(
        ApiKeyValidator.isValidUuidFormat('1234567812341234123412345678abcd'),
        false,
      );
    });

    test('rejects wrong segment lengths', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            '1234567-1234-1234-1234-123456789abc'),
        false,
      );
    });

    test('rejects non-hex characters', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            'GHIJKLMN-1234-1234-1234-123456789abc'),
        false,
      );
    });

    test('rejects partial UUID', () {
      expect(
        ApiKeyValidator.isValidUuidFormat('12345678-1234'),
        false,
      );
    });

    test('rejects UUID with extra segment', () {
      expect(
        ApiKeyValidator.isValidUuidFormat(
            '12345678-1234-1234-1234-123456789abc-extra'),
        false,
      );
    });

    test('rejects random text', () {
      expect(ApiKeyValidator.isValidUuidFormat('not-a-valid-key'), false);
    });
  });
}
