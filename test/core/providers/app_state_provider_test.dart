import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

import '../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeHiveStorage()..hasBundledDefaultKey = false;
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('hasApiKeyProvider', () {
    test('returns true when API key exists', () async {
      await fakeStorage.setApiKey('user-key');
      final c = createContainer();
      expect(c.read(hasApiKeyProvider), isTrue);
    });

    test('returns false when no API key', () {
      final c = createContainer();
      expect(c.read(hasApiKeyProvider), isFalse);
    });
  });

  group('isDemoModeProvider', () {
    test('returns true when setup skipped and no key', () async {
      await fakeStorage.skipSetup();
      final c = createContainer();
      expect(c.read(isDemoModeProvider), isTrue);
    });

    test('returns false when API key exists', () async {
      await fakeStorage.skipSetup();
      await fakeStorage.setApiKey('user-key');
      final c = createContainer();
      expect(c.read(isDemoModeProvider), isFalse);
    });
  });

  group('storageStatsProvider', () {
    test('aggregates all counts correctly', () async {
      await fakeStorage.setFavoriteIds(['a', 'b']);
      await fakeStorage.saveAlerts([
        {'id': 'a1'},
        {'id': 'a2'},
        {'id': 'a3'},
      ]);
      await fakeStorage.setIgnoredIds(['c']);
      await fakeStorage.setRating('d', 4);
      for (var i = 0; i < 10; i++) {
        await fakeStorage.cacheData('k$i', {});
      }
      await fakeStorage.savePriceRecords('s1', [
        {'a': 1},
        {'a': 2},
        {'a': 3},
        {'a': 4},
        {'a': 5},
      ]);
      await fakeStorage.saveProfile('p1', {});
      await fakeStorage.setApiKey('user-key');
      await fakeStorage.putSetting('user_position_lat', 48.0);

      final c = createContainer();
      final stats = c.read(storageStatsProvider);

      expect(stats.favoriteCount, 2);
      expect(stats.alertCount, 3);
      expect(stats.ignoredCount, 1);
      expect(stats.ratingsCount, 1);
      expect(stats.cacheEntryCount, 10);
      expect(stats.priceHistoryCount, 5);
      expect(stats.profileCount, 1);
      expect(stats.hasApiKey, isTrue);
      expect(stats.hasCustomEvKey, isFalse);
      expect(stats.hasGpsPosition, isTrue);
    });
  });

  group('MapDebugOverlay (#1316 phase 2)', () {
    test('build returns false when flag never set', () {
      final c = createContainer();
      expect(c.read(mapDebugOverlayProvider), isFalse);
    });

    test('build reflects stored true value', () async {
      await fakeStorage.putSetting(StorageKeys.mapDebugOverlayEnabled, true);
      final c = createContainer();
      expect(c.read(mapDebugOverlayProvider), isTrue);
    });

    test('enable persists true to storage and updates state', () async {
      final c = createContainer();
      await c.read(mapDebugOverlayProvider.notifier).enable();

      expect(
        fakeStorage.getSetting(StorageKeys.mapDebugOverlayEnabled),
        isTrue,
      );
      expect(c.read(mapDebugOverlayProvider), isTrue);
    });

    test('disable persists false to storage and updates state', () async {
      await fakeStorage.putSetting(StorageKeys.mapDebugOverlayEnabled, true);
      final c = createContainer();
      expect(c.read(mapDebugOverlayProvider), isTrue);

      await c.read(mapDebugOverlayProvider.notifier).disable();
      expect(
        fakeStorage.getSetting(StorageKeys.mapDebugOverlayEnabled),
        isFalse,
      );
      expect(c.read(mapDebugOverlayProvider), isFalse);
    });

    test('toggle flips false→true→false across calls', () async {
      final c = createContainer();
      expect(c.read(mapDebugOverlayProvider), isFalse);

      await c.read(mapDebugOverlayProvider.notifier).toggle();
      expect(c.read(mapDebugOverlayProvider), isTrue);
      expect(
        fakeStorage.getSetting(StorageKeys.mapDebugOverlayEnabled),
        isTrue,
      );

      await c.read(mapDebugOverlayProvider.notifier).toggle();
      expect(c.read(mapDebugOverlayProvider), isFalse);
      expect(
        fakeStorage.getSetting(StorageKeys.mapDebugOverlayEnabled),
        isFalse,
      );
    });
  });

  group('Obd2DebugOverlay (#1395)', () {
    test('build returns false when flag never set', () {
      final c = createContainer();
      expect(c.read(obd2DebugOverlayProvider), isFalse);
    });

    test('build reflects stored true value', () async {
      await fakeStorage.putSetting(StorageKeys.obd2DebugOverlayEnabled, true);
      final c = createContainer();
      expect(c.read(obd2DebugOverlayProvider), isTrue);
    });

    test('enable persists true to storage and updates state', () async {
      final c = createContainer();
      await c.read(obd2DebugOverlayProvider.notifier).enable();

      expect(
        fakeStorage.getSetting(StorageKeys.obd2DebugOverlayEnabled),
        isTrue,
      );
      expect(c.read(obd2DebugOverlayProvider), isTrue);
    });

    test('disable persists false to storage and updates state', () async {
      await fakeStorage.putSetting(StorageKeys.obd2DebugOverlayEnabled, true);
      final c = createContainer();
      expect(c.read(obd2DebugOverlayProvider), isTrue);

      await c.read(obd2DebugOverlayProvider.notifier).disable();
      expect(
        fakeStorage.getSetting(StorageKeys.obd2DebugOverlayEnabled),
        isFalse,
      );
      expect(c.read(obd2DebugOverlayProvider), isFalse);
    });

    test('toggle flips false→true→false across calls', () async {
      final c = createContainer();
      expect(c.read(obd2DebugOverlayProvider), isFalse);

      await c.read(obd2DebugOverlayProvider.notifier).toggle();
      expect(c.read(obd2DebugOverlayProvider), isTrue);
      expect(
        fakeStorage.getSetting(StorageKeys.obd2DebugOverlayEnabled),
        isTrue,
      );

      await c.read(obd2DebugOverlayProvider.notifier).toggle();
      expect(c.read(obd2DebugOverlayProvider), isFalse);
      expect(
        fakeStorage.getSetting(StorageKeys.obd2DebugOverlayEnabled),
        isFalse,
      );
    });
  });

  group('LocationConsent', () {
    test('build returns false when no consent', () {
      final c = createContainer();
      expect(c.read(locationConsentProvider), isFalse);
    });

    test('build returns true when consent given', () async {
      await fakeStorage.putSetting('location_consent', true);
      final c = createContainer();
      expect(c.read(locationConsentProvider), isTrue);
    });

    test('grant saves consent to storage', () async {
      final c = createContainer();
      await c.read(locationConsentProvider.notifier).grant();

      expect(fakeStorage.getSetting('location_consent'), true);
      expect(c.read(locationConsentProvider), isTrue);
    });
  });

  group('hasGdprConsent', () {
    test('returns false when no consent given', () {
      final c = createContainer();
      expect(c.read(hasGdprConsentProvider), isFalse);
    });

    test('returns true when consent given', () async {
      await fakeStorage.putSetting(StorageKeys.gdprConsentGiven, true);
      final c = createContainer();
      expect(c.read(hasGdprConsentProvider), isTrue);
    });
  });

  group('GdprConsent', () {
    test('build returns all false when no consent saved', () {
      final c = createContainer();
      final state = c.read(gdprConsentProvider);
      expect(state.location, isFalse);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isFalse);
      expect(state.communityWaitTime, isFalse);
      expect(state.vinOnlineDecode, isFalse);
    });

    test('build reflects stored values', () async {
      await fakeStorage.putSetting(StorageKeys.consentLocation, true);
      await fakeStorage.putSetting(StorageKeys.consentErrorReporting, false);
      await fakeStorage.putSetting(StorageKeys.consentCloudSync, true);
      await fakeStorage.putSetting(
          StorageKeys.consentCommunityWaitTime, true);
      await fakeStorage.putSetting(
          StorageKeys.consentVinOnlineDecode, true);

      final c = createContainer();
      final state = c.read(gdprConsentProvider);
      expect(state.location, isTrue);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isTrue);
      expect(state.communityWaitTime, isTrue);
      expect(state.vinOnlineDecode, isTrue);
    });

    test('save persists all consent values and sets gdprConsentGiven',
        () async {
      final c = createContainer();
      await c.read(gdprConsentProvider.notifier).save(
            location: true,
            errorReporting: false,
            cloudSync: true,
            communityWaitTime: true,
            vinOnlineDecode: true,
          );

      expect(fakeStorage.getSetting(StorageKeys.gdprConsentGiven), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), true);
      expect(fakeStorage.getSetting(StorageKeys.consentErrorReporting), false);
      expect(fakeStorage.getSetting(StorageKeys.consentCloudSync), true);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), true);
      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), true);
      // Also updates legacy location_consent key
      expect(fakeStorage.getSetting('location_consent'), true);

      final state = c.read(gdprConsentProvider);
      expect(state.location, isTrue);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isTrue);
      expect(state.communityWaitTime, isTrue);
      expect(state.vinOnlineDecode, isTrue);
    });

    test('save can persist communityWaitTime independently of others',
        () async {
      final c = createContainer();
      await c.read(gdprConsentProvider.notifier).save(
            location: false,
            errorReporting: false,
            cloudSync: false,
            communityWaitTime: true,
            vinOnlineDecode: false,
          );

      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), false);
      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), false);

      final state = c.read(gdprConsentProvider);
      expect(state.communityWaitTime, isTrue);
      expect(state.location, isFalse);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isFalse);
      expect(state.vinOnlineDecode, isFalse);
    });

    test('save can persist vinOnlineDecode independently of others (#1399)',
        () async {
      final c = createContainer();
      await c.read(gdprConsentProvider.notifier).save(
            location: false,
            errorReporting: false,
            cloudSync: false,
            communityWaitTime: false,
            vinOnlineDecode: true,
          );

      expect(
          fakeStorage.getSetting(StorageKeys.consentVinOnlineDecode), true);
      expect(fakeStorage.getSetting(StorageKeys.consentLocation), false);
      expect(
          fakeStorage.getSetting(StorageKeys.consentCommunityWaitTime), false);

      final state = c.read(gdprConsentProvider);
      expect(state.vinOnlineDecode, isTrue);
      expect(state.location, isFalse);
      expect(state.communityWaitTime, isFalse);
    });
  });
}
