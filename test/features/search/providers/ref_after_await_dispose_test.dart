// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../helpers/silence_error_logger.dart';
import '../../../mocks/mocks.dart';

class _MockLocationService extends Mock implements LocationService {}

/// A platform-free GPS stream, so `RadarSearch._subscribeGps` does not
/// reach the geolocator method channel (and its dispose does not throw a
/// MissingPluginException while we are disposing the container).
class _EmptyGeolocator extends GeolocatorWrapper {
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      const Stream<Position>.empty();
}

/// A [UserPosition] whose GPS refresh parks on [gate], so a test can
/// dispose the provider while `runRadar` is suspended on it.
class _GatedUserPosition extends UserPosition {
  final Completer<void> gate = Completer<void>();
  final List<({double lat, double lng})> persisted = [];

  @override
  UserPositionData? build() => null;

  @override
  Future<void> updateFromGps() => gate.future;

  @override
  void setFromGps(double lat, double lng) {
    persisted.add((lat: lat, lng: lng));
    super.setFromGps(lat, lng);
  }
}

/// Records every `state =` so a test can prove the resume wrote nothing.
class _SpySearchState extends SearchState {
  final writes = <AsyncValue<ServiceResult<List<SearchResultItem>>>>[];

  @override
  set state(AsyncValue<ServiceResult<List<SearchResultItem>>> value) {
    writes.add(value);
    super.state = value;
  }
}

class _SpyRadarSearch extends RadarSearch {
  final writes = <RadarSearchState>[];

  @override
  set state(RadarSearchState value) {
    writes.add(value);
    super.state = value;
  }
}

/// #4388 — an auto-dispose Notifier that is disposed while one of its own
/// `await`s is pending must resume without touching `ref`.
///
/// Both providers here are `@riverpod` (auto-dispose) and both are driven
/// from a screen that the user can pop mid-search. Before the guards, the
/// resume called `ref.read(...)` on a disposed element, which throws
/// `Cannot use the Ref of the provider after it has been disposed` — an
/// uncaught async error, because nothing awaits these methods from the
/// widget layer.
///
/// Each test drives the REAL notifier method, parks it on a real
/// collaborator's future, disposes the container underneath it, and then
/// releases the future. The assertions are the two halves of the
/// contract: the method completes (no throw) and no `state` was written
/// after the disposal.
void main() {
  silenceErrorLoggerSpool();

  setUpAll(() {
    registerFallbackValue(const LocationSettings());
  });

  group('SearchState.searchByGps (#4388)', () {
    test('disposed while awaiting the GPS fix: no throw, no state write',
        () async {
      final gate = Completer<Position>();
      final location = _MockLocationService();
      when(location.getCurrentPosition).thenAnswer((_) => gate.future);

      final spy = _SpySearchState();
      final position = _GatedUserPosition();
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
        stationServiceProvider.overrideWithValue(MockStationService()),
        locationServiceProvider.overrideWithValue(location),
        userPositionProvider.overrideWith(() => position),
        searchStateProvider.overrideWith(() => spy),
      ]);

      final pending = container.read(searchStateProvider.notifier).searchByGps();
      // Let `_runSearch` write its loading state and suspend on the fix.
      await Future<void>.delayed(Duration.zero);
      final writesBeforeDispose = spy.writes.length;
      expect(writesBeforeDispose, greaterThan(0),
          reason: 'the loading write must have happened, or the test is '
              'not actually suspended inside the search');

      // The user pops the search screen while the fix is still pending.
      container.dispose();
      gate.complete(Position(
        latitude: 52.52,
        longitude: 13.405,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ));

      await expectLater(pending, completes);
      expect(spy.writes, hasLength(writesBeforeDispose),
          reason: 'the resume must not write state on a disposed notifier');
      expect(position.persisted, isEmpty,
          reason: 'nothing past the ref.mounted guard may run — the fix '
              'must not even be persisted');
    });
  });

  group('RadarSearch.runRadar (#4388)', () {
    test('disposed while awaiting the fresh fix: no throw, no state write',
        () async {
      final position = _GatedUserPosition();
      final spy = _SpyRadarSearch();
      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
        stationServiceProvider.overrideWithValue(MockStationService()),
        geolocatorWrapperProvider.overrideWithValue(_EmptyGeolocator()),
        userPositionProvider.overrideWith(() => position),
        radarSearchProvider.overrideWith(() => spy),
      ]);

      final pending = container.read(radarSearchProvider.notifier).runRadar();
      // Let the provisional paint land and the run suspend on the fix.
      await Future<void>.delayed(Duration.zero);
      final writesBeforeDispose = spy.writes.length;
      expect(writesBeforeDispose, greaterThan(0),
          reason: 'the provisional "locating" write must have happened');

      container.dispose();
      position.gate.complete();

      await expectLater(pending, completes);
      expect(spy.writes, hasLength(writesBeforeDispose),
          reason: 'the authoritative scan must be dropped, not written into '
              'a disposed notifier');
    });
  });
}
