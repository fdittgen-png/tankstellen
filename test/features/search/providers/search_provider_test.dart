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
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

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

void main() {
  late MockHiveStorage mockStorage;
  late MockStationService mockStationService;
  late MockGeocodingChain mockGeocoding;

  setUp(() {
    mockStorage = MockHiveStorage();
    mockStationService = MockStationService();
    mockGeocoding = MockGeocodingChain();
    when(() => mockStorage.getSetting(any())).thenReturn(null);

    registerFallbackValue(SearchParams(
      lat: 0,
      lng: 0,
      radiusKm: 10,
      fuelType: FuelType.all,
    ));
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
      stationServiceProvider.overrideWithValue(mockStationService),
      geocodingChainProvider.overrideWithValue(mockGeocoding),
      userPositionProvider.overrideWith(() => _NullUserPosition()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  final testStation = Station(
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
      when(() => mockGeocoding.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any()))
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
      when(() => mockGeocoding.zipCodeToCoordinates('99999'))
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

      when(() => mockGeocoding.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
                errors: [geocodingError],
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any()))
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
        hiveStorageProvider.overrideWithValue(mockStorage),
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
      when(() => mockGeocoding.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any()))
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
      when(() => mockGeocoding.zipCodeToCoordinates('75001'))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 48.86, lng: 2.34),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any()))
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
      when(() => mockGeocoding.zipCodeToCoordinates('10115'))
          .thenAnswer((_) async => ServiceResult(
                data: (lat: 52.52, lng: 13.41),
                source: ServiceSource.nominatimGeocoding,
                fetchedAt: DateTime.now(),
              ));
      when(() => mockGeocoding.coordinatesToAddress(any(), any()))
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
        hiveStorageProvider.overrideWithValue(mockStorage),
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
  });
}
