// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/country_raw_service_builder.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/core/services/impl/demo_station_service.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/services/station_service_chain.dart';
import 'package:tankstellen/features/station_services/austria/econtrol_station_service.dart';
import 'package:tankstellen/features/station_services/germany/tankerkoenig_station_service.dart';
import 'package:tankstellen/features/station_services/luxembourg/luxembourg_station_service.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_station_service.dart';
import 'package:tankstellen/features/station_services/slovenia/slovenia_station_service.dart';
import 'package:tankstellen/features/station_services/south_korea/south_korea_station_service.dart';

import '../../fakes/fake_storage_repository.dart';

/// #2861 — the Ref-free background construction seam.
///
/// `buildBackgroundService` must build the SAME `StationServiceChain` per
/// country the foreground does (the foreground `createService(Ref)` now
/// delegates to it), so these tests drive the REAL registry + the real
/// per-country `buildRawCountryService`, not a fake. The chain's internals
/// (error source, policy) are private; we assert the public `countryCode`
/// on the wrapper and use the construction-path function
/// [buildRawCountryService] for the primary-service-type assertions.
void main() {
  CacheManager cache() => CacheManager(FakeStorageRepository());

  CountryServiceDependencies deps({
    FakeStorageRepository? storage,
    Dio? dio,
  }) =>
      CountryServiceDependencies(
        storage: storage ?? FakeStorageRepository(),
        cache: cache(),
        tankerkoenigDio: dio,
      );

  group('buildBackgroundService — chain wrapper', () {
    test('wraps every registered country in a StationServiceChain stamped '
        'with that country code', () {
      for (final entry in CountryServiceRegistry.entries) {
        final service = CountryServiceRegistry.buildBackgroundService(
          entry.countryCode,
          storage: FakeStorageRepository(),
          cache: cache(),
          tankerkoenigDio: entry.countryCode == 'DE' ? Dio() : null,
        );
        expect(service, isA<StationServiceChain>(),
            reason: '${entry.countryCode} must be chained');
        expect((service as StationServiceChain).countryCode, entry.countryCode);
      }
    });

    test('an unregistered country → bare Demo service (not a chain)', () {
      final service = CountryServiceRegistry.buildBackgroundService(
        'ZZ',
        storage: FakeStorageRepository(),
        cache: cache(),
      );
      expect(service, isA<DemoStationService>());
      expect(service, isNot(isA<StationServiceChain>()));
    });
  });

  group('buildRawCountryService — single construction path', () {
    test('DE with a key → Tankerkönig; without bundled key → Demo', () async {
      final withKey = FakeStorageRepository();
      await withKey.setApiKey('key123');
      expect(
        buildRawCountryService('DE', deps(storage: withKey, dio: Dio())),
        isA<TankerkoenigStationService>(),
      );

      final noKey = FakeStorageRepository();
      noKey.inner.hasBundledDefaultKey = false;
      expect(
        buildRawCountryService('DE', deps(storage: noKey, dio: Dio())),
        isA<DemoStationService>(),
      );
    });

    test('DE with a key but no Dio → Demo (cannot reach the API)', () async {
      final withKey = FakeStorageRepository();
      await withKey.setApiKey('key123');
      expect(
        buildRawCountryService('DE', deps(storage: withKey)),
        isA<DemoStationService>(),
      );
    });

    test('AT → E-Control', () {
      expect(buildRawCountryService('AT', deps()),
          isA<EControlStationService>());
    });

    test('PT → Portugal', () {
      expect(buildRawCountryService('PT', deps()),
          isA<PortugalStationService>());
    });

    test('LU → Luxembourg, SI → Slovenia', () {
      expect(buildRawCountryService('LU', deps()),
          isA<LuxembourgStationService>());
      expect(buildRawCountryService('SI', deps()),
          isA<SloveniaStationService>());
    });

    test('KR with a key → OPINET; without a key → Demo', () async {
      final withKey = FakeStorageRepository();
      await withKey.setApiKey('opinet');
      expect(buildRawCountryService('KR', deps(storage: withKey)),
          isA<SouthKoreaStationService>());

      // KR/CL gate on getApiKey() (not hasApiKey), so a null key → Demo
      // regardless of the bundled-default flag.
      expect(buildRawCountryService('KR', deps()), isA<DemoStationService>());
    });

    test('an unregistered country → Demo', () {
      expect(buildRawCountryService('ZZ', deps()), isA<DemoStationService>());
    });
  });

  group('foreground non-regression: same primary types via the raw builder',
      () {
    // The foreground buildService(Ref) reads its deps from the Ref and calls
    // buildBackgroundService → buildRawCountryService. These assertions lock
    // the per-country primary type the foreground has always produced.
    final cases = <String, TypeMatcher<StationService>>{
      'AT': isA<EControlStationService>(),
      'PT': isA<PortugalStationService>(),
      'LU': isA<LuxembourgStationService>(),
      'SI': isA<SloveniaStationService>(),
    };
    cases.forEach((code, matcher) {
      test('$code primary unchanged', () {
        expect(buildRawCountryService(code, deps()), matcher);
      });
    });
  });
}
