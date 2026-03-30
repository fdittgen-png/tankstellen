/// Mixin for services that download a full national dataset and cache it
/// in memory (MITECO, MISE, Argentina, Denmark).
///
/// Provides a standardized TTL-based cache validation pattern, eliminating
/// 4 duplicated cache-check blocks.
mixin CachedDatasetMixin {
  DateTime? _datasetCachedAt;

  /// Whether the in-memory dataset is still fresh.
  bool isDatasetFresh(Duration ttl) =>
      _datasetCachedAt != null &&
      DateTime.now().difference(_datasetCachedAt!) < ttl;

  /// Mark the in-memory dataset as just refreshed.
  void markDatasetRefreshed() => _datasetCachedAt = DateTime.now();
}
