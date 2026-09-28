// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/core/utils/route_progress.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_live_progress_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';

/// #4432 — the foreground listener while current-location route results
/// are on screen: accepted fixes retire passed stops and detect leaving
/// the route, without a routing request per fix, and the platform stream
/// is held only while the surface is.
class _FixedRouteSearch extends RouteSearchState {
  _FixedRouteSearch(this.result);
  final RouteSearchResult? result;
  int refreshes = 0;

  @override
  AsyncValue<RouteSearchResult?> build() => AsyncValue.data(result);

  @override
  Future<bool> refresh() async {
    refreshes++;
    return true;
  }
}

class _FakeGeolocator implements GeolocatorWrapper {
  int listens = 0;
  int cancels = 0;
  final List<bool> recordingFlags = [];
  // Closed by the test's tearDown (see `make`).
  // ignore: close_sinks
  late final StreamController<Position> controller =
      StreamController<Position>.broadcast(
    onListen: () => listens++,
    onCancel: () => cancels++,
  );

  @override
  Stream<Position> sharedPositionStream({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
    recordingFlags.add(recording);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 9, 20, 14);

  /// East to lng 2.6, north, west, then south THROUGH the first leg at
  /// (48.0, 2.3) — first met at ~22.3 km, again at ~111.4 km.
  const geometry = [
    LatLng(48.0, 2.0),
    LatLng(48.0, 2.6),
    LatLng(48.2, 2.6),
    LatLng(48.2, 2.3),
    LatLng(47.8, 2.3),
  ];

  RouteSearchResult route({required bool fromVehicle}) => RouteSearchResult(
        route: const RouteInfo(
          geometry: geometry,
          distanceKm: 134,
          durationMinutes: 100,
          samplePoints: geometry,
        ),
        stations: const [],
        request: RouteSearchRequest(
          revision: 7,
          waypoints: [
            RouteWaypoint(
              lat: 48.0,
              lng: 2.0,
              label: 'Current location',
              isVehiclePosition: fromVehicle,
            ),
            const RouteWaypoint(lat: 47.8, lng: 2.3, label: 'Dest'),
          ],
          fuelType: FuelType.e10,
          searchRadiusKm: 5,
          strategyType: RouteSearchStrategyType.uniform,
          originCapturedAt: now,
        ),
      );

  Position fix(double lat, double lng, {DateTime? at, double accuracy = 8}) =>
      Position(
        latitude: lat,
        longitude: lng,
        timestamp: at ?? now,
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 25,
        speedAccuracy: 0,
      );

  late _FakeGeolocator geo;
  late _FixedRouteSearch search;

  ProviderContainer make(RouteSearchResult result) {
    geo = _FakeGeolocator();
    addTearDown(geo.controller.close);
    search = _FixedRouteSearch(result);
    final c = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      routeSearchStateProvider.overrideWith(() => search),
      appClockProvider.overrideWithValue(FixedClock(now)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Future<RouteLiveProgress> feed(
    ProviderContainer c,
    List<Position> fixes,
  ) async {
    for (final f in fixes) {
      geo.controller.add(f);
      await Future<void>.delayed(Duration.zero);
    }
    return c.read(routeLiveProgressControllerProvider);
  }

  test('a named-origin route holds no listener at all', () {
    final c = make(route(fromVehicle: false));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    addTearDown(sub.close);

    expect(sub.read().isActive, isFalse);
    expect(geo.listens, 0);
  });

  test(
      'a current-location route listens as a NON-recording consumer and '
      'retires a passed stop while keeping one the route meets again',
      () async {
    final c = make(route(fromVehicle: true));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    addTearDown(sub.close);
    expect(geo.listens, 1);
    expect(geo.recordingFlags, [false]);

    final progress = await feed(c, [
      fix(48.0, 2.1),
      fix(48.0, 2.2),
      fix(48.0, 2.32), // just past the crossing on the first pass
    ]);
    expect(progress.status, RouteProgressStatus.onRoute);
    expect(progress.fix, const LatLng(48.0, 2.32));

    final result = route(fromVehicle: true);
    final kept = aheadOfDriver(result, progress, const [
      ('passed', 48.0, 2.1),
      ('crossing', 48.0, 2.3), // met again on the southbound leg
      ('ahead', 48.1, 2.6),
    ], (s) => (lat: s.$2, lng: s.$3));
    expect(kept.map((s) => s.$1), ['crossing', 'ahead']);
    expect(search.refreshes, 0, reason: 'no routing request per GPS fix');
  });

  test('a stale replayed fix moves nothing', () async {
    final c = make(route(fromVehicle: true));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final progress = await feed(c, [
      fix(48.0, 2.5, at: now.subtract(const Duration(minutes: 10))),
    ]);
    expect(progress.status, RouteProgressStatus.unknown);
    expect(progress.retiredBeforeKm, 0);
    expect(progress.fix, isNull);
  });

  test(
      'leaving the route asks for an update — and still fires no routing '
      'request by itself', () async {
    final c = make(route(fromVehicle: true));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final progress = await feed(c, [
      fix(48.0, 2.1),
      fix(48.03, 2.12),
      fix(48.04, 2.13),
    ]);
    expect(progress.needsRouteUpdate, isTrue);
    expect(search.refreshes, 0);
  });

  test('pause releases the platform stream; resume re-joins it', () async {
    final c = make(route(fromVehicle: true));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = c.read(routeLiveProgressControllerProvider.notifier);

    controller.pause();
    await Future<void>.delayed(Duration.zero);
    expect(controller.isListening, isFalse);
    expect(geo.cancels, 1);

    controller.resume();
    expect(controller.isListening, isTrue);
    expect(geo.listens, 2);
  });

  test('leaving the route surface disposes the listener', () async {
    final c = make(route(fromVehicle: true));
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});
    expect(geo.listens, 1);

    sub.close();
    await pumpEventQueue();
    expect(geo.cancels, 1);
  });

  test(
      'accepted progress is mirrored to the snapshot, which outlives the '
      'listener without holding it open', () async {
    final c = make(route(fromVehicle: true));
    // A non-owning consumer (the planner) watches only the snapshot.
    final snap = c.listen(routeProgressSnapshotProvider, (_, _) {});
    addTearDown(snap.close);
    final sub = c.listen(routeLiveProgressControllerProvider, (_, _) {});

    final progress = await feed(c, [
      fix(48.0, 2.1),
      fix(48.0, 2.2),
      fix(48.0, 2.32),
    ]);
    expect(progress.retiredBeforeKm, greaterThan(0));
    expect(snap.read().retiredBeforeKm, progress.retiredBeforeKm);
    expect(snap.read().revision, 7);

    // The surface goes away: the platform stream is released even though
    // the snapshot is still watched, and the retirement it recorded is
    // still there for the planner.
    sub.close();
    await pumpEventQueue();
    expect(geo.cancels, 1);
    expect(snap.read().retiredBeforeKm, progress.retiredBeforeKm);
  });

  test('passedStationIds names exactly the retired stops of THIS route', () {
    final result = RouteSearchResult(
      route: route(fromVehicle: true).route,
      stations: [
        FuelStationResult(_station('passed', 48.0, 2.1)),
        FuelStationResult(_station('crossing', 48.0, 2.3)),
        FuelStationResult(_station('ahead', 48.1, 2.6)),
      ],
      request: route(fromVehicle: true).request,
    );
    // Just past the crossing on the first pass (~22.3 km).
    const progress = RouteLiveProgress(
      revision: 7,
      status: RouteProgressStatus.onRoute,
      retiredBeforeKm: 20,
    );
    expect(passedStationIds(result, progress), {'passed'});
    // Another route's progress retires nothing on this one.
    const other = RouteLiveProgress(
      revision: 8,
      status: RouteProgressStatus.onRoute,
      retiredBeforeKm: 20,
    );
    expect(passedStationIds(result, other), isEmpty);
    expect(passedStationIds(result, RouteLiveProgress.inactive), isEmpty);
  });

  test('currentFix goes stale with the route-origin freshness bound', () {
    final p = RouteLiveProgress(
      revision: 1,
      fix: const LatLng(48, 2),
      fixAt: now,
    );
    expect(p.currentFix(now.add(const Duration(seconds: 60))),
        const LatLng(48, 2));
    expect(p.currentFix(now.add(const Duration(minutes: 5))), isNull);
  });
}

Station _station(String id, double lat, double lng) => Station(
      id: id,
      name: id,
      brand: 'B',
      street: 'R',
      postCode: '1',
      place: 'P',
      lat: lat,
      lng: lng,
      e10: 1.8,
    );
