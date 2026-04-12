import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';
import '../storage_keys.dart';

/// Hive-backed implementation of [FavoriteStorage] and [IgnoredStorage].
///
/// Manages favorite station IDs, persisted station data for offline access,
/// ignored station IDs, and station ratings.
class FavoritesHiveStore
    implements FavoriteStorage, EvFavoriteStorage, IgnoredStorage, RatingStorage {
  Box get _favorites => Hive.box(HiveBoxes.favorites);

  // Favorites
  @override
  List<String> getFavoriteIds() {
    final ids = _favorites.get(StorageKeys.favoriteStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setFavoriteIds(List<String> ids) =>
      _favorites.put(StorageKeys.favoriteStationIds, ids);

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
    await _favorites.put(StorageKeys.favoriteStationData, all);
  }

  @override
  Map<String, dynamic>? getFavoriteStationData(String stationId) {
    final raw = _getFavoriteStationDataRaw()[stationId];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Map<String, dynamic> getAllFavoriteStationData() =>
      _getFavoriteStationDataRaw();

  @override
  Future<void> removeFavoriteStationData(String stationId) async {
    final all = _getFavoriteStationDataRaw();
    all.remove(stationId);
    await _favorites.put(StorageKeys.favoriteStationData, all);
  }

  Map<String, dynamic> _getFavoriteStationDataRaw() {
    final raw = _favorites.get(StorageKeys.favoriteStationData);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  // EV Favorites
  @override
  List<String> getEvFavoriteIds() {
    final ids = _favorites.get(StorageKeys.evFavoriteStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setEvFavoriteIds(List<String> ids) =>
      _favorites.put(StorageKeys.evFavoriteStationIds, ids);

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
    await _favorites.put(StorageKeys.evFavoriteStationData, all);
  }

  @override
  Map<String, dynamic>? getEvFavoriteStationData(String stationId) {
    final raw = _getEvFavoriteStationDataRaw()[stationId];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Future<void> removeEvFavoriteStationData(String stationId) async {
    final all = _getEvFavoriteStationDataRaw();
    all.remove(stationId);
    await _favorites.put(StorageKeys.evFavoriteStationData, all);
  }

  Map<String, dynamic> _getEvFavoriteStationDataRaw() {
    final raw = _favorites.get(StorageKeys.evFavoriteStationData);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  // Ignored Stations
  @override
  List<String> getIgnoredIds() {
    final ids = _favorites.get(StorageKeys.ignoredStationIds);
    if (ids == null) return [];
    return List<String>.from(ids as List);
  }

  @override
  Future<void> setIgnoredIds(List<String> ids) =>
      _favorites.put(StorageKeys.ignoredStationIds, ids);

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
    final data = _favorites.get(StorageKeys.stationRatings);
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
    await _favorites.put(StorageKeys.stationRatings, ratings);
  }

  @override
  Future<void> removeRating(String stationId) async {
    final ratings = getRatings();
    ratings.remove(stationId);
    await _favorites.put(StorageKeys.stationRatings, ratings);
  }

  @override
  int? getRating(String stationId) => getRatings()[stationId];
}
