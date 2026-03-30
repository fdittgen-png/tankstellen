import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/hive_storage.dart';
import '../storage/storage_keys.dart';

part 'app_state_provider.g.dart';

/// Whether the Tankerkoenig API key is configured.
@riverpod
bool hasApiKey(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.hasApiKey();
}

/// Whether a custom EV API key is configured.
@riverpod
bool hasCustomEvApiKey(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.hasCustomEvApiKey();
}

/// Whether the app setup (API key or skip) is complete.
@riverpod
bool isSetupComplete(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.isSetupComplete;
}

/// Whether the app is in demo mode (setup skipped, no API key).
@riverpod
bool isDemoMode(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.isSetupSkipped && !storage.hasApiKey();
}

/// Whether location consent has been given.
@riverpod
bool hasLocationConsent(Ref ref) {
  final storage = ref.watch(hiveStorageProvider);
  return storage.getSetting('location_consent') == true;
}

/// Record location consent.
@riverpod
class LocationConsent extends _$LocationConsent {
  @override
  bool build() {
    final storage = ref.watch(hiveStorageProvider);
    return storage.getSetting('location_consent') == true;
  }

  Future<void> grant() async {
    final storage = ref.read(hiveStorageProvider);
    await storage.putSetting('location_consent', true);
    state = true;
  }
}

/// Auto-switch profile setting.
@riverpod
class AutoSwitchProfile extends _$AutoSwitchProfile {
  @override
  bool build() {
    final storage = ref.watch(hiveStorageProvider);
    return storage.getSetting(StorageKeys.autoSwitchProfile) as bool? ?? false;
  }

  Future<void> set(bool value) async {
    final storage = ref.read(hiveStorageProvider);
    await storage.putSetting(StorageKeys.autoSwitchProfile, value);
    state = value;
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
  final storage = ref.watch(hiveStorageProvider);
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
