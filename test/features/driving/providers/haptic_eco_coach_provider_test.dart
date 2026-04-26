import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';

/// Provider-layer coverage for the [hapticEcoCoachEnabledProvider]
/// (#1122).
///
/// We pump a fake [SettingsStorage] in for two reasons:
///   1. Avoid spinning up Hive — the provider's contract is "read on
///      build, write on `set`", which is fully exercised against an
///      in-memory map without any persistence machinery.
///   2. Pin the default-OFF behaviour explicitly: a fresh storage
///      with no `hapticEcoCoachEnabled` key must yield `false`. The
///      issue (#1122) is opt-in by design — a regression here would
///      buzz every user on update.
void main() {
  group('hapticEcoCoachEnabledProvider', () {
    test('defaults to false when the setting has never been written', () {
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(_FakeSettingsStorage()),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isFalse,
        reason:
            'Default-OFF is the contract: a user who never toggles the '
            'switch must not get haptic nudges.',
      );
    });

    test('reads the persisted value on build', () {
      final fake = _FakeSettingsStorage()
        ..data[StorageKeys.hapticEcoCoachEnabled] = true;
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isTrue,
        reason:
            'Persisted-true must surface as true on first read so the '
            'lifecycle provider can immediately spin up the coach.',
      );
    });

    test('set(true) writes the canonical key and updates state', () async {
      final fake = _FakeSettingsStorage();
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      // Force the provider to materialise so subsequent reads after
      // `set` go through the in-memory state path, not a fresh build.
      container.read(hapticEcoCoachEnabledProvider);
      await container
          .read(hapticEcoCoachEnabledProvider.notifier)
          .set(true);

      expect(
        fake.data[StorageKeys.hapticEcoCoachEnabled],
        isTrue,
        reason:
            'set(true) must persist to the canonical storage key so a '
            'restart preserves the user\'s choice.',
      );
      expect(
        container.read(hapticEcoCoachEnabledProvider),
        isTrue,
        reason:
            'set(true) must update state in-place — the lifecycle provider '
            'is watching, and a stale value would defer the haptic ramp-up '
            'until the next provider invalidation.',
      );
    });

    test('set(false) flips state back to false', () async {
      final fake = _FakeSettingsStorage()
        ..data[StorageKeys.hapticEcoCoachEnabled] = true;
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      container.read(hapticEcoCoachEnabledProvider);
      await container
          .read(hapticEcoCoachEnabledProvider.notifier)
          .set(false);

      expect(fake.data[StorageKeys.hapticEcoCoachEnabled], isFalse);
      expect(container.read(hapticEcoCoachEnabledProvider), isFalse);
    });
  });
}

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
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
