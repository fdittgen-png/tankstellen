// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/impl/nominatim_geocoding_provider.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #2745 — error-log #14 traces #8/#9: `NominatimGeocodingProvider`'s reverse
/// geocoding + country detection ERROR-logged a `DioException` host-lookup
/// failure to nominatim.openstreetmap.org while the device was offline. Both
/// methods already fall back (to "lat, lng" / the next provider), so the trace
/// must be a breadcrumb, NOT an ERROR. Guard: a genuine 5xx still ERROR-logs.

class _CapturingRecorder implements TraceRecorder {
  final calls = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.error);
  final DioException Function(RequestOptions o) error;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    throw error(options);
  }

  @override
  void close({bool force = false}) {}
}

NominatimGeocodingProvider _providerThrowing(
    DioException Function(RequestOptions o) error) {
  final dio = Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'));
  dio.httpClientAdapter = _ThrowingAdapter(error);
  return NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
}

DioException _offlineHostLookup(RequestOptions o) => DioException(
      requestOptions: o,
      type: DioExceptionType.connectionError,
      error: const SocketException(
          'Failed host lookup: nominatim.openstreetmap.org'),
    );

DioException _genuine5xx(RequestOptions o) => DioException(
      requestOptions: o,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: o, statusCode: 503),
    );

void main() {
  late _CapturingRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    BreadcrumbCollector.clear();
  });

  tearDown(errorLogger.resetForTest);

  group('Nominatim offline de-noise (#2745)', () {
    test(
        'coordinatesToAddress offline host-lookup is a breadcrumb, NOT ERROR '
        '(trace #8)', () async {
      final provider = _providerThrowing(_offlineHostLookup);
      final result = await provider.coordinatesToAddress(48.85, 2.35);

      expect(result, '48.85, 2.35', reason: 'falls back to lat, lng');
      expect(recorder.calls, isEmpty,
          reason: 'an offline host-lookup must NOT ERROR-log');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('Nominatim reverse geocoding skipped — offline'),
      );
    });

    test(
        'coordinatesToCountryCode offline host-lookup is a breadcrumb, NOT '
        'ERROR (trace #9)', () async {
      final provider = _providerThrowing(_offlineHostLookup);
      final code = await provider.coordinatesToCountryCode(48.85, 2.35);

      expect(code, isNull, reason: 'falls back to the next provider');
      expect(recorder.calls, isEmpty);
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('Nominatim country detection skipped — offline'),
      );
    });

    test('coordinatesToAddress GENUINE 5xx STILL ERROR-logs (the guard)',
        () async {
      final provider = _providerThrowing(_genuine5xx);
      final result = await provider.coordinatesToAddress(48.85, 2.35);

      expect(result, '48.85, 2.35');
      expect(recorder.calls, hasLength(1),
          reason: 'a real 5xx must persist as an ERROR trace');
      expect(recorder.calls.single.toString(),
          contains('Nominatim reverse geocoding failed'));
    });

    test('coordinatesToCountryCode GENUINE 5xx STILL ERROR-logs (the guard)',
        () async {
      final provider = _providerThrowing(_genuine5xx);
      await provider.coordinatesToCountryCode(48.85, 2.35);

      expect(recorder.calls, hasLength(1));
      expect(recorder.calls.single.toString(),
          contains('Nominatim country detection failed'));
    });
  });
}
