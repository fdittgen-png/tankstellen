import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/providers/ev_search_provider.dart';

import '../../fakes/fake_hive_storage.dart';

/// #697 — Spain EV search dispatch regression guard.
///
/// The EV search was reported as returning zero results when the user's
/// active profile country is Spain. The unit check here pins the
/// dispatch contract: when the active country is ES, calling
/// `EVSearchState.searchNearby(...)` must (a) resolve without throwing
/// and (b) not silently short-circuit due to a missing EV API key.
///
/// The actual OCM response is out of scope — that's tested via live
/// test under the `network` tag. This test fails loudly if the code
/// path drops the search on the floor for ES specifically.
void main() {
  test(
    'ES active country dispatches EV search with an API key set',
    () async {
      final fake = FakeHiveStorage()..hasBundledDefaultKey = false;
      await fake.setEvApiKey('test-key-abc');

      final container = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fake),
        // Force the active country to Spain so the dispatcher uses ES.
        activeCountryProvider.overrideWith(() => _FixedActiveCountry()),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(activeCountryProvider).code,
        'ES',
        reason: 'Test setup must actually put Spain as active country',
      );
      // A valid EV API key IS present — the dispatcher must not throw
      // NoEvApiKeyException here. The actual OCM call will fail in the
      // test because we have no real API, but the CODE PATH should
      // reach that point. Failing *before* the HTTP attempt means the
      // dispatch regressed.
      await container
          .read(eVSearchStateProvider.notifier)
          .searchNearby(lat: 40.4168, lng: -3.7038, radiusKm: 10);

      // State is whatever the (unreachable) OCM call produced. We only
      // care that it's no longer `loading` — i.e. the dispatcher did
      // complete its work. A regression that silently drops the ES
      // path would leave state as loading forever.
      final state = container.read(eVSearchStateProvider);
      expect(state.isLoading, isFalse,
          reason:
              'Dispatcher must not leave the state in loading — that '
              'indicates the ES EV path silently short-circuited');
    },
  );
}

class _FixedActiveCountry extends ActiveCountry {
  @override
  CountryConfig build() => Countries.spain;
}
