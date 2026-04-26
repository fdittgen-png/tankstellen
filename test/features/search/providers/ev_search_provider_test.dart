import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';

import '../../../fakes/fake_hive_storage.dart';

/// Tests cover the branches of EVSearchState that do **not** hit the
/// real OpenChargeMap API — notably the initial state and the
/// no-API-key guard. The API-success branch is exercised indirectly
/// by the integration-style search_provider tests, which drive
/// EVSearchState through its public searchNearby API; covering it
/// here too would require a dependency-injection seam for
/// EVChargingService that does not exist today.
void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage();
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('EVSearchState.build', () {
    test('starts with an empty AsyncData payload', () {
      final container = createContainer();
      final state = container.read(eVSearchStateProvider);
      expect(state, isA<AsyncData<ServiceResult<List<dynamic>>>>());
      expect(state.value?.data, isEmpty);
      expect(state.value?.source, ServiceSource.openChargeMapApi);
      expect(state.value?.fetchedAt, isNotNull);
    });

    test('keepAlive prevents auto-dispose between reads', () {
      // The `keepAlive: true` on the provider means two reads
      // separated by a "nobody watching" gap return the SAME
      // state payload — guards the #550 fix against regression.
      final container = createContainer();
      final first = container.read(eVSearchStateProvider);
      // Simulate a gap where no listener watches the provider by
      // NOT calling .listen() or watch() — then read again.
      final second = container.read(eVSearchStateProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('EVSearchState.searchNearby — no API key guard', () {
    test('sets AsyncError(NoEvApiKeyException) when key is null', () async {
      // FakeHiveStorage returns null for getEvApiKey by default.
      final container = createContainer();
      await container
          .read(eVSearchStateProvider.notifier)
          .searchNearby(lat: 48.85, lng: 2.35, radiusKm: 10);

      final state = container.read(eVSearchStateProvider);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<NoEvApiKeyException>());
    });

    test('sets AsyncError(NoEvApiKeyException) when key is empty',
        () async {
      await fakeStorage.setEvApiKey('');

      final container = createContainer();
      await container
          .read(eVSearchStateProvider.notifier)
          .searchNearby(lat: 0, lng: 0, radiusKm: 5);

      final state = container.read(eVSearchStateProvider);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<NoEvApiKeyException>());
    });

    test('error state carries the stack trace', () async {
      final container = createContainer();
      await container
          .read(eVSearchStateProvider.notifier)
          .searchNearby(lat: 0, lng: 0, radiusKm: 5);

      final state = container.read(eVSearchStateProvider);
      expect(state.stackTrace, isNotNull);
    });

    test('a failed searchNearby leaves the provider still alive for retry',
        () async {
      // Regression guard for #550 — if keepAlive ever gets dropped,
      // the notifier would be disposed mid-error-surface and a retry
      // would throw UnmountedRefException.
      final container = createContainer();
      final notifier = container.read(eVSearchStateProvider.notifier);
      await notifier.searchNearby(lat: 0, lng: 0, radiusKm: 5);
      // Second call on the same notifier must not throw.
      await notifier.searchNearby(lat: 1, lng: 1, radiusKm: 5);

      final state = container.read(eVSearchStateProvider);
      expect(state, isA<AsyncError>());
    });
  });
}
