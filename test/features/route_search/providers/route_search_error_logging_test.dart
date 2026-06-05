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
/// injectable, but the notifier rejects fewer than 2 usable waypoints
/// SYNCHRONOUSLY (before any network call) — the #2872 degenerate-origin
/// guard throws a `LocationException` (an `AppException`) that lands in the
/// `on AppException` outer catch. That gives a deterministic, network-free
/// way to exercise the breadcrumb.
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

    // A single waypoint leaves < 2 usable waypoints, which the #2872 guard
    // rejects with a LocationException (an AppException) synchronously,
    // before any OSRM call.
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
    expect(ctx.inner, isA<LocationException>());
  });

  // #2872 — a degenerate origin ((0,0) / a one-axis-unacquired (lat,0))
  // must be rejected BEFORE the OSRM fetch so the route never starts from
  // the Gulf of Guinea and the route map can't centre in the Sahara. With
  // only one usable waypoint left, the guard throws a LocationException
  // (NOT a network/ApiException) — i.e. it asks for a manual start rather
  // than routing through null island.
  test(
      'searchAlongRoute rejects a degenerate origin before OSRM with a '
      'LocationException (#2872)', () async {
    final container = ProviderContainer(
      overrides: [
        activeProfileProvider.overrideWith(_NullActiveProfile.new),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);

    // A (0,0) origin paired with a real Catalonia destination: exactly the
    // real-report shape. The origin is dropped, leaving < 2 usable
    // waypoints, so no OSRM request is ever built.
    await notifier.searchAlongRoute(
      waypoints: const [
        RouteWaypoint(lat: 0, lng: 0, label: 'GPS'),
        RouteWaypoint(lat: 42.43, lng: 2.86, label: 'Catalonia'),
      ],
      fuelType: FuelType.e10,
    );

    final state = container.read(routeSearchStateProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<LocationException>(),
        reason: 'a degenerate origin must be rejected as a location error, '
            'not reach OSRM and fail as a network/ApiException');
  });

  test(
      'searchAlongRoute also rejects a one-axis-unacquired (lat,0) origin '
      'before OSRM (#2872)', () async {
    final container = ProviderContainer(
      overrides: [
        activeProfileProvider.overrideWith(_NullActiveProfile.new),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(routeSearchStateProvider.notifier);

    await notifier.searchAlongRoute(
      waypoints: const [
        RouteWaypoint(lat: 42.7, lng: 0, label: 'GPS'),
        RouteWaypoint(lat: 42.43, lng: 2.86, label: 'Catalonia'),
      ],
      fuelType: FuelType.e10,
    );

    final state = container.read(routeSearchStateProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<LocationException>());
  });
}
