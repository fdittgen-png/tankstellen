// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthRetryableFetchException;
import 'package:tankstellen/core/network/dio_offline.dart';

/// #2745 — `isOfflineError` is the OFFLINE SUPERSET used by the telemetry
/// de-noise gate + the offline-tolerant fallback sites. These tests feed the
/// EXACT exception shapes captured in error-log #14 and assert each offline
/// shape is recognised while a GENUINE (non-offline) counterpart is NOT — the
/// guard that keeps real failures ERROR-logging.
void main() {
  group('isOfflineError — offline shapes are recognised (#2745)', () {
    test('a "Failed host lookup" SocketException', () {
      expect(
        isOfflineError(
          const SocketException('Failed host lookup: data.economie.gouv.fr'),
        ),
        isTrue,
      );
    });

    test('a "No address associated with hostname" SocketException', () {
      expect(
        isOfflineError(
          const SocketException(
            'Failed host lookup: xyz.supabase.co '
            '(OS Error: No address associated with hostname, errno = 7)',
          ),
        ),
        isTrue,
      );
    });

    test(
        'a DioException[unknown] wrapping an HttpException connection-abort '
        '(FR trace #1)', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/records'),
        type: DioExceptionType.unknown,
        error: const HttpException('Software caused connection abort'),
      );
      expect(isOfflineError(e), isTrue,
          reason: 'the FR feed connection-abort while offline is transient');
    });

    test('a DioException[connectionError] (offline DNS)', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/reverse'),
        type: DioExceptionType.connectionError,
        error: const SocketException('Failed host lookup: nominatim.org'),
      );
      expect(isOfflineError(e), isTrue);
    });

    test(
        'an AuthRetryableFetchException whose message reports a host lookup '
        'failure (Supabase traces #2–4)', () {
      final e = AuthRetryableFetchException(
        message: 'SocketException: Failed host lookup: '
            'abc.supabase.co (OS Error: No address associated with hostname)',
      );
      expect(isOfflineError(e), isTrue,
          reason: 'an offline supabase retryable fetch is a transient');
    });

    test(
        'a PlatformException(IO_ERROR, …UNAVAILABLE…) from the on-device '
        'geocoder (native trace #7)', () {
      final e = PlatformException(
        code: 'IO_ERROR',
        message: 'grpc failed: UNAVAILABLE: Unable to resolve host',
      );
      expect(isOfflineError(e), isTrue,
          reason: 'the on-device geocoder offline IO error is transient');
    });
  });

  group('isOfflineError — genuine failures are NOT swallowed (the guard)', () {
    test('a DioException[badResponse] (a real 5xx) is NOT offline', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/records'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/records'),
          statusCode: 503,
        ),
      );
      expect(isOfflineError(e), isFalse,
          reason: 'a server 5xx must still ERROR-log');
    });

    test('a connection-refused SocketException (online) is NOT offline', () {
      // No host-lookup / unreachable substring → a real failure.
      expect(
        isOfflineError(const SocketException('Connection refused')),
        isFalse,
      );
    });

    test(
        'an AuthRetryableFetchException caused by a real server blip '
        '(no offline substring) is NOT offline', () {
      final e = AuthRetryableFetchException(
        message: 'Internal Server Error',
        statusCode: '500',
      );
      expect(isOfflineError(e), isFalse,
          reason: 'a non-offline retryable fetch must still ERROR-log');
    });

    test(
        'a non-offline PlatformException (e.g. a real plugin bug) is NOT '
        'offline', () {
      final e = PlatformException(
        code: 'PARSE_ERROR',
        message: 'malformed placemark payload',
      );
      expect(isOfflineError(e), isFalse);
    });

    test('a plain Exception is NOT offline', () {
      expect(isOfflineError(Exception('parse failed')), isFalse);
    });
  });

  group('isTransientUpstreamError — retry-later statuses only (#3395)', () {
    DioException badResponse(int code) => DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badResponse,
          response: Response(
              requestOptions: RequestOptions(path: '/'), statusCode: code),
        );

    test('502 / 503 / 504 (gateway/unavailable) are transient', () {
      for (final code in [502, 503, 504]) {
        expect(isTransientUpstreamError(badResponse(code)), isTrue,
            reason: '$code is an infra/proxy transient');
      }
    });

    test('429 (rate limited) is transient', () {
      expect(isTransientUpstreamError(badResponse(429)), isTrue);
    });

    test('connect/send/receive timeouts are transient (upstream too slow)', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          isTransientUpstreamError(
              DioException(requestOptions: RequestOptions(path: '/'), type: t)),
          isTrue,
        );
      }
    });

    test('500 is NOT transient — it can mean our request broke the server', () {
      expect(isTransientUpstreamError(badResponse(500)), isFalse);
    });

    test('4xx are NOT transient — a malformed/forbidden request is a real bug',
        () {
      for (final code in [400, 401, 403, 404, 422]) {
        expect(isTransientUpstreamError(badResponse(code)), isFalse,
            reason: '$code is a request-shape problem, not retry-later');
      }
    });

    test('a non-Dio error is never transient-upstream', () {
      expect(isTransientUpstreamError(Exception('boom')), isFalse);
      expect(isTransientUpstreamError(const SocketException('x')), isFalse);
    });
  });
}
