// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../../logging/app_log.dart';
import '../../logging/error_logger.dart';
import '../hive_boxes.dart';
import '../hive_map_coercion.dart';
import '../storage_keys.dart';

/// Hive round-trips deeply nested maps as `Map<dynamic, dynamic>` / `List<dynamic>`
/// even when the original write was strongly typed. When those payloads are
/// handed back to freezed's fromJson (which expects `Map<String, dynamic>`
/// for every nested object), the cast fails and the station silently drops
/// out of the favorites list (#690). Use the shared deep-converter so every
/// level matches what fromJson demands.

/// Hive-backed implementation of [FavoriteStorage] and [IgnoredStorage].
///
/// Manages favorite station IDs, persisted station data for offline access,
/// ignored station IDs, and station ratings.
///
/// ## A closed box is a no-op, never a throw (#4190)
///
/// This store is reached from fire-and-forget paths — the home-widget
/// refresh is the one that found this — which can outlive the moment the
/// boxes close. `Hive.box()` THROWS on a closed box, and this was the
/// only such store that let it: `BackgroundScanDedupStore`,
/// `RadiusAlertDedup`, `BudgetStateStore` and `OpportunityFeedStore` all
/// reach their box through a nullable accessor and degrade.
///
/// The asymmetry surfaced as a test that fails only in a full local run
/// (a late widget refresh reading after teardown) and is invisible to
/// CI, whose four shards never produce that interleaving. In production
/// the same throw is swallowed by a caller's guard — but a store whose
/// contract is "readable from a background path" should not need one.
///
/// Reads return their empty value; writes drop with a log. Neither ever
/// throws.
class FavoritesHiveStore
    implements FavoriteStorage, EvFavoriteStorage, IgnoredStorage, RatingStorage {
  /// The favorites box, or null when it is not open.
  ///
  /// Null is a real answer here, not a failure to handle: after the app
  /// closes its boxes there is nothing to read and nothing to write, and
  /// saying so is cheaper than every caller owning a guard.
  Box<dynamic>? get _boxOrNull {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.favorites)) return null;
      return Hive.box(HiveBoxes.favorites);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'FavoritesHiveStore: favorites box unavailable',
      });
      return null;
    }
  }

  /// Read one key, or null when the box is closed.
  Object? _get(String key) => _boxOrNull?.get(key);

  /// Write one key; a closed box drops the write with a log.
  Future<void> _put(String key, Object? value) async {
    final box = _boxOrNull;
    if (box == null) {
      log.debug('put skipped, favorites box closed ($key)',
          tag: 'FavoritesHiveStore');
      return;
    }
    await box.put(key, value);
  }

  // Favorites
  @override
  List<String> getFavoriteIds() {
    final ids = _get(StorageKeys.favoriteStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setFavoriteIds(List<String> ids) =>
      _put(StorageKeys.favoriteStationIds, ids);

  @override
  Future<void> addFavorite(String id) async {
    final ids = getFavoriteIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await setFavoriteIds(ids);
    }
  }

  @override
  Future<void> removeFavorite(String id) async {
    final ids = getFavoriteIds();
    ids.remove(id);
    await setFavoriteIds(ids);
  }

  @override
  bool isFavorite(String id) => getFavoriteIds().contains(id);

  @override
  int get favoriteCount => getFavoriteIds().length;

  // Favorite Station Data (permanent, never expires)
  @override
  Future<void> saveFavoriteStationData(
      String stationId, Map<String, dynamic> data) async {
    final all = _getFavoriteStationDataRaw();
    all[stationId] = data;
    await _put(StorageKeys.favoriteStationData, all);
  }

  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) {
    final raw = _getFavoriteStationDataRaw()[stationId];
    if (raw is! Map) return null;
    // #2893 — deep-convert so nested objects (e.g. the #2777 structured
    // `openingHours`, whose `days`/`ranges` Hive round-trips as
    // `Map<dynamic, dynamic>`) keep `Map<String, dynamic>` typing. A shallow
    // `Map<String, dynamic>.from` left those inner maps dynamic-keyed, so
    // `Station.fromJson`'s nested cast threw and the whole favorite was
    // silently dropped. Mirrors the EV path's existing deep-convert (#690).
    return toStringDynamicMap(raw);
  }

  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      _getFavoriteStationDataRaw();

  @override
  Future<void> removeFavoriteStationData(String stationId) async {
    final all = _getFavoriteStationDataRaw();
    all.remove(stationId);
    await _put(StorageKeys.favoriteStationData, all);
  }

  Map<String, dynamic> _getFavoriteStationDataRaw() {
    final raw = _get(StorageKeys.favoriteStationData);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  // EV Favorites
  @override
  List<String> getEvFavoriteIds() {
    final ids = _get(StorageKeys.evFavoriteStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setEvFavoriteIds(List<String> ids) =>
      _put(StorageKeys.evFavoriteStationIds, ids);

  @override
  Future<void> addEvFavorite(String id) async {
    final ids = getEvFavoriteIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await setEvFavoriteIds(ids);
    }
  }

  @override
  Future<void> removeEvFavorite(String id) async {
    final ids = getEvFavoriteIds();
    ids.remove(id);
    await setEvFavoriteIds(ids);
  }

  @override
  bool isEvFavorite(String id) => getEvFavoriteIds().contains(id);

  @override
  int get evFavoriteCount => getEvFavoriteIds().length;

  @override
  Future<void> saveEvFavoriteStationData(
      String stationId, Map<String, dynamic> data) async {
    final all = _getEvFavoriteStationDataRaw();
    all[stationId] = data;
    await _put(StorageKeys.evFavoriteStationData, all);
  }

  @override
  Map<String, dynamic>? getEvFavoriteStationData(String stationId) {
    final raw = _getEvFavoriteStationDataRaw()[stationId];
    if (raw is! Map) return null;
    // Deep-convert so nested connectors + addresses keep `Map<String, dynamic>`
    // typing; otherwise ChargingStation.fromJson fails on the inner cast (#690).
    return toStringDynamicMap(raw);
  }

  @override
  Future<void> removeEvFavoriteStationData(String stationId) async {
    final all = _getEvFavoriteStationDataRaw();
    all.remove(stationId);
    await _put(StorageKeys.evFavoriteStationData, all);
  }

  Map<String, dynamic> _getEvFavoriteStationDataRaw() {
    final raw = _get(StorageKeys.evFavoriteStationData);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  // Ignored Stations
  @override
  List<String> getIgnoredIds() {
    final ids = _get(StorageKeys.ignoredStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setIgnoredIds(List<String> ids) =>
      _put(StorageKeys.ignoredStationIds, ids);

  @override
  Future<void> addIgnored(String id) async {
    final ids = getIgnoredIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await setIgnoredIds(ids);
    }
  }

  @override
  Future<void> removeIgnored(String id) async {
    final ids = getIgnoredIds();
    ids.remove(id);
    await setIgnoredIds(ids);
  }

  @override
  bool isIgnored(String id) => getIgnoredIds().contains(id);

  // Station Ratings (1-5 stars)
  @override
  Map<String, int> getRatings() {
    final data = _get(StorageKeys.stationRatings);
    if (data == null) return {};
    if (data is Map) {
      return Map<String, int>.fromEntries(
        data.entries
            .map((e) => MapEntry(e.key.toString(), (e.value as num).toInt())),
      );
    }
    return {};
  }

  @override
  Future<void> setRating(String stationId, int rating) async {
    final ratings = getRatings();
    ratings[stationId] = rating;
    await _put(StorageKeys.stationRatings, ratings);
  }

  @override
  Future<void> removeRating(String stationId) async {
    final ratings = getRatings();
    ratings.remove(stationId);
    await _put(StorageKeys.stationRatings, ratings);
  }

  @override
  int? getRating(String stationId) => getRatings()[stationId];
}
