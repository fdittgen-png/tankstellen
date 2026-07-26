// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3619 — per-shape cache schema versions.
///
/// Cached payloads are PARSED output, so a payload whose serialized
/// SHAPE changed between builds can embed exactly the parser bug an
/// update just fixed (#3219: the FR per-day-hours fix was invisible
/// because the pre-fix build's hour-less parse sat fresh under the same
/// key). The original guard was the blunt appBuild stamp: EVERY cache
/// entry — including the multi-MB `dataset:` country payloads — busted
/// on EVERY app update, refetching the world after each of our frequent
/// releases.
///
/// This registry replaces the sledgehammer with discipline + enforcement
/// (the DesKilo cacheSchemaVersion pattern, ported back):
///
///  * every envelope is stamped with its key-prefix's schema version;
///  * `CacheManager.getFresh` requires an exact schema match — the
///    appBuild mismatch alone no longer busts;
///  * **bumping the matching constant below is part of ANY change to
///    that entry type's serialized shape** — enforced by
///    `test/core/cache/cache_schema_shape_test.dart`, which pins each
///    codec's structural signature against the registered version:
///    shape drift without a bump is a red test, not a field bug.
///
/// A missing stamp (entry written before this registry, or by a future
/// build with a HIGHER version) reads as a fresh-miss, exactly like the
/// old cross-build gate — `CacheManager.get` still serves it to the
/// stale/offline fallback, so an update never costs the offline
/// backbone.
class CacheSchema {
  CacheSchema._();

  /// Schema version per cache-key `type:` prefix (see [CacheKey] /
  /// [PersistentDataset.keyPrefix]). Bump the matching entry whenever
  /// the SERIALIZED SHAPE of that type changes; unknown prefixes get
  /// [fallback].
  static const Map<String, int> byPrefix = {
    // serializeStationList — {'stations': [Station.toJson()]}
    'search': 1,
    'station': 1,
    'dataset': 1,
    // serializeStationDetail — station + hours + overrides envelope
    'detail': 1,
    // serializePrices — {'prices': {id: StationPrices.toJson()}}
    'prices': 1,
    // geocoding_chain inline shapes: {'lat','lng'} / {'address'} /
    // {'countryCode'}
    'geo': 1,
    // serializeLocations — {'locations': [ResolvedLocation fields]}
    'city': 1,
  };

  /// Version for prefixes not (yet) in [byPrefix].
  static const int fallback = 1;

  /// The registered schema version for [key] (`type:` = everything
  /// before the first `:`; keys without a colon use the whole key).
  static int forKey(String key) {
    final colon = key.indexOf(':');
    final prefix = colon < 0 ? key : key.substring(0, colon);
    return byPrefix[prefix] ?? fallback;
  }
}
