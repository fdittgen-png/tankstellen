// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/radar/motorway_exits_service.dart';
import 'package:tankstellen/core/services/service_result.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3633 — [MotorwayExitsService.exitsFor] never throws: any failure
/// (network down, hostile body) degrades to the last-known copy or an
/// empty list, so highway mode falls back to exit-less v1. Fault-
/// injected per the never-throws contract (#2349).
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body,
          Future<void>? cancelFuture) =>
      throw DioException.connectionError(
          requestOptions: options, reason: 'offline');

  @override
  void close({bool force = false}) {}
}

class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<void> put(String key, Map<String, dynamic> data,
      {required Duration ttl, required ServiceSource source}) async {
    _store[key] = CacheEntry(
        payload: data,
        // #3660 — pinned instant, not the wall clock.
        storedAt: DateTime(2026, 3, 11, 14, 30),
        originalSource: source,
        ttl: ttl);
  }

  @override
  CacheEntry? get(String key) => _store[key];

  @override
  CacheEntry? getFresh(String key) => _store[key];
}

void main() {
  silenceErrorLoggerSpool();

  test('a dead network completes with an empty list — never throws', () async {
    final dio = Dio()..httpClientAdapter = _ThrowingAdapter();
    final service = MotorwayExitsService(dio: dio, cache: _MemCache());

    await expectLater(service.exitsFor('FR'), completes);
    expect(await service.exitsFor('FR'), isEmpty,
        reason: 'no copy anywhere → the exit-less v1 degradation');
  });

  test('no cache wired (isolated harness) still completes', () async {
    final dio = Dio()..httpClientAdapter = _ThrowingAdapter();
    final service = MotorwayExitsService(dio: dio);
    await expectLater(service.exitsFor('DE'), completes);
  });
}
