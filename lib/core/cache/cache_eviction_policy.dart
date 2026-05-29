// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Tunables for `CacheManager.evictBounded` (#2264).
///
/// All compile-time so the eviction behaviour stays reproducible in tests
/// (mirrors the `CacheTtl` policy stance — no runtime knob).
class CacheEvictionPolicy {
  /// Max entries kept per key prefix (`search:`, `detail:`, …). The oldest
  /// entries beyond this per-prefix count are evicted so one noisy prefix
  /// can't starve the rest.
  final int prefixBudget;

  /// Global ceiling on the total approximate payload size, in bytes. Past it
  /// the LRU sweep evicts oldest-first (excluding `dataset:` entries).
  final int maxBytes;

  const CacheEvictionPolicy({
    this.prefixBudget = 200,
    this.maxBytes = 8 * 1024 * 1024,
  });
}
