import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/error_localizer.dart';
import 'package:tankstellen/core/error/exceptions.dart';

void main() {
  // Test without l10n (null) to verify English fallbacks
  group('ErrorLocalizer (no l10n)', () {
    test('ApiException with 500+ status returns server error', () {
      final msg = ErrorLocalizer.localize(
        const ApiException(message: 'Internal Server Error', statusCode: 500),
        null,
      );
      expect(msg, contains('Server error'));
    });

    test('ApiException with 403 returns API key error', () {
      final msg = ErrorLocalizer.localize(
        const ApiException(message: 'Forbidden', statusCode: 403),
        null,
      );
      expect(msg, contains('API key'));
    });

    test('ApiException with 401 returns API key error', () {
      final msg = ErrorLocalizer.localize(
        const ApiException(message: 'Unauthorized', statusCode: 401),
        null,
      );
      expect(msg, contains('API key'));
    });

    test('ApiException without status returns network error', () {
      final msg = ErrorLocalizer.localize(
        const ApiException(message: 'timeout'),
        null,
      );
      expect(msg, contains('Network error'));
    });

    test('LocationException returns location error', () {
      final msg = ErrorLocalizer.localize(
        const LocationException(message: 'GPS off'),
        null,
      );
      expect(msg, contains('location'));
    });

    test('NoApiKeyException returns setup message', () {
      final msg = ErrorLocalizer.localize(
        const NoApiKeyException(),
        null,
      );
      expect(msg, contains('API key'));
      expect(msg, contains('Settings'));
    });

    test('NoEvApiKeyException returns OpenChargeMap setup message', () {
      final msg = ErrorLocalizer.localize(
        const NoEvApiKeyException(),
        null,
      );
      expect(msg, contains('OpenChargeMap'));
      expect(msg, contains('Settings'));
    });

    test('ServiceChainExhaustedException returns data load error', () {
      final msg = ErrorLocalizer.localize(
        const ServiceChainExhaustedException(errors: []),
        null,
      );
      expect(msg, contains('load data'));
    });

    test('UpstreamCertificateException names the provider host (#837)', () {
      final msg = ErrorLocalizer.localize(
        const UpstreamCertificateException(
          host: 'datos.energia.gob.ar',
          countryCode: 'ar',
          detail: 'HandshakeException: certificate has expired',
        ),
        null,
      );
      // The user has to know WHO to contact — the host must appear in the
      // message, and we must mention the cert problem so the blame is on
      // the provider, not the app.
      expect(msg, contains('datos.energia.gob.ar'));
      expect(msg.toLowerCase(), contains('certificate'));
    });

    test('UpstreamCertificateException does not leak raw Dart error text', () {
      final msg = ErrorLocalizer.localize(
        const UpstreamCertificateException(
          host: 'example.com',
          detail: 'HandshakeException: bad cert',
        ),
        null,
      );
      // The low-level `HandshakeException` string is for logs, not for users.
      expect(msg.contains('HandshakeException'), isFalse,
          reason: 'Raw Dart exception class should not reach the UI');
    });

    test('CacheException returns cache error', () {
      final msg = ErrorLocalizer.localize(
        const CacheException(message: 'corrupt'),
        null,
      );
      expect(msg, contains('cache'));
    });

    test('DioException connectionTimeout returns timeout message', () {
      final msg = ErrorLocalizer.localize(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
        null,
      );
      expect(msg, contains('timed out'));
    });

    test('DioException connectionError returns no connection', () {
      final msg = ErrorLocalizer.localize(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
        null,
      );
      expect(msg, contains('internet'));
    });

    test('DioException cancel returns cancelled', () {
      final msg = ErrorLocalizer.localize(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        ),
        null,
      );
      expect(msg, contains('cancelled'));
    });

    test('unknown error returns generic message', () {
      final msg = ErrorLocalizer.localize(
        Exception('something weird'),
        null,
      );
      expect(msg, contains('unexpected'));
    });

    test('never returns raw exception class name', () {
      final errors = [
        const ApiException(message: 'test', statusCode: 500),
        const LocationException(message: 'test'),
        const NoApiKeyException(),
        const ServiceChainExhaustedException(errors: []),
        const UpstreamCertificateException(host: 'example.com'),
        const CacheException(message: 'test'),
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
        Exception('raw'),
      ];

      for (final error in errors) {
        final msg = ErrorLocalizer.localize(error, null);
        expect(msg.contains('Exception'), isFalse,
            reason: 'Message should not contain raw "Exception": $msg');
        expect(msg.contains('DioException'), isFalse,
            reason: 'Message should not contain raw "DioException": $msg');
      }
    });
  });
}
