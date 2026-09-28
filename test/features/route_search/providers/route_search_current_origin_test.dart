// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/providers/route_fetcher_provider.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';

/// #4432 — the reported scenario, end to end through the PRODUCTION
/// route search: submission, origin re-resolution on refresh, the route
/// fetch, the corridor sweep, the detour filter and the best stops.
///
/// The driver's GPS was read near La Tour-du-Pin (A); the vehicle is now
/// at Belley (B), ~30 km on; the destination is Geneva (C). Until
/// `routeFetcherProvider` existed the route fetch was constructed inline,
/// so this path could only be tested around the fetch — the widget test
/// pinned what the input HANDED OVER and the corridor test pinned what
/// the filter DID with a given polyline, but nothing pinned that the
/// origin actually routed, drawn and published was B.
class _MockLocationService extends Mock implements LocationService {}

/// A clock the test advances by hand.
class _StepClock implements AppClock {
  _StepClock(this.instant);
  DateTime instant;
  @override
  DateTime now() => instant;
}

class _NoKeyStorage implements StorageRepository {
  @override
  bool hasApiKey(String countryCode) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

/// A French source that knows three forecourts along the A→C road and
/// returns all of them for every query, as a radius search that reaches
/// them would. Which ones SURVIVE is then entirely the corridor's doing.
class _CorridorStations implements StationService {
  _CorridorStations(this.stations);
  final List<Station> stations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult(
        data: stations,
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 9, 20),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Position _fix(LatLng at, DateTime measured) => Position(
      latitude: at.latitude,
      longitude: at.longitude,
      timestamp: measured,
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  const a = LatLng(45.5636, 5.4456); // La Tour-du-Pin — the stale snapshot
  const b = LatLng(45.7594, 5.6842); // Belley — where the vehicle is now
  const c = LatLng(46.2044, 6.1432); // Geneva

  /// The road from wherever the route starts, through Culoz and Seyssel,
  /// to Geneva — what a router would draw from A or from B.
  const onward = <LatLng>[
    LatLng(45.8470, 5.7830), // Culoz
    LatLng(45.9570, 5.8330), // Seyssel
    LatLng(46.1200, 6.0100),
    c,
  ];

  Station forecourt(String id, LatLng at, double e85) => Station(
        id: id,
        name: id,
        brand: id,
        street: '',
        postCode: '',
        place: id,
        lat: at.latitude,
        lng: at.longitude,
        e85: e85,
        isOpen: true,
      );

  // The cheapest one is the one already passed: if it survives, it is
  // also the "best stop" the driver is told to turn back for.
  final passed = forecourt('la-tour-du-pin', a, 0.799);
  final culoz = forecourt('culoz', onward[0], 0.849);
  final seyssel = forecourt('seyssel', onward[1], 0.839);

  late _MockLocationService location;
  late _StepClock clock;
  late List<List<RouteWaypoint>> routed;

  setUp(() {
    location = _MockLocationService();
    clock = _StepClock(DateTime(2026, 9, 20, 14));
    routed = [];
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      activeProfileProvider.overrideWith(_NullActiveProfile.new),
      storageRepositoryProvider.overrideWith((ref) => _NoKeyStorage()),
      allProfilesProvider.overrideWith((ref) => const [
            UserProfile(
              id: 'fr',
              name: 'Standard',
              countryCode: 'FR',
              preferredFuelType: FuelType.e85,
            ),
          ]),
      perCountryStationServiceProvider('FR').overrideWith(
          (ref) => _CorridorStations([passed, culoz, seyssel])),
      locationServiceProvider.overrideWithValue(location),
      appClockProvider.overrideWithValue(clock),
      // The router draws from whatever origin it is actually given.
      routeFetcherProvider.overrideWithValue((waypoints, _) async {
        routed.add(waypoints);
        final from = LatLng(waypoints.first.lat, waypoints.first.lng);
        final geometry = [from, ...onward];
        return RouteInfo(
          geometry: geometry,
          distanceKm: 100,
          durationMinutes: 70,
          samplePoints: geometry,
        );
      }),
    ]);
    addTearDown(container.dispose);
    // The provider is auto-dispose; hold it across the steps.
    addTearDown(container.listen(routeSearchStateProvider, (_, _) {}).close);
    return container;
  }

  /// The submission the criteria screen makes after the GPS button read
  /// A: a vehicle-position origin captured at [capturedAt].
  Future<void> searchFromA(ProviderContainer container, DateTime capturedAt) =>
      container.read(routeSearchStateProvider.notifier).searchAlongRoute(
        waypoints: [
          RouteWaypoint(
            lat: a.latitude,
            lng: a.longitude,
            label: 'Current location',
            isVehiclePosition: true,
          ),
          RouteWaypoint(lat: c.latitude, lng: c.longitude, label: 'Genève'),
        ],
        fuelType: FuelType.e85,
        searchRadiusKm: 15,
        originCapturedAt: capturedAt,
      );

  Set<String> ids(RouteSearchResult r) =>
      r.stations.whereType<FuelStationResult>().map((s) => s.id).toSet();

  Set<String> bestStops(RouteSearchResult r) =>
      {...?r.cheapestPerSegment?.values, ?r.cheapestId};

  test(
      'A → B → C: after the vehicle moved 30 km, refresh routes, draws and '
      'publishes from B, and the stop passed at A is no candidate', () async {
    final container = makeContainer();
    final notifier = container.read(routeSearchStateProvider.notifier);

    await searchFromA(container, clock.now());
    final fromA = container.read(routeSearchStateProvider).requireValue!;
    // The field report, reproduced: a corridor from A keeps the passed
    // forecourt, and being the cheapest it is even a "best stop".
    expect(ids(fromA), contains('la-tour-du-pin'));
    expect(bestStops(fromA), contains('la-tour-du-pin'));

    // The driver is now 30 km on, and GPS says so with a fresh fix.
    clock.instant = clock.instant.add(const Duration(minutes: 25));
    when(() => location.getCurrentPosition())
        .thenAnswer((_) async => _fix(b, clock.now()));

    expect(await notifier.refresh(), isTrue);
    final fromB = container.read(routeSearchStateProvider).requireValue!;

    // The request that went to the router started at B, still marked as
    // the vehicle's own position.
    final origin = routed.last.first;
    expect((origin.lat, origin.lng), (b.latitude, b.longitude));
    expect(origin.isVehiclePosition, isTrue);
    expect(routed.last.last.label, 'Genève', reason: 'destination unchanged');
    // The drawn route (and the maps launch, which starts at its first
    // vertex) begins at B.
    expect(fromB.route.geometry.first, b);
    // The published request says B, measured NOW — not the old capture.
    expect(fromB.request!.waypoints.first.lat, b.latitude);
    expect(fromB.request!.originCapturedAt, clock.now());
    expect(fromB.routeRevision, isNot(fromA.routeRevision));

    expect(ids(fromB), {'culoz', 'seyssel'});
    expect(bestStops(fromB), isNot(contains('la-tour-du-pin')));
    expect(bestStops(fromB), isNotEmpty);
  });

  test(
      'a search-time fix that is itself 25 min old cannot pass as current: '
      'the published request keeps the ORIGINAL capture time', () async {
    final container = makeContainer();
    final notifier = container.read(routeSearchStateProvider.notifier);
    final capturedAt = clock.now();

    await searchFromA(container, capturedAt);
    clock.instant = clock.instant.add(const Duration(minutes: 25));
    // The platform answers from its cache: A, measured back then.
    when(() => location.getCurrentPosition())
        .thenAnswer((_) async => _fix(a, capturedAt));

    await notifier.refresh();
    final result = container.read(routeSearchStateProvider).requireValue!;

    // Still routed from the stored point — but its age is not laundered
    // into "measured just now".
    expect(result.request!.originCapturedAt, capturedAt);
    expect(
      clock.now().difference(result.request!.originCapturedAt!),
      const Duration(minutes: 25),
    );
  });

  test('a named origin is fixed: refresh neither reads GPS nor moves it',
      () async {
    final container = makeContainer();
    final notifier = container.read(routeSearchStateProvider.notifier);

    await notifier.searchAlongRoute(
      waypoints: [
        RouteWaypoint(lat: a.latitude, lng: a.longitude, label: 'La Tour'),
        RouteWaypoint(lat: c.latitude, lng: c.longitude, label: 'Genève'),
      ],
      fuelType: FuelType.e85,
      searchRadiusKm: 15,
    );
    await notifier.refresh();

    verifyNever(() => location.getCurrentPosition());
    expect(routed, hasLength(2));
    expect(routed.last.first.lat, a.latitude);
  });

  test(
      'revisions never repeat across provider lifetimes, so two routes can '
      'not share road quotes keyed on them', () async {
    final first = makeContainer();
    await searchFromA(first, clock.now());
    final second = makeContainer();
    await searchFromA(second, clock.now());

    final r1 = first.read(routeSearchStateProvider).requireValue!;
    final r2 = second.read(routeSearchStateProvider).requireValue!;
    // Identical geometry, identical length — the old
    // `Object.hash(geometry.length, distanceKm)` key could not tell them
    // apart. The request revision can.
    expect(r1.route.geometry, r2.route.geometry);
    expect(r1.routeRevision, isNot(r2.routeRevision));
    expect(r1.routeRevision, greaterThan(0));
  });

  test(
      'a current-location DESTINATION (swapped in) is re-read on refresh; '
      'the named origin stays put', () async {
    final container = makeContainer();
    final notifier = container.read(routeSearchStateProvider.notifier);
    final capturedAt = clock.now();

    await notifier.searchAlongRoute(
      waypoints: [
        RouteWaypoint(lat: c.latitude, lng: c.longitude, label: 'Genève'),
        RouteWaypoint(
          lat: a.latitude,
          lng: a.longitude,
          label: 'Current location',
          isVehiclePosition: true,
        ),
      ],
      fuelType: FuelType.e85,
      searchRadiusKm: 15,
      originCapturedAt: capturedAt,
    );

    clock.instant = clock.instant.add(const Duration(minutes: 25));
    when(() => location.getCurrentPosition())
        .thenAnswer((_) async => _fix(b, clock.now()));
    await notifier.refresh();

    final sent = routed.last;
    expect((sent.first.lat, sent.first.lng), (c.latitude, c.longitude));
    expect(sent.first.isVehiclePosition, isFalse);
    expect((sent.last.lat, sent.last.lng), (b.latitude, b.longitude));
    expect(sent.last.isVehiclePosition, isTrue);
    final result = container.read(routeSearchStateProvider).requireValue!;
    expect(result.request!.destinationIsVehiclePosition, isTrue);
    expect(result.request!.originCapturedAt, clock.now());
  });
}
