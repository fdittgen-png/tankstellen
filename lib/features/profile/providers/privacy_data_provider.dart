import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_provider.dart';

part 'privacy_data_provider.g.dart';

/// Snapshot of all locally stored user data for the privacy dashboard.
///
/// Each field represents a distinct data category that the user
/// can inspect before deciding to export or delete.
class PrivacyDataSnapshot {
  final int favoritesCount;
  final int ignoredCount;
  final int ratingsCount;
  final int alertsCount;
  final int priceHistoryStationCount;
  final int profileCount;
  final int cacheEntryCount;
  final int itineraryCount;
  final bool hasApiKey;
  final bool hasEvApiKey;
  final bool syncEnabled;
  final String? syncMode;
  final String? syncUserId;
  final int estimatedTotalBytes;

  const PrivacyDataSnapshot({
    required this.favoritesCount,
    required this.ignoredCount,
    required this.ratingsCount,
    required this.alertsCount,
    required this.priceHistoryStationCount,
    required this.profileCount,
    required this.cacheEntryCount,
    required this.itineraryCount,
    required this.hasApiKey,
    required this.hasEvApiKey,
    required this.syncEnabled,
    required this.syncMode,
    required this.syncUserId,
    required this.estimatedTotalBytes,
  });
}

/// Collects a snapshot of all locally stored user data.
@riverpod
PrivacyDataSnapshot privacyData(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final syncConfig = ref.watch(syncStateProvider);
  final stats = storage.storageStats;

  return PrivacyDataSnapshot(
    favoritesCount: storage.favoriteCount,
    ignoredCount: storage.getIgnoredIds().length,
    ratingsCount: storage.getRatings().length,
    alertsCount: storage.alertCount,
    priceHistoryStationCount: storage.getPriceHistoryKeys().length,
    profileCount: storage.profileCount,
    cacheEntryCount: storage.cacheEntryCount,
    itineraryCount: storage.getItineraries().length,
    hasApiKey: storage.hasApiKey(),
    hasEvApiKey: storage.hasEvApiKey(),
    syncEnabled: syncConfig.enabled,
    syncMode: syncConfig.enabled ? syncConfig.modeName : null,
    syncUserId: syncConfig.userId,
    estimatedTotalBytes: stats.total,
  );
}

/// Exports all user data as a JSON string for GDPR data portability.
///
/// Excludes API keys for security — the user re-enters those on import.
/// Excludes cache data because it is ephemeral and reconstructable.
@riverpod
String exportPrivacyData(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);

  final export = <String, dynamic>{
    'exportedAt': DateTime.now().toIso8601String(),
    'appVersion': '4.1.0',
    'favorites': storage.getFavoriteIds(),
    'favoriteStationData': storage.getAllFavoriteStationData(),
    'ignoredStations': storage.getIgnoredIds(),
    'ratings': storage.getRatings().map((k, v) => MapEntry(k, v)),
    'profiles': storage.getAllProfiles(),
    'alerts': storage.getAlerts(),
    'itineraries': storage.getItineraries(),
    'priceHistory': _exportPriceHistory(storage),
  };

  return const JsonEncoder.withIndent('  ').convert(export);
}

Map<String, dynamic> _exportPriceHistory(StorageRepository storage) {
  final result = <String, dynamic>{};
  for (final key in storage.getPriceHistoryKeys()) {
    result[key] = storage.getPriceRecords(key);
  }
  return result;
}
