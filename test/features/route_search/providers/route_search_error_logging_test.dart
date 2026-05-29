// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #2308 — the three outer catch clauses of `searchAlongRoute` must emit
/// an `errorLogger` breadcrumb (so an OSRM outage / country-service
/// exhaustion / Dart error is distinguishable in exportable logs), not
/// only write `AsyncValue.error`.
///
/// The OSRM `RoutingService` is constructed internally and not
/// injectable, but `getRoute` throws `ApiException` SYNCHRONOUSLY (before
/// any network call) when fewer than 2 waypoints are supplied — which
/// lands in the `on AppException` outer catch. That gives a deterministic,
/// network-free way to exercise the breadcrumb.
class _FakeTraceRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Test override for [ActiveProfile] that returns no profile without
/// touching Hive / the real [ProfileRepository].
class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

void main() {
  late _FakeTraceRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _FakeTraceRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(errorLogger.resetForTest);

  test(
      'searchAlongRoute outer catch logs an errorLogger breadcrumb and sets '
      'AsyncValue.error', () async {
    final container = ProviderContainer(
      overrides: [
        // No active profile → the notifier uses its defaults; the
        // sub-2-waypoint guard fires before any profile-dependent path.
        activeProfileProvider.overrideWith(_NullActiveProfile.new),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);

    // A single waypoint trips `getRoute`'s `waypoints.length < 2` guard,
    // which throws ApiException (an AppException) synchronously.
    await notifier.searchAlongRoute(
      waypoints: const [
        RouteWaypoint(lat: 52.52, lng: 13.41, label: 'Berlin'),
      ],
      fuelType: FuelType.e10,
    );

    // State surfaced the error to the UI.
    expect(container.read(routeSearchStateProvider).hasError, isTrue);

    // #2308 — and a breadcrumb was logged. The error is wrapped in a
    // ContextualError carrying the call-site `where`.
    expect(recorder.calls, hasLength(1));
    final logged = recorder.calls.single;
    expect(logged, isA<ContextualError>());
    final ctx = (logged as ContextualError);
    expect(ctx.layer, ErrorLayer.providers);
    expect(ctx.context, contains('where'));
    expect(ctx.context!['where'], 'RouteSearchState.searchAlongRoute');
    expect(ctx.inner, isA<ApiException>());
  });
}
