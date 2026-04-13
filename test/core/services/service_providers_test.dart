import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/services/impl/demo_station_service.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';

import '../../mocks/mocks.dart';

class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedActiveCountry(this._country);

  @override
  CountryConfig build() => _country;
}

void main() {
  late MockHiveStorage mockStorage;
  late MockCacheManager mockCache;

  setUp(() {
    mockStorage = MockHiveStorage();
    mockCache = MockCacheManager();
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer({
    CountryConfig country = Countries.germany,
  }) {
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
      cacheManagerProvider.overrideWithValue(mockCache),
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
      when(() => mockStorage.hasApiKey()).thenReturn(false);

      final container = createContainer(country: Countries.germany);
      final service = container.read(stationServiceProvider);

      expect(service, isA<StationServiceChain>());
    });

    test('returns StationServiceChain when DE and API key present', () {
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      when(() => mockStorage.getApiKey()).thenReturn('test-key');

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
