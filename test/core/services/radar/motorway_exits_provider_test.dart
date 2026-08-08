// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/radar/motorway_exits_provider.dart';
import 'package:tankstellen/core/services/radar/motorway_exits_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3633 — [MotorwayExits.ensureLoaded] is fire-and-forget by contract:
/// a failing service must never throw into the caller (the radar's
/// poll loop) and the state stays the empty v1 list. Fault-injected per
/// the never-throws contract (#2349).
class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? body,
          Future<void>? cancelFuture) =>
      throw DioException.connectionError(
          requestOptions: options, reason: 'offline');

  @override
  void close({bool force = false}) {}
}

void main() {
  silenceErrorLoggerSpool();

  test('ensureLoaded with a failing service returns normally and leaves '
      'the empty v1 state', () async {
    final container = ProviderContainer(overrides: [
      motorwayExitsServiceProvider.overrideWithValue(
        MotorwayExitsService(dio: Dio()..httpClientAdapter = _OfflineAdapter()),
      ),
    ]);
    addTearDown(container.dispose);

    expect(
      () => container.read(motorwayExitsProvider.notifier).ensureLoaded('FR'),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(motorwayExitsProvider), isEmpty);
  });

  test('the annotation side-channel publishes and clears', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(highwayExitInfoMapProvider.notifier);
    expect(container.read(highwayExitInfoMapProvider), isEmpty);
    notifier.clear(); // idempotent on empty
    expect(container.read(highwayExitInfoMapProvider), isEmpty);
  });
}
