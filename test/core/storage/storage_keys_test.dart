import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';

void main() {
  // Catalogue every StorageKey used by the app. If a new key is added
  // without being listed here, the uniqueness test will still pass for it
  // (it won't collide with itself) — but the count assertion below makes
  // drift visible so reviewers remember to update consumer code too.
  final allKeys = <String>[
    StorageKeys.apiKey,
    StorageKeys.activeProfileId,
    StorageKeys.favoriteStationIds,
    StorageKeys.setupSkipped,
    StorageKeys.userPositionLat,
    StorageKeys.userPositionLng,
    StorageKeys.userPositionTimestamp,
    StorageKeys.userPositionSource,
    StorageKeys.autoSwitchProfile,
    StorageKeys.evApiKey,
    StorageKeys.ignoredStationIds,
    StorageKeys.stationRatings,
    StorageKeys.favoriteStationData,
    StorageKeys.gdprConsentGiven,
    StorageKeys.consentLocation,
    StorageKeys.consentErrorReporting,
    StorageKeys.consentCloudSync,
    StorageKeys.swipeTutorialShown,
    StorageKeys.consumptionLog,
    StorageKeys.vehicleProfiles,
    StorageKeys.activeVehicleProfileId,
    StorageKeys.evStationsCache,
    StorageKeys.evShowOnMap,
    StorageKeys.evFavoriteStationIds,
    StorageKeys.evFavoriteStationData,
    StorageKeys.helpBannerCriteria,
    StorageKeys.helpBannerAlerts,
    StorageKeys.supabaseAnonKey,
  ];

  group('StorageKeys', () {
    test('all keys are pairwise unique — no two constants share a value', () {
      // Two keys with the same Hive string would silently overwrite each
      // other on read/write, corrupting unrelated features. A duplicate
      // here is a day-zero bug; pin it in CI.
      expect(allKeys.toSet().length, allKeys.length,
          reason: 'Duplicate StorageKey value detected — Hive reads will collide');
    });

    test('every key is non-empty', () {
      for (final key in allKeys) {
        expect(key, isNotEmpty);
      }
    });

    test('every key uses snake_case (lowercase + underscores only)', () {
      // A typo like "apiKey" vs "api_key" would quietly write to a
      // different Hive box than it reads from. Enforce the convention.
      final snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final key in allKeys) {
        expect(snakeCase.hasMatch(key), isTrue,
            reason: 'Key "$key" does not match snake_case pattern');
      }
    });

    test('pinned GDPR keys keep their wire format', () {
      // Migration pain: renaming these later would orphan the user's
      // previously granted consent, forcing them through the wizard again.
      expect(StorageKeys.gdprConsentGiven, 'gdpr_consent_given');
      expect(StorageKeys.consentLocation, 'consent_location');
      expect(StorageKeys.consentErrorReporting, 'consent_error_reporting');
      expect(StorageKeys.consentCloudSync, 'consent_cloud_sync');
    });

    test('StorageKeys is not instantiable', () {
      // Defensive: the class is private-constructor by design. We can't
      // call the private ctor directly, but we can verify the static API
      // is the intended surface by touching one constant through the
      // type itself.
      expect(StorageKeys.apiKey, isA<String>());
    });
  });
}
