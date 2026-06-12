// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'network_retry.dart';

/// Regression tests for the nightly-network retry helper (#3096), extended
/// for the #3115/#3222 TLS-trust hardening (Denmark OK rotated onto the new
/// ISRG Root YR hierarchy and the runner's stale CA bundle failed the
/// handshake every night). No `network` tag — everything here is offline.
void main() {
  group('networkTestSecurityContext (#3115/#3222)', () {
    test('embedded ISRG Root YR PEM parses into a SecurityContext', () {
      // setTrustedCertificatesBytes throws a TlsException on a corrupt /
      // truncated PEM, so this guards the embedded certificate bytes.
      expect(networkTestSecurityContext, returnsNormally);
    });
  });

  group('transient-error classification (#3096, #3115/#3222)', () {
    DioException handshakeFailure() => DioException(
          requestOptions: RequestOptions(path: '/probe'),
          error: const HandshakeException(
            'Handshake error in client (CERTIFICATE_VERIFY_FAILED)',
          ),
        );

    test('a TLS handshake blip is retried and can self-heal', () async {
      var calls = 0;
      final result = await retryNetwork<int>(
        () async {
          calls++;
          if (calls < 2) throw handshakeFailure();
          return 42;
        },
        baseDelay: Duration.zero,
      );
      expect(result, 42);
      expect(calls, 2);
    });

    test('a PERSISTENT handshake failure still fails after bounded retries',
        () async {
      var calls = 0;
      await expectLater(
        retryNetwork<int>(
          () async {
            calls++;
            throw handshakeFailure();
          },
          attempts: 3,
          baseDelay: Duration.zero,
        ),
        throwsA(isA<DioException>()),
      );
      expect(calls, 3);
    });

    test('a non-transient 4xx is NOT retried (contract break fails fast)',
        () async {
      var calls = 0;
      await expectLater(
        retryNetwork<int>(
          () async {
            calls++;
            throw DioException(
              requestOptions: RequestOptions(path: '/probe'),
              type: DioExceptionType.badResponse,
              response: Response<void>(
                requestOptions: RequestOptions(path: '/probe'),
                statusCode: 404,
              ),
            );
          },
          baseDelay: Duration.zero,
        ),
        throwsA(isA<DioException>()),
      );
      expect(calls, 1);
    });

    test('a real assertion (TestFailure) is never retried', () async {
      var calls = 0;
      await expectLater(
        retryNetwork<int>(
          () async {
            calls++;
            fail('upstream contract changed');
          },
          baseDelay: Duration.zero,
        ),
        throwsA(isA<TestFailure>()),
      );
      expect(calls, 1);
    });
  });
}
