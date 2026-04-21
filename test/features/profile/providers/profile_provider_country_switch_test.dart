import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

/// Regression tests for #753 — tapping a home-screen widget row opened
/// the wrong station. One confirmed vector: after a country switch, the
/// previous country's search cache remained live. `stationDetailProvider`
/// prefers the search-state cache over the API, so a colliding numeric
/// station id (e.g. `75001` in France vs Tankerkönig) would return the
/// wrong station's detail.
///
/// The fix: `ActiveProfile.switchProfile` invalidates `searchStateProvider`
/// whenever the new profile's country differs from the previous one.
/// These tests lock the behavior so a future refactor cannot silently
/// reintroduce the regression.
void main() {
  group('ActiveProfile.switchProfile — country-change invalidation (#753)',
      () {
    test('cross-country switch invalidates searchStateProvider', () async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      final de = await repo.createProfile(name: 'DE', countryCode: 'DE');
      final fr = await repo.createProfile(name: 'FR', countryCode: 'FR');
      await repo.setActiveProfile(de.id);

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      // Capture initial state so we can prove the provider was rebuilt
      // (identity changes on rebuild; ref.invalidate disposes + re-runs build).
      final before = container.read(searchStateProvider);

      await container
          .read(activeProfileProvider.notifier)
          .switchProfile(fr.id);
      await Future.microtask(() {});

      final after = container.read(searchStateProvider);
      expect(container.read(activeProfileProvider)?.countryCode, 'FR');
      expect(
        identical(before, after),
        isFalse,
        reason:
            'switchProfile from DE to FR must invalidate searchStateProvider '
            '(a rebuilt AsyncValue is a different instance)',
      );
    });

    test('same-country switch does NOT invalidate searchStateProvider',
        () async {
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      final de1 = await repo.createProfile(name: 'DE1', countryCode: 'DE');
      final de2 = await repo.createProfile(name: 'DE2', countryCode: 'DE');
      await repo.setActiveProfile(de1.id);

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final before = container.read(searchStateProvider);

      await container
          .read(activeProfileProvider.notifier)
          .switchProfile(de2.id);
      await Future.microtask(() {});

      final after = container.read(searchStateProvider);
      expect(container.read(activeProfileProvider)?.id, de2.id);
      expect(
        identical(before, after),
        isTrue,
        reason:
            'same-country switch must preserve searchStateProvider — '
            'invalidating here would discard the user\'s in-flight search',
      );
    });

    test('first-ever switch (no previous country) does not invalidate',
        () async {
      // Scenario: fresh install, first profile has no countryCode set yet.
      // switchProfile to a profile with a country should NOT invalidate
      // (there is no stale cross-country cache to protect against).
      final storage = _InMemoryHiveStorage();
      final repo = ProfileRepository(storage);
      final noCountry = await repo.createProfile(name: 'Nameless');
      final de = await repo.createProfile(name: 'DE', countryCode: 'DE');
      await repo.setActiveProfile(noCountry.id);

      final container = ProviderContainer(overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final before = container.read(searchStateProvider);

      await container
          .read(activeProfileProvider.notifier)
          .switchProfile(de.id);
      await Future.microtask(() {});

      final after = container.read(searchStateProvider);
      expect(
        identical(before, after),
        isTrue,
        reason:
            'switching from a no-country profile should not invalidate — '
            'there is no previous country whose cache could pollute',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// In-memory HiveStorage fake — mirrors the fake used in profile_provider_test.
// Re-declared here so the two test files stay independently runnable.
// ---------------------------------------------------------------------------

class _InMemoryHiveStorage extends Mock implements HiveStorage {
  final Map<String, Map<String, dynamic>> _profiles = {};
  String? _activeProfileId;
  final Map<String, dynamic> _settings = {};

  @override
  String? getActiveProfileId() => _activeProfileId;

  @override
  Future<void> setActiveProfileId(String id) async {
    _activeProfileId = id;
  }

  @override
  Map<String, dynamic>? getProfile(String id) {
    final data = _profiles[id];
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  List<Map<String, dynamic>> getAllProfiles() {
    return _profiles.values
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    _profiles[id] = Map<String, dynamic>.from(profile);
  }

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.remove(id);
  }

  @override
  int get profileCount => _profiles.length;

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    _settings[key] = value;
  }
}
