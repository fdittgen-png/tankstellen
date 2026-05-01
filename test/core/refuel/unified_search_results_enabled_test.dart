import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/refuel/unified_search_results_enabled.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

/// Coverage for the #1116 phase 3a feature flag.
///
/// Mirrors the [EvShowOnMap] test pattern in
/// `test/features/ev/providers/ev_providers_test.dart` — a fake in-memory
/// [SettingsStorage] is overridden into the container so reads + writes
/// stay deterministic without a Hive box.
void main() {
  group('unifiedSearchResultsEnabledProvider', () {
    test('defaults to false on a fresh storage', () {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
    });

    test(
      'reads persisted true value when storage already holds the flag',
      () {
        final storage = _FakeSettings()
          ..putSetting(StorageKeys.unifiedSearchResultsEnabled, true);
        final container = ProviderContainer(
          overrides: [settingsStorageProvider.overrideWithValue(storage)],
        );
        addTearDown(container.dispose);

        expect(container.read(unifiedSearchResultsEnabledProvider), isTrue);
      },
    );

    test('non-bool persisted value falls back to false', () {
      // Defensive: previous app versions or hand-edited Hive boxes may
      // store the wrong type. The provider must not throw.
      final storage = _FakeSettings()
        ..putSetting(StorageKeys.unifiedSearchResultsEnabled, 'yes');
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
    });

    test('toggle flips state and persists the new value', () async {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .toggle();

      expect(container.read(unifiedSearchResultsEnabledProvider), isTrue);
      expect(
        storage.getSetting(StorageKeys.unifiedSearchResultsEnabled),
        isTrue,
      );

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .toggle();

      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
      expect(
        storage.getSetting(StorageKeys.unifiedSearchResultsEnabled),
        isFalse,
      );
    });

    test('set(value) writes through and updates state', () async {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(true);
      expect(container.read(unifiedSearchResultsEnabledProvider), isTrue);
      expect(
        storage.getSetting(StorageKeys.unifiedSearchResultsEnabled),
        isTrue,
      );

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(false);
      expect(container.read(unifiedSearchResultsEnabledProvider), isFalse);
      expect(
        storage.getSetting(StorageKeys.unifiedSearchResultsEnabled),
        isFalse,
      );
    });

    test('set(true) is idempotent — repeated writes keep state at true',
        () async {
      final storage = _FakeSettings();
      final container = ProviderContainer(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(true);
      await container
          .read(unifiedSearchResultsEnabledProvider.notifier)
          .set(true);
      expect(container.read(unifiedSearchResultsEnabledProvider), isTrue);
    });
  });
}

class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
