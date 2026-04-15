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

/// Auto-switch profile setting.
@riverpod
class AutoSwitchProfile extends _$AutoSwitchProfile {
  @override
  bool build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getSetting(StorageKeys.autoSwitchProfile) as bool? ?? false;
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

/// GDPR consent state: location, error reporting, cloud sync.
@Riverpod(keepAlive: true)
class GdprConsent extends _$GdprConsent {
  @override
  ({bool location, bool errorReporting, bool cloudSync}) build() {
    final storage = ref.watch(storageRepositoryProvider);
    return (
      location: storage.getSetting(StorageKeys.consentLocation) as bool? ?? false,
      errorReporting: storage.getSetting(StorageKeys.consentErrorReporting) as bool? ?? false,
      cloudSync: storage.getSetting(StorageKeys.consentCloudSync) as bool? ?? false,
    );
  }

  Future<void> save({
    required bool location,
    required bool errorReporting,
    required bool cloudSync,
  }) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.putSetting(StorageKeys.gdprConsentGiven, true);
    await storage.putSetting(StorageKeys.consentLocation, location);
    await storage.putSetting(StorageKeys.consentErrorReporting, errorReporting);
    await storage.putSetting(StorageKeys.consentCloudSync, cloudSync);
    // Also update the legacy location_consent key for backward compatibility
    await storage.putSetting('location_consent', location);
    state = (
      location: location,
      errorReporting: errorReporting,
      cloudSync: cloudSync,
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
