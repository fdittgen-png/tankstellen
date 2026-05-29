// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/failure_kind.dart';

DioException _dio(
  DioExceptionType type, {
  int? statusCode,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('failureKindFromDio (#2255)', () {
    test('connectionTimeout / sendTimeout / receiveTimeout → timeout', () {
      expect(failureKindFromDio(_dio(DioExceptionType.connectionTimeout)),
          FailureKind.timeout);
      expect(failureKindFromDio(_dio(DioExceptionType.sendTimeout)),
          FailureKind.timeout);
      expect(failureKindFromDio(_dio(DioExceptionType.receiveTimeout)),
          FailureKind.timeout);
    });

    test('connectionError → network', () {
      expect(failureKindFromDio(_dio(DioExceptionType.connectionError)),
          FailureKind.network);
    });

    test('badResponse 429 → rateLimited', () {
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 429)),
        FailureKind.rateLimited,
      );
    });

    test('badResponse 401/403 → auth', () {
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 401)),
        FailureKind.auth,
      );
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 403)),
        FailureKind.auth,
      );
    });

    test('badResponse 404 → notFound', () {
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 404)),
        FailureKind.notFound,
      );
    });

    test('badResponse 5xx → network (preserves the old transient-5xx rule)',
        () {
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 503)),
        FailureKind.network,
      );
    });

    test('badResponse other 4xx → unknown', () {
      expect(
        failureKindFromDio(
            _dio(DioExceptionType.badResponse, statusCode: 400)),
        FailureKind.unknown,
      );
    });

    test('cancel / badCertificate / unknown → unknown', () {
      expect(failureKindFromDio(_dio(DioExceptionType.cancel)),
          FailureKind.unknown);
      expect(failureKindFromDio(_dio(DioExceptionType.badCertificate)),
          FailureKind.unknown);
      expect(failureKindFromDio(_dio(DioExceptionType.unknown)),
          FailureKind.unknown);
    });
  });

  group('failureKindFromStatus', () {
    test('maps representative codes', () {
      expect(failureKindFromStatus(429), FailureKind.rateLimited);
      expect(failureKindFromStatus(401), FailureKind.auth);
      expect(failureKindFromStatus(403), FailureKind.auth);
      expect(failureKindFromStatus(404), FailureKind.notFound);
      expect(failureKindFromStatus(500), FailureKind.network);
      expect(failureKindFromStatus(599), FailureKind.network);
      expect(failureKindFromStatus(418), FailureKind.unknown);
      expect(failureKindFromStatus(null), FailureKind.unknown);
    });
  });
}
