// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../mocks/mocks.dart';

class MockGeocodingChain extends Mock implements GeocodingChain {}

class MockLocationService extends Mock implements LocationService {}

class _NullUserPosition extends UserPosition {
  @override
  UserPositionData? build() => null;
}

class _FixedUserPosition extends UserPosition {
  final UserPositionData _data;
  _FixedUserPosition(this._data);

  @override
  UserPositionData? build() => _data;
}

/// #2872 — records every `setFromGps` so a test can assert that a
/// degenerate fix is NEVER persisted as the user position.
class _SpyUserPosition extends UserPosition {
  final List<({double lat, double lng})> persisted = [];

  @override
  UserPositionData? build() => null;

  @override
  void setFromGps(double lat, double lng) {
    persisted.add((lat: lat, lng: lng));
    super.setFromGps(lat, lng);
  }
}

/// #2872 — a fake [GeolocatorWrapper] that hands back a caller-chosen fix
/// (e.g. the degenerate (0,0)/(lat,0)) through the REAL [LocationService]
/// acquisition chokepoint, so the search path exercises the production
/// guard rather than a mock that bypasses it.
class _FakeGeolocatorWrapper extends GeolocatorWrapper {
  _FakeGeolocatorWrapper(this._position);
  final Position _position;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async =>
      _position;
}

/// EV fake that returns one charging station, so unified-search tests
/// can assert the merged feed carries both kinds.
class _OneStationEVSearchState extends EVSearchState {
  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime(2024, 1, 1),
    ));
  }

  @override
  Future<void> searchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    state = AsyncValue.data(ServiceResult(
      data: const [
        ChargingStation(
          id: 'ev-merge-1',
          name: 'OCM Berlin',
          latitude: 52.5,
          longitude: 13.4,
        ),
      ],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime(2024, 1, 1),
    ));
  }
}

/// EV fake whose search always fails — models the keyless
/// `NoEvApiKeyException` case for unified-search partial-failure tests.
class _FailingEVSearchState extends EVSearchState {
  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime(2024, 1, 1),
    ));
  }

  @override
  Future<void> searchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    state = AsyncValue.error(const NoEvApiKeyException(), StackTrace.current);
  }
}

void main() {
  late FakeHiveStorage fakeStorage;
  late MockStationService mockStationService;
  late MockGeocodingChain mockGeocoding;

  setUp(() {
    // #2146 — silence the spool so errorLogger.log inside catches
    // doesn't trip the test framework's zone-error guard.
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};

    fakeStorage = FakeHiveStorage();
    mockStationService = MockStationService();
    mockGeocoding = MockGeocodingChain();

    registerFallbackValue(const SearchParams(
      lat: 0,
      lng: 0,
      radiusKm: 10,
      fuelType: FuelType.all,
    ));
    registerFallbackValue(CancelToken());
  });

  tearDown(errorLogger.resetForTest);

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      stationServiceProvider.overrideWithValue(mockStationService),
      geocodingChainProvider.overrideWithValue(mockGeocoding),
      userPositionProvider.overrideWith(() => _NullUserPosition()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  /// Container for unified-search tests, with a swappable EV fake.
  /// Unified fuel + EV search is the unconditional path (#1789).
  ProviderContainer createContainerUnified(EVSearchState evFake) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      stationServiceProvider.overrideWithValue(mockStationService),
      geocodingChainProvider.overrideWithValue(mockGeocoding),
      userPositionProvider.overrideWith(() => _NullUserPosition()),
      eVSearchStateProvider.overrideWith(() => evFake),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  const testStation = Station(
    id: 'test-1',
    name: 'Test Station',
    brand: 'TEST',
    street: 'Teststr.',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.52,
    lng: 13.41,
    isOpen: true,
    e10: 1.459,
  );

  group('SelectedFuelType', () {
    test('defaults to FuelType.all when no profile', () {
      final container = createContainer();
      final fuelType = container.read(selectedFuelTypeProvider);

      expect(fuelType, FuelType.all);
    });

    test('select() updates the fuel type', () {
      final container = createContainer();
      container.read(selectedFuelTypeProvider.notifier).select(FuelType.e10);

      expect(container.read(selectedFuelTypeProvider), FuelType.e10);
    });

    test('select() to different types works', () {
      final container = createContainer();
      final notifier = container.read(selectedFuelTypeProvider.notifier);

      notifier.select(FuelType.diesel);
      expect(container.read(selectedFuelTypeProvider), FuelType.diesel);

      notifier.select(FuelType.e5);
      expect(container.read(selectedFuelTypeProvider), FuelType.e5);
    });

    test(
        'defaults to FuelType.all when no profile exists — regression guard '
        'for the #704 effective-fuel migration', () {
      // No profile → no override source → fuel filter should stay
      // wildcard so the first search doesn't hide non-E10 pumps.
      final container = createContainer();
      expect(container.read(selectedFuelTypeProvider), FuelType.all);
    });
  });

  group('SearchRadius', () {
    test('defaults to 10.0 when no profile', () {
      final container = createContainer();
      final radius = container.read(searchRadiusProvider);

      expect(radius, 10.0);
    });

    test('set() updates the radius', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(5.0);

      expect(container.read(searchRadiusProvider), 5.0);
    });

    test('set() clamps radius to min 1.0', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(0.5);

      expect(container.read(searchRadiusProvider), 1.0);
    });

    test('set() clamps radius to max 25.0', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(50.0);

      expect(container.read(searchRadiusProvider), 25.0);
    });

    test('set() clamps negative radius to 1.0', () {
      final container = createContainer();
      container.read(searchRadiusProvider.notifier).set(-5.0);

      expect(container.read(searchRadiusProvider), 1.0);
    });
  });

  group('SearchLocation', () {
    test('defaults to empty string', () {
      final container = createContainer();
      final location = container.read(searchLocationProvider);

      expect(location, '');
    });

    test('set() updates the location string', () {
      final container = createContainer();
      container.read(searchLocationProvider.notifier).set('10115 Berlin');

      expect(container.read(searchLocationProvider), '10115 Berlin');
    });

    test('set() can be updated multiple times', () {
      final container = createContainer();
      final notifier = container.read(searchLocationProvider.notifier);

      notifier.set('10115 Berlin');
      expect(container.read(searchLocationProvider), '10115 Berlin');

      notifier.set('75001 Paris');
      expect(container.read(searchLocationProvider), '75001 Paris');
    });
  });

  group('SearchState', () {
    test('initial state is empty list', () {
      final container = createContainer();
      final state = container.read(searchStateProvider);

      expect(state, isA<AsyncData<dynamic>>());
      final data = state.value!;
      expect(data.data, isEmpty);
      expect(data.source, ServiceSource.cache);
    });

    test('searchByZipCode sets loading then data', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('10115', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByZipCode(zipCode: '10115');

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncData<dynamic>>());
      expect(state.value!.data.length, 1);
      expect(state.value!.data.first.id, 'test-1');
    });

    test('searchByZipCode handles ServiceChainExhaustedException', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('99999', cancelToken: any(named: 'cancelToken')))
          .thenThrow(const ServiceChainExhaustedException(errors: []));

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByZipCode(zipCode: '99999');

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncError<dynamic>>());
    });

    test('searchByCoordinates uses explicit lat/lng', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByCoordinates(
        lat: 52.52,
        lng: 13.41,
        locationName: 'Berlin',
      );

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncData<dynamic>>());
      expect(state.value!.data.length, 1);
    });

    test('searchByCoordinates updates searchLocation', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            locationName: 'Berlin Mitte',
          );

      expect(container.read(searchLocationProvider), 'Berlin Mitte');
    });

    test('searchByCoordinates handles DioException cancel gracefully',
        () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenThrow(DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(),
      ));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(lat: 52.52, lng: 13.41);

      // Cancel should not produce error state; state remains as initial
      final state = container.read(searchStateProvider);
      // Either still loading or data, not error
      expect(state.hasError, isFalse);
    });

    test('searchByCoordinates handles generic exceptions', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenThrow(Exception('Network error'));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(lat: 52.52, lng: 13.41);

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncError<dynamic>>());
    });

    test('searchByZipCode merges geocoding errors into result', () async {
      final geocodingError = ServiceError(
        source: ServiceSource.nativeGeocoding,
        message: 'Native geocoding unavailable',
        occurredAt: DateTime.now(),
      );

      when(() => mockGeocoding.zipCodeToCoordinates('10115', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
                errors: [geocodingError],
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: '10115');

      final state = container.read(searchStateProvider);
      // The geocoding error surfaces in the merged result. (The
      // unconditional EV fetch (#1789) also records an
      // openChargeMapApi error here — no EV key is configured in this
      // test — so the assertion targets the geocoding error directly
      // rather than the total error count.)
      expect(
        state.value!.errors.map((e) => e.source),
        contains(ServiceSource.nativeGeocoding),
      );
    });

    test('searchByCoordinates without locationName does not update searchLocation', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      // Set initial location
      container.read(searchLocationProvider.notifier).set('Initial');

      await container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(lat: 52.52, lng: 13.41);

      // Should remain as initial since no locationName was provided
      expect(container.read(searchLocationProvider), 'Initial');
    });

    test('searchByCoordinates with postalCode passes it to SearchParams', () async {
      SearchParams? capturedParams;
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((invocation) async {
        capturedParams = invocation.positionalArguments[0] as SearchParams;
        return ServiceResult(
          data: [],
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        );
      });

      final container = createContainer();
      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 48.85,
            lng: 2.35,
            postalCode: '75001',
            locationName: 'Paris',
          );

      expect(capturedParams, isNotNull);
      expect(capturedParams!.postalCode, '75001');
      expect(capturedParams!.lat, 48.85);
      expect(capturedParams!.lng, 2.35);
    });

    test('searchByCoordinates recalculates distances from user position', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        stationServiceProvider.overrideWithValue(mockStationService),
        geocodingChainProvider.overrideWithValue(mockGeocoding),
        userPositionProvider.overrideWith(() => _FixedUserPosition(
          UserPositionData(lat: 48.8, lng: 2.3, updatedAt: DateTime.now(), source: 'GPS'),
        )),
      ]);
      addTearDown(container.dispose);

      await container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(lat: 52.52, lng: 13.41);

      final state = container.read(searchStateProvider);
      // Distance from Paris (48.8, 2.3) to Berlin station (52.52, 13.41) should be > 0
      expect(state.value!.data.first.dist, greaterThan(0));
    });

    test('searchByZipCode handles geocoding address failure gracefully', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('10115', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(), cancelToken: any(named: 'cancelToken')))
          .thenThrow(Exception('Geocoding failed'));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: '10115');

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncData<dynamic>>());
      expect(state.value!.data.length, 1);
    });

    test('searchByZipCode sets searchLocation with zip and city', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('75001', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 48.86, lng: 2.34),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Paris',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [],
                source: ServiceSource.prixCarburantsApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      await container
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: '75001');

      expect(container.read(searchLocationProvider), '75001 Paris');
    });

    test('searchByCoordinates with custom fuelType passes it through', () async {
      SearchParams? capturedParams;
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((invocation) async {
        capturedParams = invocation.positionalArguments[0] as SearchParams;
        return ServiceResult(
          data: [],
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        );
      });

      final container = createContainer();
      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            fuelType: FuelType.diesel,
            radiusKm: 15.0,
          );

      expect(capturedParams!.fuelType, FuelType.diesel);
      expect(capturedParams!.radiusKm, 15.0);
    });

    test('searchByZipCode recalculates distances from user position',
        () async {
      when(() => mockGeocoding.zipCodeToCoordinates('10115', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      // Create container with user position set
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        stationServiceProvider.overrideWithValue(mockStationService),
        geocodingChainProvider.overrideWithValue(mockGeocoding),
        userPositionProvider.overrideWith(() => _FixedUserPosition(
          UserPositionData(lat: 48.8, lng: 2.3, updatedAt: DateTime.now(), source: 'GPS'),
        )),
      ]);
      addTearDown(container.dispose);

      await container
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: '10115');

      final state = container.read(searchStateProvider);
      // Distance from Paris to Berlin should be recalculated
      expect(state.value!.data.first.dist, greaterThan(0));
    });

    test(
        'repeatLastSearch is a no-op before any search has been issued '
        '(#1268 — guard against fresh-install resume crash)', () async {
      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      // Must not throw and must leave state untouched.
      await notifier.repeatLastSearch();

      final state = container.read(searchStateProvider);
      expect(state, isA<AsyncData<dynamic>>());
      expect(state.value!.data, isEmpty);
      verifyNever(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken')));
    });

    test(
        'repeatLastSearch replays the most recent searchByZipCode '
        'with the same parameters (#1268)', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('10115',
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      var stationCalls = 0;
      when(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken'))).thenAnswer((inv) async {
        stationCalls++;
        return ServiceResult(
          data: [testStation],
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        );
      });

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByZipCode(zipCode: '10115', radiusKm: 7.0);
      expect(stationCalls, 1);

      await notifier.repeatLastSearch();
      expect(stationCalls, 2,
          reason:
              'repeatLastSearch must re-run the most recently issued '
              'search so the map can refresh stale data on app resume.');

      // The second SearchParams must carry the same radius — i.e. the
      // replay used the original parameters, not a default.
      final captured = verify(() => mockStationService.searchStations(
              captureAny(),
              cancelToken: any(named: 'cancelToken')))
          .captured
          .whereType<SearchParams>()
          .toList();
      expect(captured.length, 2);
      expect(captured.last.radiusKm, 7.0);
      expect(captured.last.postalCode, '10115');
    });

    test(
        'repeatLastSearch replays searchByCoordinates with original '
        'lat/lng/postalCode (#1268)', () async {
      var stationCalls = 0;
      when(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken'))).thenAnswer((inv) async {
        stationCalls++;
        return ServiceResult(
          data: [testStation],
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        );
      });

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByCoordinates(
        lat: 43.45,
        lng: 3.45,
        postalCode: '34120',
        locationName: 'Castelnau-de-Guers',
        radiusKm: 12.5,
      );
      expect(stationCalls, 1);

      await notifier.repeatLastSearch();
      expect(stationCalls, 2);

      final captured = verify(() => mockStationService.searchStations(
              captureAny(),
              cancelToken: any(named: 'cancelToken')))
          .captured
          .whereType<SearchParams>()
          .toList();
      expect(captured.length, 2);
      expect(captured.last.lat, 43.45);
      expect(captured.last.lng, 3.45);
      expect(captured.last.postalCode, '34120');
      expect(captured.last.radiusKm, 12.5);
    });

    test(
        'repeatLastSearch tracks the LATEST search type, not just the '
        'first (#1268 — sequential tab-switch + zip-edit scenario)',
        () async {
      // First search: by zip code.
      when(() => mockGeocoding.zipCodeToCoordinates(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      final notifier = container.read(searchStateProvider.notifier);

      await notifier.searchByZipCode(zipCode: '10115');
      // Then a second, different search by coordinates.
      await notifier.searchByCoordinates(
        lat: 43.45,
        lng: 3.45,
        radiusKm: 5.0,
      );

      // Replay must replay the SECOND (coordinates) search.
      await notifier.repeatLastSearch();

      final captured = verify(() => mockStationService.searchStations(
              captureAny(),
              cancelToken: any(named: 'cancelToken')))
          .captured
          .whereType<SearchParams>()
          .toList();
      // 3 calls: zip, coordinates, replay-coordinates.
      expect(captured.length, 3);
      expect(captured.last.lat, 43.45);
      expect(captured.last.lng, 3.45);
      expect(captured.last.radiusKm, 5.0);
    });
  });

  group('EV dispatch — results match the search intent (#1866)', () {
    void stubFuel() {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
    }

    test('a fuel search returns fuel stations only — no EV rows leak in',
        () async {
      stubFuel();
      // The EV fake WOULD return a charging station — the fuel search
      // must still not surface it.
      final container = createContainerUnified(_OneStationEVSearchState());

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            fuelType: FuelType.e10,
            radiusKm: 7.0,
          );

      final items = container.read(searchStateProvider).value!.data;
      expect(items.whereType<FuelStationResult>(), hasLength(1));
      expect(items.whereType<EVStationResult>(), isEmpty);
    });

    test('an EV search returns EV stations only — no fuel rows leak in',
        () async {
      stubFuel();
      final container = createContainerUnified(_OneStationEVSearchState());

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            fuelType: FuelType.electric,
            radiusKm: 7.0,
          );

      final items = container.read(searchStateProvider).value!.data;
      expect(items.whereType<EVStationResult>(), hasLength(1));
      expect(items.whereType<FuelStationResult>(), isEmpty);
    });

    test('an EV search whose EV fetch fails records the OpenChargeMap error',
        () async {
      stubFuel();
      final container = createContainerUnified(_FailingEVSearchState());

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            fuelType: FuelType.electric,
            radiusKm: 7.0,
          );

      final result = container.read(searchStateProvider).value!;
      // EV search failed → empty feed; no fuel rows leak in to mask it.
      expect(result.data, isEmpty);
      expect(
        result.errors.where((e) => e.source == ServiceSource.openChargeMapApi),
        hasLength(1),
      );
    });
  });

  group('dispose-mid-flight (#1321 — ref-not-mounted crash)', () {
    /// Builds a [Position] without going through geolocator's platform
    /// channel — `Position` has a public const-ish ctor we can fill.
    Position fakePosition() => Position(
          latitude: 52.52,
          longitude: 13.41,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

    test(
        'GPS dispose mid-flight does not throw when inner future '
        'completes after dispose', () async {
      final mockLocation = MockLocationService();
      // Hold the GPS future open so we can dispose mid-flight, then
      // complete it AFTER the container is gone.
      final positionCompleter = Completer<Position>();
      when(() => mockLocation.getCurrentPosition())
          .thenAnswer((_) => positionCompleter.future);

      when(() => mockGeocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        stationServiceProvider.overrideWithValue(mockStationService),
        geocodingChainProvider.overrideWithValue(mockGeocoding),
        locationServiceProvider.overrideWithValue(mockLocation),
        userPositionProvider.overrideWith(() => _NullUserPosition()),
      ]);

      // Fire the search but don't await — we need to dispose mid-flight.
      final searchFuture =
          container.read(searchStateProvider.notifier).searchByGps();

      // Dispose the container while searchByGps is awaiting GPS.
      container.dispose();

      // Now complete the GPS future. Without the ref.mounted guards,
      // every post-await `state =` write would throw on the disposed
      // provider; with them, the search exits cleanly.
      positionCompleter.complete(fakePosition());

      await expectLater(searchFuture, completes);
    });

    test(
        'GPS dispose mid-await with throw does not propagate '
        'Ref._throwIfInvalidUsage', () async {
      final mockLocation = MockLocationService();
      final positionCompleter = Completer<Position>();
      when(() => mockLocation.getCurrentPosition())
          .thenAnswer((_) => positionCompleter.future);

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        stationServiceProvider.overrideWithValue(mockStationService),
        geocodingChainProvider.overrideWithValue(mockGeocoding),
        locationServiceProvider.overrideWithValue(mockLocation),
        userPositionProvider.overrideWith(() => _NullUserPosition()),
      ]);

      final searchFuture =
          container.read(searchStateProvider.notifier).searchByGps();

      container.dispose();

      // Throw AFTER dispose — without the catch-block guard this would
      // try to `state = classified` on a disposed ref and bubble up
      // Riverpod's "set state on disposed provider" StateError.
      positionCompleter.completeError(
        Exception('Network error after dispose'),
      );

      await expectLater(searchFuture, completes);
    });

    test('ZipCode dispose mid-flight does not throw', () async {
      final geocodeCompleter =
          Completer<ServiceResult<({double lat, double lng})>>();
      when(() => mockGeocoding.zipCodeToCoordinates('10115',
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) => geocodeCompleter.future);
      when(() => mockGeocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Berlin',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      final searchFuture = container
          .read(searchStateProvider.notifier)
          .searchByZipCode(zipCode: '10115');

      // Dispose while geocoding is still pending.
      container.dispose();

      // Complete the geocoding result post-dispose. The continuation
      // would normally write `state = AsyncValue.data(...)` after
      // each subsequent await — every write must short-circuit on
      // !ref.mounted.
      geocodeCompleter.complete(ServiceResult(
        data: (lat: 52.52, lng: 13.41),
        source: ServiceSource.nominatimGeocoding,
        fetchedAt: DateTime.now(),
      ));

      await expectLater(searchFuture, completes);
    });

    test(
        'CancelToken is cancelled on container dispose so in-flight '
        'HTTP is dropped', () async {
      // Capture the CancelToken handed to the station service so we
      // can assert it was cancelled when the container was disposed.
      CancelToken? capturedToken;
      final stationCompleter =
          Completer<ServiceResult<List<Station>>>();
      when(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken'))).thenAnswer((inv) {
        capturedToken =
            inv.namedArguments[#cancelToken] as CancelToken?;
        return stationCompleter.future;
      });

      final container = createContainer();
      // searchStateProvider is autoDispose; keep it alive across the
      // read+delay so the autoDispose timer doesn't run our onDispose
      // before we manually dispose the container.
      final sub = container.listen(
        searchStateProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final searchFuture = container
          .read(searchStateProvider.notifier)
          .searchByCoordinates(lat: 52.52, lng: 13.41);

      // Yield so the search reaches the station-service await and
      // the CancelToken is captured.
      await Future<void>.delayed(Duration.zero);
      expect(capturedToken, isNotNull,
          reason: 'station service must be reached before dispose');
      expect(capturedToken!.isCancelled, isFalse);

      container.dispose();

      expect(capturedToken!.isCancelled, isTrue,
          reason:
              'ref.onDispose in build() must cancel the active token '
              'so the in-flight HTTP request is dropped (#1321).');

      // Complete the station future with a cancel error — the search
      // must still complete cleanly (no unhandled exception).
      stationCompleter.completeError(DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(),
      ));

      await expectLater(searchFuture, completes);
    });
  });

  group('searchByGps — degenerate-fix guard (#2872)', () {
    Position fix(double lat, double lng) => Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

    /// Wires the REAL [LocationService] to a fake [GeolocatorWrapper] that
    /// returns [position], plus a spy [UserPosition], so a search exercises
    /// the production acquisition guard end-to-end.
    ({ProviderContainer container, _SpyUserPosition spy}) containerFor(
      Position position,
    ) {
      final spy = _SpyUserPosition();
      final c = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        stationServiceProvider.overrideWithValue(mockStationService),
        geocodingChainProvider.overrideWithValue(mockGeocoding),
        geolocatorWrapperProvider
            .overrideWithValue(_FakeGeolocatorWrapper(position)),
        userPositionProvider.overrideWith(() => spy),
      ]);
      addTearDown(c.dispose);
      return (container: c, spy: spy);
    }

    void stubStation() {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));
    }

    test('a (0,0) fix surfaces an error and is NOT persisted', () async {
      stubStation();
      final t = containerFor(fix(0, 0));

      await t.container.read(searchStateProvider.notifier).searchByGps();

      expect(t.container.read(searchStateProvider), isA<AsyncError<dynamic>>());
      expect(t.spy.persisted, isEmpty,
          reason: 'a null-island fix must never reach userPositionProvider');
      verifyNever(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken')));
    });

    test('a one-axis-unacquired (lat,0) fix surfaces an error and is NOT '
        'persisted', () async {
      stubStation();
      final t = containerFor(fix(42.7, 0));

      await t.container.read(searchStateProvider.notifier).searchByGps();

      expect(t.container.read(searchStateProvider), isA<AsyncError<dynamic>>());
      expect(t.spy.persisted, isEmpty);
      verifyNever(() => mockStationService.searchStations(any(),
          cancelToken: any(named: 'cancelToken')));
    });

    test('a valid France fix persists the position and searches — no '
        'regression', () async {
      stubStation();
      when(() => mockGeocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: 'Rivesaltes',
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      final t = containerFor(fix(42.7667, 2.8667));

      await t.container.read(searchStateProvider.notifier).searchByGps();

      expect(t.container.read(searchStateProvider), isA<AsyncData<dynamic>>());
      expect(t.spy.persisted, hasLength(1));
      expect(t.spy.persisted.single.lat, closeTo(42.7667, 0.0001));
      expect(t.spy.persisted.single.lng, closeTo(2.8667, 0.0001));
    });
  });

  group('fuelStationsProvider', () {
    test('extracts fuel stations from search results', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final container = createContainer();
      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52, lng: 13.41, fuelType: FuelType.e10,
          );

      final stations = container.read(fuelStationsProvider);
      expect(stations.length, 1);
      expect(stations.first.id, 'test-1');
    });

    test('returns empty list when no search results', () {
      final container = createContainer();
      final stations = container.read(fuelStationsProvider);
      expect(stations, isEmpty);
    });
  });
}
