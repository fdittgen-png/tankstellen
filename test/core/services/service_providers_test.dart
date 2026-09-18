// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/services/impl/demo_station_service.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../mocks/mocks.dart';

/// Answers every request with an empty Tankerkönig list payload and records
/// the URI it was asked for — the seam that proves the `apikey` query
/// parameter survived the interceptor.
class _CapturingAdapter implements HttpClientAdapter {
  final List<Uri> requestUris = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestUris.add(options.uri);
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'stations': <dynamic>[]}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedActiveCountry(this._country);

  @override
  CountryConfig build() => _country;
}

void main() {
  late FakeHiveStorage fakeStorage;
  late MockCacheManager mockCache;

  setUp(() {
    fakeStorage = FakeHiveStorage()..hasBundledDefaultKey = false;
    mockCache = MockCacheManager();
  });

  ProviderContainer createContainer({
    CountryConfig country = Countries.germany,
    CacheManager? cache,
  }) {
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
      cacheManagerProvider.overrideWithValue(cache ?? mockCache),
      activeCountryProvider.overrideWith(() => _FixedActiveCountry(country)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('stationServiceProvider', () {
    test('returns DemoStationService chain when DE and no API key', () {
      // After #425 the Germany factory lives in CountryServiceRegistry
      // and the registry wraps every service (including the demo
      // fallback) in a StationServiceChain. The behaviour is preserved:
      // demo data still backs the chain, the chain is just the consistent
      // outer type so callers don't have to special-case Germany either.
      // Default fake state: no key configured, hasApiKey() == false.

      final container = createContainer(country: Countries.germany);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain when DE and API key present',
        () async {
      await fakeStorage.setApiKey('de', 'test-key');

      final container = createContainer(country: Countries.germany);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain for France (no API key needed)', () {
      final container = createContainer(country: Countries.france);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain for Austria', () {
      final container = createContainer(country: Countries.austria);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain for Spain', () {
      final container = createContainer(country: Countries.spain);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain for Italy', () {
      final container = createContainer(country: Countries.italy);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain for Denmark', () {
      final container = createContainer(country: Countries.denmark);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns DemoStationService for unknown country code', () {
      const unknown = CountryConfig(
        code: 'XX',
        name: 'Unknown',
        flag: '',
        locale: 'en_US',
        postalCodeLength: 5,
        postalCodeRegex: r'^\d{5}$',
        postalCodeLabel: 'Zip',
      );

      final container = createContainer(country: unknown);
      final service = container.read(stationServiceProvider);

      expect(service, isA<DemoStationService>());
    });
  });

  group('tankerkoenigDioProvider lifetime (#4381)', () {
    test(
        'the Dio retained by the keepAlive station service still applies the '
        'API key after the Dio provider element is disposed', () async {
      await fakeStorage.setApiKey('de', 'test-key');
      final container = createContainer(
        country: Countries.germany,
        cache: CacheManager(fakeStorage),
      );

      // The keepAlive station service resolves the Tankerkönig Dio through
      // the registry and RETAINS it inside the chain for the whole session.
      final service = container.read(stationServiceProvider);
      expect(service, isA<StationServiceChain>());

      final dio = container.read(tankerkoenigDioProvider);
      final adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;

      // #4381 — tear the whole provider scope down. In production the gap
      // was narrower (nothing listens to the Dio provider, so its
      // auto-dispose element died the moment the registry's `ref.read`
      // returned, while the keepAlive chain kept the instance) but the
      // invariant is the same and this form is lifetime-agnostic: a Dio
      // someone else holds must carry everything it needs, never a `Ref`
      // it can outlive.
      container.dispose();
      await Future<void>.delayed(Duration.zero);

      final result = await service.searchStations(
        const SearchParams(lat: 52.52, lng: 13.405),
      );

      expect(result.data, isEmpty);
      expect(adapter.requestUris, hasLength(1));
      expect(
        adapter.requestUris.single.queryParameters['apikey'],
        'test-key',
      );
    });

  });

  group('geocodingChainProvider', () {
    test('creates GeocodingChain for Germany', () {
      final container = createContainer(country: Countries.germany);
      final geocoding = container.read(geocodingChainProvider);

      expect(geocoding, isNotNull);
    });

    test('creates GeocodingChain for France', () {
      final container = createContainer(country: Countries.france);
      final geocoding = container.read(geocodingChainProvider);

      expect(geocoding, isNotNull);
    });

    test('creates GeocodingChain for Austria', () {
      final container = createContainer(country: Countries.austria);
      final geocoding = container.read(geocodingChainProvider);

      expect(geocoding, isNotNull);
    });
  });
}
