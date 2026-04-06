import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_retry.dart';

void main() {
  group('isRetryable', () {
    test('connectionTimeout is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        )),
        isTrue,
      );
    });

    test('sendTimeout is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(),
        )),
        isTrue,
      );
    });

    test('receiveTimeout is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        )),
        isTrue,
      );
    });

    test('connectionError is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        )),
        isTrue,
      );
    });

    test('500 server error is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ),
        )),
        isTrue,
      );
    });

    test('503 service unavailable is retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 503,
          ),
        )),
        isTrue,
      );
    });

    test('400 bad request is not retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
          ),
        )),
        isFalse,
      );
    });

    test('404 not found is not retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
        )),
        isFalse,
      );
    });

    test('cancel is not retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(),
        )),
        isFalse,
      );
    });

    test('badCertificate is not retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.badCertificate,
          requestOptions: RequestOptions(),
        )),
        isFalse,
      );
    });

    test('unknown is not retryable', () {
      expect(
        isRetryable(DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(),
        )),
        isFalse,
      );
    });
  });

  group('BackgroundRetryConfig', () {
    test('default config has 3 attempts and 2s base delay', () {
      const config = BackgroundRetryConfig();
      expect(config.maxAttempts, 3);
      expect(config.baseDelay, const Duration(seconds: 2));
    });

    test('custom config overrides defaults', () {
      const config = BackgroundRetryConfig(
        maxAttempts: 5,
        baseDelay: Duration(seconds: 1),
      );
      expect(config.maxAttempts, 5);
      expect(config.baseDelay, const Duration(seconds: 1));
    });
  });

  group('fetchWithRetry', () {
    late Dio dio;
    late _MockAdapter adapter;

    setUp(() {
      adapter = _MockAdapter();
      dio = Dio()..httpClientAdapter = adapter;
    });

    test('returns data on first success', () async {
      adapter.responses = [
        _MockResponse(data: {'ok': true, 'prices': {}}, statusCode: 200),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {'key': 'value'},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNotNull);
      expect(result!['ok'], isTrue);
      expect(adapter.requestCount, 1);
    });

    test('retries on timeout and succeeds on second attempt', () async {
      adapter.responses = [
        _MockResponse(
          error: DioExceptionType.connectionTimeout,
        ),
        _MockResponse(data: {'ok': true, 'result': 42}, statusCode: 200),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNotNull);
      expect(result!['result'], 42);
      expect(adapter.requestCount, 2);
    });

    test('returns null after exhausting all retries', () async {
      adapter.responses = [
        _MockResponse(error: DioExceptionType.connectionTimeout),
        _MockResponse(error: DioExceptionType.connectionTimeout),
        _MockResponse(error: DioExceptionType.connectionTimeout),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNull);
      expect(adapter.requestCount, 3);
    });

    test('does not retry on non-retryable error (cancel)', () async {
      adapter.responses = [
        _MockResponse(error: DioExceptionType.cancel),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNull);
      expect(adapter.requestCount, 1);
    });

    test('retries on 500 server error', () async {
      adapter.responses = [
        _MockResponse(statusCode: 500),
        _MockResponse(data: {'recovered': true}, statusCode: 200),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNotNull);
      expect(result!['recovered'], isTrue);
      expect(adapter.requestCount, 2);
    });

    test('does not retry on 404 client error', () async {
      adapter.responses = [
        _MockResponse(statusCode: 404),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 3,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNull);
      expect(adapter.requestCount, 1);
    });

    test('returns null when response data is not a Map', () async {
      adapter.responses = [
        _MockResponse(data: 'not a map', statusCode: 200),
      ];

      final result = await fetchWithRetry(
        dio: dio,
        url: 'https://example.com/api',
        queryParameters: {},
        config: const BackgroundRetryConfig(
          maxAttempts: 1,
          baseDelay: Duration(milliseconds: 1),
        ),
      );

      expect(result, isNull);
    });
  });
}

/// Mock response definition for testing.
class _MockResponse {
  final dynamic data;
  final int statusCode;
  final DioExceptionType? error;

  _MockResponse({this.data, this.statusCode = 200, this.error});
}

/// Simple mock HTTP adapter that returns predefined responses in order.
class _MockAdapter implements HttpClientAdapter {
  List<_MockResponse> responses = [];
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = requestCount++;
    if (index >= responses.length) {
      throw DioException(
        type: DioExceptionType.connectionError,
        requestOptions: options,
        message: 'No more mock responses',
      );
    }

    final mock = responses[index];

    if (mock.error != null) {
      if (mock.error == DioExceptionType.badResponse) {
        throw DioException(
          type: DioExceptionType.badResponse,
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: mock.statusCode,
          ),
        );
      }
      throw DioException(
        type: mock.error!,
        requestOptions: options,
      );
    }

    if (mock.statusCode >= 400) {
      throw DioException(
        type: DioExceptionType.badResponse,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: mock.statusCode,
          data: mock.data,
        ),
      );
    }

    final jsonString = mock.data is String
        ? mock.data as String
        : jsonEncode(mock.data);
    return ResponseBody.fromString(
      jsonString,
      mock.statusCode,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
