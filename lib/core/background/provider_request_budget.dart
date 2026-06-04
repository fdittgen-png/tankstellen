// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/storage_repository.dart';

/// A per-provider last-upstream-request stamp shared by the foreground and the
/// background isolate through ONE budget (Epic #2860 EXIT GATE, #2866).
///
/// ## Why a shared, persisted budget
///
/// Each Dio already owns an in-memory [RateLimitInterceptor] gate, but that
/// gate is per-isolate: the background scan runs in an OS-spawned isolate with
/// its own freshly-built Dio, so its interceptor has no memory of a foreground
/// request the user fired seconds earlier. The result would be a foreground
/// search and a background scan double-hitting the same provider within its
/// `minInterval`.
///
/// This budget closes that gap. It records a single per-country timestamp in
/// the SHARED Hive settings box — written on every successful provider network
/// request from EITHER isolate ([recordRequest], stamped by
/// [StationServiceChain] on a `networkApi` outcome), and read by the background
/// scan ([canFire]) BEFORE it fires a provider request. If the foreground (or a
/// prior background hit) touched a provider within its `minInterval`, the scan
/// skips that provider this round — the cache still answers from the last fetch.
///
/// Combined with the once-per-country-per-scan grouping (the registry-driven
/// `BackgroundPriceSource`) and the twice-daily cadence (the core safeguard),
/// this bounds every provider to well inside its published rate-limit / ToS.
///
/// Pure storage, no I/O of its own: reads are synchronous off the open settings
/// box; the write is fire-and-forget ([recordRequest] returns void) so the hot
/// network-success path never awaits a Hive put.
class ProviderRequestBudget {
  /// Settings-key prefix for the per-country last-request stamp. The country
  /// code is appended (`bg_provider_budget:DE`). One key per provider country.
  // i18n-ignore: storage key, not user-facing.
  static const String keyPrefix = 'bg_provider_budget:';

  ProviderRequestBudget(this._storage);

  final StorageRepository _storage;

  static String _keyFor(String country) => '$keyPrefix$country';

  /// The last recorded upstream-request time for [country], or null when no
  /// request has ever been stamped (or the stored value is unparseable).
  DateTime? lastRequestAt(String country) {
    final raw = _storage.getSetting(_keyFor(country));
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// Whether a fresh provider request for [country] is allowed under the
  /// shared budget — `true` when no prior request is stamped, or the last one
  /// is at least [minInterval] old (relative to [now], default wall clock).
  ///
  /// A null / zero [minInterval] is treated as "no shared throttle" → always
  /// allowed (the provider has no configured spacing to honour).
  bool canFire(String country, Duration? minInterval, {DateTime? now}) {
    if (minInterval == null || minInterval <= Duration.zero) return true;
    final last = lastRequestAt(country);
    if (last == null) return true;
    final at = now ?? DateTime.now();
    return at.difference(last) >= minInterval;
  }

  /// Stamp [country]'s last-request time to [now] (default wall clock).
  ///
  /// Fire-and-forget: the Hive put is started but not awaited, so the network
  /// success path that calls this (the foreground or background chain) is not
  /// slowed by storage I/O. A put failure is swallowed — a missed stamp only
  /// loosens the shared throttle for one round, never crashes a scan.
  void recordRequest(String country, {DateTime? now}) {
    final at = (now ?? DateTime.now()).toUtc().toIso8601String();
    unawaited(_storage.putSetting(_keyFor(country), at).catchError((_) {}));
  }

  /// Await-able variant of [recordRequest] for callers (and tests) that need
  /// the stamp persisted before proceeding.
  @visibleForTesting
  Future<void> recordRequestAwait(String country, {DateTime? now}) async {
    final at = (now ?? DateTime.now()).toUtc().toIso8601String();
    await _storage.putSetting(_keyFor(country), at);
  }
}
