import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../mocks/mocks.dart';

class MockGeocodingChain extends Mock implements GeocodingChain {}

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

/// Fake EVSearchState that records calls to [searchNearby] without
/// hitting real services.
class _FakeEVSearchState extends EVSearchState {
  bool searchNearbyCalled = false;
  double? lastLat;
  double? lastLng;
  double? lastRadiusKm;

  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> searchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    searchNearbyCalled = true;
    lastLat = lat;
    lastLng = lng;
    lastRadiusKm = radiusKm;
    state = AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime.now(),
    ));
  }
}

void main() {
  late FakeHiveStorage fakeStorage;
  late MockStationService mockStationService;
  late MockGeocodingChain mockGeocoding;

  setUp(() {
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

  /// Creates a container with a fake EVSearchState for EV dispatch tests.
  (ProviderContainer, _FakeEVSearchState) createContainerWithEv() {
    final fakeEv = _FakeEVSearchState();
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      stationServiceProvider.overrideWithValue(mockStationService),
      geocodingChainProvider.overrideWithValue(mockGeocoding),
      userPositionProvider.overrideWith(() => _NullUserPosition()),
      eVSearchStateProvider.overrideWith(() => fakeEv),
    ]);
    addTearDown(c.dispose);
    return (c, fakeEv);
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

      expect(state, isA<AsyncData>());
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
      expect(state, isA<AsyncData>());
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
      expect(state, isA<AsyncError>());
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
      expect(state, isA<AsyncData>());
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
      expect(state, isA<AsyncError>());
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
      expect(state.value!.errors.length, 1);
      expect(
          state.value!.errors.first.source, ServiceSource.nativeGeocoding);
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
      expect(state, isA<AsyncData>());
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
      expect(state, isA<AsyncData>());
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

  group('EV dispatch (unified search trigger)', () {
    test('searchByCoordinates with FuelType.electric dispatches to EVSearchState', () async {
      final (container, fakeEv) = createContainerWithEv();

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 48.85,
            lng: 2.35,
            fuelType: FuelType.electric,
            radiusKm: 5.0,
          );

      expect(fakeEv.searchNearbyCalled, isTrue);
      expect(fakeEv.lastLat, 48.85);
      expect(fakeEv.lastLng, 2.35);
      expect(fakeEv.lastRadiusKm, 5.0);
      // Fuel station service should NOT have been called
      verifyNever(() => mockStationService.searchStations(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    test('searchByCoordinates with non-electric fuel does NOT dispatch to EVSearchState', () async {
      when(() => mockStationService.searchStations(any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: [testStation],
                source: ServiceSource.tankerkoenigApi,
                fetchedAt: DateTime.now(),
              ));

      final (container, fakeEv) = createContainerWithEv();

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 48.85,
            lng: 2.35,
            fuelType: FuelType.e10,
          );

      expect(fakeEv.searchNearbyCalled, isFalse);
      verify(() => mockStationService.searchStations(
            any(),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('searchByZipCode with FuelType.electric geocodes then dispatches to EVSearchState', () async {
      when(() => mockGeocoding.zipCodeToCoordinates('75001', cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 48.86, lng: 2.34),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));

      final (container, fakeEv) = createContainerWithEv();

      await container.read(searchStateProvider.notifier).searchByZipCode(
            zipCode: '75001',
            fuelType: FuelType.electric,
            radiusKm: 8.0,
          );

      expect(fakeEv.searchNearbyCalled, isTrue);
      expect(fakeEv.lastLat, 48.86);
      expect(fakeEv.lastLng, 2.34);
      expect(fakeEv.lastRadiusKm, 8.0);
      verifyNever(() => mockStationService.searchStations(
            any(),
            cancelToken: any(named: 'cancelToken'),
          ));
    });

    test('searchByCoordinates with FuelType.electric skips fuel service entirely', () async {
      final (container, fakeEv) = createContainerWithEv();

      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 52.52,
            lng: 13.41,
            fuelType: FuelType.electric,
            radiusKm: 10.0,
            locationName: 'Berlin',
          );

      expect(fakeEv.searchNearbyCalled, isTrue);
      // SearchState itself should NOT be in data state from fuel results
      // (it stays in initial state because EV dispatch returned early)
      final state = container.read(searchStateProvider);
      expect(state.value!.data, isEmpty);
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
