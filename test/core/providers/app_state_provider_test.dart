import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/providers/app_state_provider.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockHiveStorage mockStorage;

  setUp(() {
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getSetting(any())).thenReturn(null);
  });

  ProviderContainer createContainer() {
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(mockStorage),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('hasApiKeyProvider', () {
    test('returns true when API key exists', () {
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      final c = createContainer();
      expect(c.read(hasApiKeyProvider), isTrue);
    });

    test('returns false when no API key', () {
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      final c = createContainer();
      expect(c.read(hasApiKeyProvider), isFalse);
    });
  });

  group('isDemoModeProvider', () {
    test('returns true when setup skipped and no key', () {
      when(() => mockStorage.isSetupSkipped).thenReturn(true);
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      final c = createContainer();
      expect(c.read(isDemoModeProvider), isTrue);
    });

    test('returns false when API key exists', () {
      when(() => mockStorage.isSetupSkipped).thenReturn(true);
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      final c = createContainer();
      expect(c.read(isDemoModeProvider), isFalse);
    });
  });

  group('storageStatsProvider', () {
    test('aggregates all counts correctly', () {
      when(() => mockStorage.getFavoriteIds()).thenReturn(['a', 'b']);
      when(() => mockStorage.alertCount).thenReturn(3);
      when(() => mockStorage.getIgnoredIds()).thenReturn(['c']);
      when(() => mockStorage.getRatings()).thenReturn({'d': 4});
      when(() => mockStorage.cacheEntryCount).thenReturn(10);
      when(() => mockStorage.priceHistoryEntryCount).thenReturn(5);
      when(() => mockStorage.profileCount).thenReturn(1);
      when(() => mockStorage.hasApiKey()).thenReturn(true);
      when(() => mockStorage.hasCustomEvApiKey()).thenReturn(false);
      when(() => mockStorage.getSetting('user_position_lat')).thenReturn(48.0);

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

  group('LocationConsent', () {
    test('build returns false when no consent', () {
      when(() => mockStorage.getSetting('location_consent')).thenReturn(null);
      final c = createContainer();
      expect(c.read(locationConsentProvider), isFalse);
    });

    test('build returns true when consent given', () {
      when(() => mockStorage.getSetting('location_consent')).thenReturn(true);
      final c = createContainer();
      expect(c.read(locationConsentProvider), isTrue);
    });

    test('grant saves consent to storage', () async {
      when(() => mockStorage.getSetting('location_consent')).thenReturn(false);
      when(() => mockStorage.putSetting(any(), any())).thenAnswer((_) async {});

      final c = createContainer();
      await c.read(locationConsentProvider.notifier).grant();

      verify(() => mockStorage.putSetting('location_consent', true)).called(1);
      expect(c.read(locationConsentProvider), isTrue);
    });
  });

  group('hasGdprConsent', () {
    test('returns false when no consent given', () {
      when(() => mockStorage.getSetting(StorageKeys.gdprConsentGiven))
          .thenReturn(null);
      final c = createContainer();
      expect(c.read(hasGdprConsentProvider), isFalse);
    });

    test('returns true when consent given', () {
      when(() => mockStorage.getSetting(StorageKeys.gdprConsentGiven))
          .thenReturn(true);
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
    });

    test('build reflects stored values', () {
      when(() => mockStorage.getSetting(StorageKeys.consentLocation))
          .thenReturn(true);
      when(() => mockStorage.getSetting(StorageKeys.consentErrorReporting))
          .thenReturn(false);
      when(() => mockStorage.getSetting(StorageKeys.consentCloudSync))
          .thenReturn(true);

      final c = createContainer();
      final state = c.read(gdprConsentProvider);
      expect(state.location, isTrue);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isTrue);
    });

    test('save persists all consent values and sets gdprConsentGiven',
        () async {
      when(() => mockStorage.putSetting(any(), any()))
          .thenAnswer((_) async {});

      final c = createContainer();
      await c.read(gdprConsentProvider.notifier).save(
            location: true,
            errorReporting: false,
            cloudSync: true,
          );

      verify(() =>
              mockStorage.putSetting(StorageKeys.gdprConsentGiven, true))
          .called(1);
      verify(() =>
              mockStorage.putSetting(StorageKeys.consentLocation, true))
          .called(1);
      verify(() => mockStorage.putSetting(
              StorageKeys.consentErrorReporting, false))
          .called(1);
      verify(() =>
              mockStorage.putSetting(StorageKeys.consentCloudSync, true))
          .called(1);
      // Also updates legacy location_consent key
      verify(() => mockStorage.putSetting('location_consent', true))
          .called(1);

      final state = c.read(gdprConsentProvider);
      expect(state.location, isTrue);
      expect(state.errorReporting, isFalse);
      expect(state.cloudSync, isTrue);
    });
  });
}
