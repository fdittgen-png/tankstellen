// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_station_service.dart';

/// #2745 — error-log #14 trace #1: `PrixCarburantsStationService._queryByGeo`
/// ERROR-logged a `DioException` carrying an `HttpException('Software caused
/// connection abort')` from data.economie.gouv.fr while the device was
/// offline. The geo query already swallows offline failures (returns []), so
/// the trace must be a breadcrumb, NOT an ERROR. Guard: a genuine API error
/// (5xx) still ERROR-logs.

/// Captures every `errorLogger.log` -> `record` call so a test can assert an
/// offline failure was NOT ERROR-logged while a genuine one was.
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

/// A Dio adapter that throws a per-test [DioException] on every fetch.
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

PrixCarburantsStationService _serviceThrowing(
    DioException Function(RequestOptions o) error) {
  final dio = Dio(BaseOptions(baseUrl: 'https://data.economie.gouv.fr'));
  dio.httpClientAdapter = _ThrowingAdapter(error);
  return PrixCarburantsStationService(dio: dio);
}

const _geoParams = SearchParams(lat: 43.45, lng: 3.42, radiusKm: 5);

void main() {
  late _CapturingRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    BreadcrumbCollector.clear();
  });

  tearDown(errorLogger.resetForTest);

  group('PrixCarburants geo offline de-noise (#2745)', () {
    test(
        'a DioException[unknown] wrapping an HttpException connection-abort '
        '(field trace #1) is a breadcrumb, NOT an ERROR', () async {
      final svc = _serviceThrowing((o) => DioException(
            requestOptions: o,
            type: DioExceptionType.unknown,
            error: const HttpException('Software caused connection abort'),
          ));

      final result = await svc.searchStations(_geoParams);

      expect(result.data, isEmpty, reason: 'offline failure swallowed');
      expect(recorder.calls, isEmpty,
          reason: 'an offline connection-abort must NOT ERROR-log (#2745)');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('Prix-Carburants geo fetch skipped — offline'),
      );
    });

    test('a connectionError wrapping a host-lookup is a breadcrumb, NOT ERROR',
        () async {
      final svc = _serviceThrowing((o) => DioException(
            requestOptions: o,
            type: DioExceptionType.connectionError,
            error: const SocketException(
                'Failed host lookup: data.economie.gouv.fr'),
          ));

      await svc.searchStations(_geoParams);

      expect(recorder.calls, isEmpty);
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('Prix-Carburants geo fetch skipped — offline'),
      );
    });

    test(
        'a transient UPSTREAM 502 (field: gov gateway 50x in 7 min) is a '
        'breadcrumb, NOT an ERROR (#3395)', () async {
      final svc = _serviceThrowing((o) => DioException(
            requestOptions: o,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: o, statusCode: 502),
          ));

      final result = await svc.searchStations(_geoParams);

      expect(result.data, isEmpty, reason: 'transient blip degrades to empty');
      expect(recorder.calls, isEmpty,
          reason: 'a transient gateway 502/503/504 must NOT spool an ERROR '
              'trace (#3395) — it buries real faults');
      expect(
        BreadcrumbCollector.snapshot().map((b) => b.action),
        contains('Prix-Carburants geo fetch — transient upstream error'),
      );
    });

    test('503 and 504 are also transient-upstream breadcrumbs (#3395)',
        () async {
      for (final code in [503, 504]) {
        errorLogger.resetForTest();
        recorder = _CapturingRecorder();
        errorLogger.testRecorderOverride = recorder;
        final svc = _serviceThrowing((o) => DioException(
              requestOptions: o,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: o, statusCode: code),
            ));
        await svc.searchStations(_geoParams);
        expect(recorder.calls, isEmpty, reason: '$code must breadcrumb');
      }
    });

    test(
        'a GENUINE server error (500) or 4xx STILL ERROR-logs — only transient '
        'gateway statuses are de-noised (#3395 guard)', () async {
      // 500 can mean OUR request broke the server — keep it loud.
      final svc = _serviceThrowing((o) => DioException(
            requestOptions: o,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: o, statusCode: 500),
          ));

      await svc.searchStations(_geoParams);

      expect(recorder.calls, hasLength(1),
          reason: 'a 500 is a genuine failure and must persist as a trace');
      expect(recorder.calls.single.toString(),
          contains('Prix-Carburants geo fetch failed'));
    });
  });
}
