// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../mocks/mocks.dart';

/// Epic "app-wide latency" — the search must not wait on a step its result
/// does not need. Every test gates the step that used to block and proves
/// the station request (or the preview) happens while it is still pending.

class _MockGeocodingChain extends Mock implements GeocodingChain {}

/// A [LocationService] whose fix resolves only when the test says so.
class _GatedLocationService implements LocationService {
  final gate = Completer<Position>();
  int calls = 0;

  @override
  Future<Position> getCurrentPosition() {
    calls++;
    return gate.future;
  }

  @override
  double distanceBetween(double a, double b, double c, double d) => 0;
}

class _PersistedPosition extends UserPosition {
  _PersistedPosition(this._data, {this.refresh});
  final UserPositionData? _data;

  /// When set, [updateFromGps] resolves only when this completes.
  final Completer<void>? refresh;

  @override
  UserPositionData? build() => _data;

  @override
  Future<void> updateFromGps() => refresh?.future ?? Future.value();
}

class _AutoUpdateProfile extends ActiveProfile {
  @override
  UserProfile? build() =>
      const UserProfile(id: 'p1', name: 'p1', autoUpdatePosition: true);
}

final _now = DateTime(2026, 10, 7, 12);

Position _fix(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: _now,
      accuracy: 20,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

const _cached = Station(
  id: 'cached-1',
  name: 'Last Time',
  brand: 'JET',
  street: 'A',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.405,
  isOpen: true,
  e10: 1.799,
);

const _fresh = Station(
  id: 'fresh-1',
  name: 'Now',
  brand: 'ARAL',
  street: 'B',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.52,
  lng: 13.405,
  isOpen: true,
  e10: 1.749,
);

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockStationService stations;
  late _MockGeocodingChain geocoding;
  late _GatedLocationService location;
  late CacheManager cache;
  final searched = <SearchParams>[];

  setUp(() {
    errorLogger.spoolEnqueueOverride = ({
      required String isolateTaskName,
      required Object error,
      StackTrace? stack,
      Map<String, dynamic>? contextMap,
      DateTime? timestamp,
    }) async {};
    registerFallbackValue(const SearchParams(
        lat: 0, lng: 0, radiusKm: 10, fuelType: FuelType.all));
    registerFallbackValue(CancelToken());
    stations = MockStationService();
    geocoding = _MockGeocodingChain();
    location = _GatedLocationService();
    cache = CacheManager(_MapCacheStorage());
    searched.clear();
    when(() => stations.searchStations(any(),
        cancelToken: any(named: 'cancelToken'))).thenAnswer((inv) async {
      searched.add(inv.positionalArguments.first as SearchParams);
      return ServiceResult(
        data: const [_fresh],
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: _now,
      );
    });
  });

  tearDown(errorLogger.resetForTest);

  ProviderContainer container({
    UserPositionData? persisted,
    Completer<void>? positionRefresh,
    bool autoUpdate = false,
  }) {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
      stationServiceProvider.overrideWithValue(stations),
      geocodingChainProvider.overrideWithValue(geocoding),
      locationServiceProvider.overrideWithValue(location),
      cacheManagerProvider.overrideWithValue(cache),
      appClockProvider.overrideWithValue(FixedClock(_now)),
      userPositionProvider.overrideWith(
          () => _PersistedPosition(persisted, refresh: positionRefresh)),
      if (autoUpdate) activeProfileProvider.overrideWith(_AutoUpdateProfile.new),
    ]);
    addTearDown(c.dispose);
    c.listen(searchStateProvider, (_, _) {});
    // The search screen keeps the label alive the same way.
    c.listen(searchLocationProvider, (_, _) {});
    return c;
  }

  UserPositionData gpsAt(Duration age) => UserPositionData(
        lat: 52.52,
        lng: 13.405,
        updatedAt: _now.subtract(age),
        source: 'GPS',
      );

  group('GPS search does not wait on the reverse geocode', () {
    test('the station request is sent while the geocoder is still pending, '
        'and carries no postal code', () async {
      final address = Completer<ServiceResult<String>>();
      when(() => geocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) => address.future);
      final c = container();

      final search = c
          .read(searchStateProvider.notifier)
          .searchByGps(fuelType: FuelType.e10, radiusKm: 10);
      location.gate.complete(_fix(52.52, 13.405));
      await search;

      expect(searched, hasLength(1),
          reason: 'the search used to wait for Nominatim first (up to 20 s)');
      expect(searched.single.postalCode, isNull);
      expect(c.read(searchStateProvider).value!.data.map((i) => i.id),
          ['fresh-1']);

      // The label still lands once the geocoder answers.
      address.complete(ServiceResult(
        data: '10115 Berlin',
        source: ServiceSource.nominatimGeocoding,
        fetchedAt: _now,
      ));
      await _settle();
      expect(c.read(searchLocationProvider), '10115 Berlin');
    });

    test('a geocode answering after a NEWER search never relabels it',
        () async {
      final address = Completer<ServiceResult<String>>();
      when(() => geocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) => address.future);
      final c = container();
      final notifier = c.read(searchStateProvider.notifier);

      final first = notifier.searchByGps(fuelType: FuelType.e10);
      location.gate.complete(_fix(52.52, 13.405));
      await first;
      await notifier.searchByCoordinates(
          lat: 48.1, lng: 11.5, locationName: 'München');

      address.complete(ServiceResult(
        data: 'stale Berlin label',
        source: ServiceSource.nominatimGeocoding,
        fetchedAt: _now,
      ));
      await _settle();
      expect(c.read(searchLocationProvider), 'München');
    });
  });

  group('instant paint from the last search', () {
    Future<void> seedLastCell(ProviderContainer c) => cache.put(
          CacheKey.stationSearch(52.52, 13.405, 10, FuelType.e10.apiValue,
              countryCode: c.read(activeCountryProvider).code),
          serializeStationList(const [_cached]),
          ttl: CacheTtl.stationSearch,
          source: ServiceSource.tankerkoenigApi,
        );

    test('the cached stations of the last position paint BEFORE the fix',
        () async {
      when(() => geocoding.coordinatesToAddress(any(), any(),
              cancelToken: any(named: 'cancelToken')))
          .thenThrow(Exception('offline'));
      final c = container(persisted: gpsAt(const Duration(minutes: 5)));
      await seedLastCell(c);

      final search = c
          .read(searchStateProvider.notifier)
          .searchByGps(fuelType: FuelType.e10, radiusKm: 10);
      await _settle();

      expect(location.calls, 1, reason: 'the fix is still pending');
      expect(c.read(searchStateProvider).value?.data.map((i) => i.id),
          ['cached-1'],
          reason: 'the shimmer used to stay up for fix + geocode + network');

      location.gate.complete(_fix(52.53, 13.41));
      await search;
      expect(c.read(searchStateProvider).value!.data.map((i) => i.id),
          ['fresh-1']);
    });

    test('a position older than the preview window paints nothing early',
        () async {
      final c = container(persisted: gpsAt(const Duration(hours: 2)));
      await seedLastCell(c);

      unawaited(c
          .read(searchStateProvider.notifier)
          .searchByGps(fuelType: FuelType.e10, radiusKm: 10));
      await _settle();

      expect(c.read(searchStateProvider).isLoading, isTrue,
          reason: 'stations around a two-hour-old position may be another '
              'town — wait for the fix');
    });
  });

  test('a fix taken seconds ago is reused, not re-acquired', () async {
    when(() => geocoding.coordinatesToAddress(any(), any(),
            cancelToken: any(named: 'cancelToken')))
        .thenThrow(Exception('offline'));
    final c = container(persisted: gpsAt(const Duration(seconds: 10)));

    await c.read(searchStateProvider.notifier).searchByGps();

    expect(location.calls, 0,
        reason: 'Refresh took a fix, then the search took a second one');
    expect(searched.single.lat, 52.52);
  });

  test('a ZIP search does not wait for the optional position refresh',
      () async {
    when(() => geocoding.zipCodeToCoordinates('10115',
            cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => ServiceResult(
              data: (lat: 52.52, lng: 13.405),
              source: ServiceSource.nominatimGeocoding,
              fetchedAt: _now,
            ));
    when(() => geocoding.coordinatesToAddress(any(), any(),
            cancelToken: any(named: 'cancelToken')))
        .thenAnswer((_) async => ServiceResult(
              data: 'Berlin',
              source: ServiceSource.nominatimGeocoding,
              fetchedAt: _now,
            ));
    final refresh = Completer<void>();
    final c = container(positionRefresh: refresh, autoUpdate: true);

    final search =
        c.read(searchStateProvider.notifier).searchByZipCode(zipCode: '10115');
    await _settle();

    expect(searched, hasLength(1),
        reason: 'the GPS refresh only re-measures distances at the end');

    refresh.complete();
    await search;
    expect(c.read(searchStateProvider).value!.data.map((i) => i.id),
        ['fresh-1']);
  });
}

/// In-memory [CacheStorage] with the real [CacheManager] envelope semantics.
class _MapCacheStorage implements CacheStorage {
  final Map<String, dynamic> store = {};

  @override
  Future<void> cacheData(String key, dynamic data) async {
    if (data == null) {
      store.remove(key);
    } else {
      store[key] = data;
    }
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final raw = store[key];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  @override
  Future<void> clearCache() async => store.clear();

  @override
  int get cacheEntryCount => store.length;

  @override
  Iterable<dynamic> get cacheKeys => store.keys;

  @override
  Future<void> deleteCacheEntry(String key) async => store.remove(key);
}
