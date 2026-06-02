// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// #2703 — a single corridor country's feed failing in a multi-country route
// where the overall search still returns results is RECOVERABLE: the chain
// already retries transient faults and the other legs still resolve. It must
// NOT spam a top-level ERROR trace for every failed leg (the 5 UK-feed ERRORs
// from the southern-France field log). The catch in `buildCorridorQueryFunction`
// now records a diagnostic BreadcrumbCollector breadcrumb and drops the
// `errorLogger.log(ErrorLayer.services, …)` ERROR call.
//
// Reuse-fidelity: drives the REAL `buildCorridorQueryFunction` with a real
// throwing StationService for one country + a real returning one for the other,
// and asserts (a) the merged result is non-empty (the good leg survives) and
// (b) NO trace reached the TraceRecorder (no ERROR for the failed leg), while a
// breadcrumb WAS recorded. RED on master (the failed leg logged an ERROR).

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/telemetry/upload/trace_uploader.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/route_search/data/cross_border_corridor.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// A country service that always throws — the flaky UK feed.
class _ThrowingStationService implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    throw const SocketException('Failed host lookup: api2.krlmedia.com');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// A country service that returns one station at the queried point.
class _OkStationService implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final station = Station(
      id: 'fr-${params.lat.toStringAsFixed(2)}-${params.lng.toStringAsFixed(2)}',
      name: 'Total',
      brand: 'Total',
      street: 'Route',
      postCode: '34120',
      place: 'Pézenas',
      lat: params.lat,
      lng: params.lng,
      isOpen: true,
      e10: 1.60,
    );
    return ServiceResult(
      data: [station],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Captures every trace the recorder is asked to store.
class _CapturingTraceStorage extends TraceStorage {
  final stored = <ErrorTrace>[];

  @override
  Future<void> store(ErrorTrace trace) async => stored.add(trace);

  @override
  List<ErrorTrace> getAll() => stored;

  @override
  ErrorTrace? getById(String id) =>
      stored.where((t) => t.id == id).firstOrNull;
}

class _NoopUploader extends TraceUploader {
  _NoopUploader() : super(_NoopSettings());
  @override
  Future<void> uploadIfEnabled(ErrorTrace trace) async {}
}

class _NoopSettings implements SettingsStorage {
  @override
  dynamic getSetting(String key) => null;
  @override
  Future<void> putSetting(String key, dynamic value) async {}
  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CapturingTraceStorage traceStorage;
  late ProviderContainer container;

  setUp(() {
    // The recorder reads connectivity upfront (#2703) — mock it online so the
    // gate's behaviour is irrelevant here (a thrown leg never reaches it).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => call.method == 'check' ? <String>['wifi'] : null,
    );

    traceStorage = _CapturingTraceStorage();
    container = ProviderContainer();

    late Ref capturedRef;
    final refCapture = Provider<int>((ref) {
      capturedRef = ref;
      return 0;
    });
    container.read(refCapture);

    // Route the singleton errorLogger through a real TraceRecorder backed by
    // the capturing storage, so any ERROR.log lands where we can assert.
    errorLogger.testRecorderOverride =
        TraceRecorder(traceStorage, _NoopUploader(), capturedRef);
    BreadcrumbCollector.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
    errorLogger.resetForTest();
    BreadcrumbCollector.clear();
    container.dispose();
  });

  test(
      'a corridor leg that throws is a breadcrumb, not an ERROR — the other '
      'leg still returns results (#2703)', () async {
    late Ref capturedRef;
    final refCapture = Provider<int>((ref) {
      capturedRef = ref;
      return 0;
    });
    container.read(refCapture);

    final queryFn = buildCorridorQueryFunction(
      capturedRef,
      FuelType.e10,
      corridorMap: <String, CountrySource>{
        // The flaky UK feed — throws on every query.
        'GB': (service: _ThrowingStationService(), fuel: FuelType.e10),
        // The healthy FR feed — returns a station.
        'FR': (service: _OkStationService(), fuel: FuelType.e10),
      },
      criterion: RouteSearchCriterion.cheapest,
      topNPerSamplePoint: 10,
    );

    final result = await queryFn(
      lat: 43.44,
      lng: 3.44,
      radiusKm: 15,
      fuelType: FuelType.e10,
    );

    // The good FR leg survives — the route is not aborted by the GB outage.
    expect(result.whereType<FuelStationResult>(), isNotEmpty,
        reason: 'the healthy FR leg must still return its station');

    // Let any fire-and-forget error log settle, then assert NONE was raised.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(traceStorage.stored, isEmpty,
        reason: 'a recoverable per-leg failure must NOT persist an ERROR '
            'trace (the UK-feed ERROR spam, #2703)');

    // …but the failure is still DIAGNOSABLE via a breadcrumb.
    final crumbs = BreadcrumbCollector.snapshot();
    expect(
      crumbs.any((c) => c.action.contains('per-country station query failed')),
      isTrue,
      reason: 'a chronically-failing feed must leave a breadcrumb',
    );
    expect(
      crumbs.any((c) => (c.detail ?? '').contains('country=GB')),
      isTrue,
      reason: 'the breadcrumb names the failing country',
    );
  });
}
