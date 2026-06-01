// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';

part 'app_state_provider.g.dart';

/// Whether the Tankerkoenig API key is configured.
///
/// Since #521 this is always true — the app ships a community
/// default. Use [hasCustomApiKey] to tell whether the user set their
/// own key.
@riverpod
bool hasApiKey(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.hasApiKey();
}

/// Whether the user has set their **own** Tankerkoenig key, distinct
/// from the community default bundled in the app (#521).
@riverpod
bool hasCustomApiKey(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.hasCustomApiKey();
}

/// Whether a custom EV API key is configured.
@riverpod
bool hasCustomEvApiKey(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.hasCustomEvApiKey();
}

/// Whether the app setup (API key or skip) is complete.
@riverpod
bool isSetupComplete(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.isSetupComplete;
}

/// Whether the app is in demo mode (setup skipped, no API key).
@riverpod
bool isDemoMode(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.isSetupSkipped && !storage.hasApiKey();
}

/// Whether location consent has been given.
@riverpod
bool hasLocationConsent(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.getSetting('location_consent') == true;
}

/// Record location consent.
@riverpod
class LocationConsent extends _$LocationConsent {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getSetting('location_consent') == true;
  }

  Future<void> grant() async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting('location_consent', true);
    state = true;
  }
}

/// In-app OBD2 fuel-rate diagnostic overlay flag (#1395).
///
/// `kDebugMode` always shows the overlay; this Hive-backed flag flips
/// it on for release builds when the user enables it via the hidden
/// 5-tap gesture on the trip-recording screen title. Persisted so the
/// overlay stays visible across launches once the user has opted in.
@riverpod
class Obd2DebugOverlay extends _$Obd2DebugOverlay {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getSetting(StorageKeys.obd2DebugOverlayEnabled) as bool? ??
        false;
  }

  Future<void> enable() => _set(true);
  Future<void> disable() => _set(false);
  Future<void> toggle() => _set(!state);

  Future<void> _set(bool value) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.obd2DebugOverlayEnabled, value);
    state = value;
  }
}

/// Auto-switch profile setting.
@riverpod
class AutoSwitchProfile extends _$AutoSwitchProfile {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    // #2597 — default ON so border-crossing auto-activates the country's
    // profile out of the box; the Settings toggle persists an explicit
    // `false` to opt out.
    return storage.getSetting(StorageKeys.autoSwitchProfile) as bool? ?? true;
  }

  Future<void> set(bool value) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.autoSwitchProfile, value);
    state = value;
  }
}

/// Whether GDPR consent has been given (any choices made).
@riverpod
bool hasGdprConsent(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return storage.getSetting(StorageKeys.gdprConsentGiven) == true;
}

/// GDPR consent state: location, error reporting, cloud sync,
/// community wait-time pings (#1119), VIN online decode (#1399),
/// trip-sync to TankSync (#1479 phase 1).
@Riverpod(keepAlive: true)
class GdprConsent extends _$GdprConsent {
  @override
  ({
    bool location,
    bool errorReporting,
    bool cloudSync,
    bool vinOnlineDecode,
    bool syncTrips,
  }) build() {
    final storage = ref.watch(storageRepositoryProvider);
    return (
      location: storage.getSetting(StorageKeys.consentLocation) as bool? ?? false,
      errorReporting: storage.getSetting(StorageKeys.consentErrorReporting) as bool? ?? false,
      cloudSync: storage.getSetting(StorageKeys.consentCloudSync) as bool? ?? false,
      vinOnlineDecode:
          storage.getSetting(StorageKeys.consentVinOnlineDecode) as bool? ?? false,
      syncTrips:
          storage.getSetting(StorageKeys.consentSyncTrips) as bool? ?? false,
    );
  }

  Future<void> save({
    required bool location,
    required bool errorReporting,
    required bool cloudSync,
    required bool vinOnlineDecode,
    bool syncTrips = false,
  }) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.gdprConsentGiven, true);
    await storage.putSetting(StorageKeys.consentLocation, location);
    await storage.putSetting(StorageKeys.consentErrorReporting, errorReporting);
    await storage.putSetting(StorageKeys.consentCloudSync, cloudSync);
    await storage.putSetting(
      StorageKeys.consentVinOnlineDecode,
      vinOnlineDecode,
    );
    // #1479 — trip-sync consent gates the trip → cloud upload path.
    // Force off when the master cloudSync consent is off so a stale
    // syncTrips=true value can't ride past a cloudSync=false toggle.
    final effectiveSyncTrips = cloudSync ? syncTrips : false;
    await storage.putSetting(
      StorageKeys.consentSyncTrips,
      effectiveSyncTrips,
    );
    // Also update the legacy location_consent key for backward compatibility
    await storage.putSetting('location_consent', location);
    state = (
      location: location,
      errorReporting: errorReporting,
      cloudSync: cloudSync,
      vinOnlineDecode: vinOnlineDecode,
      syncTrips: effectiveSyncTrips,
    );
  }
}

/// Storage statistics for the settings page.
class StorageStats {
  final int favoriteCount;
  final int alertCount;
  final int ignoredCount;
  final int ratingsCount;
  final int cacheEntryCount;
  final int priceHistoryCount;
  final int profileCount;
  final bool hasGpsPosition;
  final bool hasApiKey;
  final bool hasCustomEvKey;

  const StorageStats({
    this.favoriteCount = 0,
    this.alertCount = 0,
    this.ignoredCount = 0,
    this.ratingsCount = 0,
    this.cacheEntryCount = 0,
    this.priceHistoryCount = 0,
    this.profileCount = 0,
    this.hasGpsPosition = false,
    this.hasApiKey = false,
    this.hasCustomEvKey = false,
  });
}

/// Aggregated storage stats — used by config verification and storage section.
@riverpod
StorageStats storageStats(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  return StorageStats(
    favoriteCount: storage.getFavoriteIds().length,
    alertCount: storage.alertCount,
    ignoredCount: storage.getIgnoredIds().length,
    ratingsCount: storage.getRatings().length,
    cacheEntryCount: storage.cacheEntryCount,
    priceHistoryCount: storage.priceHistoryEntryCount,
    profileCount: storage.profileCount,
    hasGpsPosition: storage.getSetting('user_position_lat') != null,
    hasApiKey: storage.hasApiKey(),
    hasCustomEvKey: storage.hasCustomEvApiKey(),
  );
}
