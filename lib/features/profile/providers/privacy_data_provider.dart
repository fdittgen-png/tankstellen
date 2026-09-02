// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/moderation/content_moderation_providers.dart';
import '../../../core/storage/storage_providers.dart';

part 'privacy_data_provider.g.dart';

/// One category of data the app keeps on the device (#3910, Epic #3907).
///
/// The kind is a stable identity for icons, labels and widget keys; the
/// count is the number of user-visible items and [bytes] the on-disk
/// estimate (exact box size where the storage layer measures it, a
/// per-entry estimate for the tiny sets it does not).
enum DeviceDataKind {
  favorites,
  ratings,
  profiles,
  alerts,
  priceHistory,
  ignoredStations,
  blockedUsers,
  itineraries,
  cache,
  settings,
}

/// Estimated bytes of one entry in the small string-set categories the
/// storage layer does not measure (ignored stations, ratings, blocked
/// users, saved routes).
const int kDeviceDataSmallEntryBytes = 64;

class DeviceDataCategory {
  final DeviceDataKind kind;

  /// Number of items; `null` for categories without a countable unit
  /// (the settings box).
  final int? count;
  final int bytes;

  const DeviceDataCategory({
    required this.kind,
    required this.count,
    required this.bytes,
  });

  /// True when the category holds nothing the user put there. Settings
  /// always exist, so that row is never "empty".
  bool get isEmpty => count != null && count == 0;
}

/// The ONE device-data inventory (#3910): every category with its count
/// AND its size, so the "Data on this device" screen and the Privacy &
/// data summary read the same numbers — the former dashboard card and
/// the storage section each carried their own copy.
class DeviceDataInventory {
  /// Categories in canonical order (favorites … settings).
  final List<DeviceDataCategory> categories;

  /// Total bytes of every measured storage box.
  final int totalBytes;

  const DeviceDataInventory({
    required this.categories,
    required this.totalBytes,
  });

  /// Non-empty categories first (canonical order kept), empty ones at
  /// the end — the list shape the inventory screen renders.
  List<DeviceDataCategory> get orderedForDisplay => [
        ...categories.where((c) => !c.isEmpty),
        ...categories.where((c) => c.isEmpty),
      ];

  int get nonEmptyCount => categories.where((c) => !c.isEmpty).length;

  DeviceDataCategory byKind(DeviceDataKind kind) =>
      categories.firstWhere((c) => c.kind == kind);
}

/// Collects the device-data inventory from the storage layer.
@riverpod
DeviceDataInventory deviceDataInventory(Ref ref) {
  final storage = ref.watch(storageRepositoryProvider);
  final blocked = ref.watch(blockedContentAuthorsProvider);
  final stats = storage.storageStats;
  final ignored = storage.getIgnoredIds().length;
  final ratings = storage.getRatings().length;
  final itineraries = storage.getItineraries().length;

  return DeviceDataInventory(
    totalBytes: stats.total,
    categories: [
      DeviceDataCategory(
        kind: DeviceDataKind.favorites,
        count: storage.favoriteCount,
        bytes: stats.favorites,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.ratings,
        count: ratings,
        bytes: ratings * kDeviceDataSmallEntryBytes,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.profiles,
        count: storage.profileCount,
        bytes: stats.profiles,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.alerts,
        count: storage.alertCount,
        bytes: stats.alerts,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.priceHistory,
        count: storage.getPriceHistoryKeys().length,
        bytes: stats.priceHistory,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.ignoredStations,
        count: ignored,
        bytes: ignored * kDeviceDataSmallEntryBytes,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.blockedUsers,
        count: blocked.length,
        bytes: blocked.length * kDeviceDataSmallEntryBytes,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.itineraries,
        count: itineraries,
        bytes: itineraries * kDeviceDataSmallEntryBytes,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.cache,
        count: storage.cacheEntryCount,
        bytes: stats.cache,
      ),
      DeviceDataCategory(
        kind: DeviceDataKind.settings,
        count: null,
        bytes: stats.settings,
      ),
    ],
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
