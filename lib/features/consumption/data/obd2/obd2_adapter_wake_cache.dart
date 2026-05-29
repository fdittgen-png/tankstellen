// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/data/storage_repository.dart';
import '../../../../core/logging/error_logger.dart';
import 'elm327_adapter.dart';
import 'obd2_service.dart';

/// Per-MAC observed-outcome wake cache (#2268 concern 3).
///
/// Records whether a specific physical adapter needs the bounded wake
/// window (#2268 concern 2) on a fresh connect. Keyed per adapter MAC —
/// NOT per firmware string: thousands of clones share the identical
/// `ELM327 v1.5` `ATI` reply, so a firmware-string key would smear one
/// flaky clone's behaviour across every adapter that ever reported the
/// same version. The MAC (BLE remote-id / Classic address) is stable per
/// physical device, which is exactly the granularity the wake decision
/// wants.
///
/// The recorded value is an OBSERVED outcome, never raw first-command
/// latency:
///   * `true`  — a fresh-connect first command timed out AND a
///     longer-settle re-send then succeeded ([WakeObservation.wokeAfterNudge]).
///   * `false` — the wake window ran and the first command answered
///     immediately ([WakeObservation.answeredImmediately]); this MAC
///     never needs the window again and the connection service can
///     suppress it forever.
///
/// Backed by [SettingsStorage] (the Hive `settings` box), reusing the
/// `obd_adapter_blocklist.dart` pattern byte-for-byte: one entry per MAC
/// under the [_keyPrefix] namespace plus an additive [_indexKey] roster
/// (SettingsStorage exposes no key enumeration). Stateless and
/// idempotent. Empty MACs are ignored — an unstamped service has no
/// stable key to recall by next session.
class Obd2AdapterWakeCache {
  final SettingsStorage _storage;

  const Obd2AdapterWakeCache(this._storage);

  /// Settings-box key prefix; one entry per adapter MAC. Chosen to avoid
  /// collisions with the `obdAdapterBroken:` blocklist keys and the rest
  /// of the shared `settings` box.
  static const _keyPrefix = 'obdAdapterWake:';

  /// Settings-box key for the additive index of known adapter MACs.
  /// [SettingsStorage] exposes no key-enumeration, so the cache keeps its
  /// own roster: every [record] appends here, [entries] reads it back.
  static const _indexKey = 'obdAdapterWake:__ids';

  /// Normalise a MAC into a stable cache key — trimmed + lower-cased so
  /// capitalisation never splits an entry. Returns null for an empty MAC.
  static String? _normalise(String mac) {
    final m = mac.trim().toLowerCase();
    return m.isEmpty ? null : m;
  }

  /// Persists the observed [wakeNeeded] outcome for [mac]. No-op when
  /// [mac] is empty — without a stable key the value would just leak.
  /// Idempotent: a later observation overwrites the earlier one (e.g. an
  /// adapter that woke once but answers immediately on later connects
  /// flips to `false`).
  Future<void> record(String mac, bool wakeNeeded) async {
    final key = _normalise(mac);
    if (key == null) return;
    await _storage.putSetting('$_keyPrefix$key', wakeNeeded);
    await _addToIndex(key);
  }

  /// Recalls the observed outcome for [mac]:
  ///   * `true`  — known to need the wake window.
  ///   * `false` — observed never to need it (suppress the window).
  ///   * `null`  — never observed, [mac] empty, or a non-bool legacy
  ///     value (defensive against Hive type drift). The connection
  ///     service then lets the adapter's own [WakePolicy] decide.
  Future<bool?> recall(String mac) async {
    final key = _normalise(mac);
    if (key == null) return null;
    final raw = _storage.getSetting('$_keyPrefix$key');
    if (raw is bool) return raw;
    return null;
  }

  /// Resolve the wake-window override for [mac] (#2268 concern 3): a
  /// no-op [WakePolicy] when the cache observed the MAC as never-needing
  /// the window (so the connect path suppresses it), else null — honour
  /// the adapter's own policy (a no-op for every generic adapter).
  /// Best-effort: a read failure falls back to the adapter policy.
  Future<WakePolicy?> overrideFor(String mac) async {
    try {
      return await recall(mac) == false ? const WakePolicy.noop() : null;
    } catch (e, st) {
      _logFailure('recall', e, st);
      return null;
    }
  }

  /// Persist the observed wake outcome for [mac] (#2268 concern 3).
  /// Records `false` on [WakeObservation.answeredImmediately] and `true`
  /// on [WakeObservation.wokeAfterNudge]; writes NOTHING for `notRun`
  /// (window never ran) or `failed` (no positive evidence) — so the cache
  /// only ever learns from a clean OBSERVED outcome. Best-effort.
  Future<void> recordObservation(String mac, WakeObservation obs) async {
    final bool wakeNeeded;
    switch (obs) {
      case WakeObservation.answeredImmediately:
        wakeNeeded = false;
      case WakeObservation.wokeAfterNudge:
        wakeNeeded = true;
      case WakeObservation.notRun:
      case WakeObservation.failed:
        return;
    }
    try {
      await record(mac, wakeNeeded);
    } catch (e, st) {
      _logFailure('record', e, st);
    }
  }

  void _logFailure(String op, Object e, StackTrace st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
      'where': 'Obd2AdapterWakeCache $op failed',
    }));
  }

  /// Every MAC the cache has observed, keyed by its normalised MAC with
  /// the recorded wakeNeeded flag. Reads the [_indexKey] roster then
  /// recalls each entry; a MAC whose value was cleared is skipped.
  Future<Map<String, bool>> entries() async {
    final result = <String, bool>{};
    for (final mac in _index()) {
      final needed = await recall(mac);
      if (needed != null) result[mac] = needed;
    }
    return result;
  }

  /// Removes [mac] from the cache — the escape hatch for an adapter
  /// whose behaviour changed (re-flashed firmware, etc.). [SettingsStorage]
  /// has no key-delete, so the value is neutralised to null (making
  /// [recall] return null, as if never observed) and the id is dropped
  /// from the index.
  Future<void> clearEntry(String mac) async {
    final key = _normalise(mac);
    if (key == null) return;
    await _storage.putSetting('$_keyPrefix$key', null);
    final remaining = _index()..remove(key);
    await _storage.putSetting(_indexKey, remaining);
  }

  /// Current index roster, read defensively against Hive type drift.
  List<String> _index() {
    final raw = _storage.getSetting(_indexKey);
    if (raw is List) return raw.whereType<String>().toList();
    return <String>[];
  }

  Future<void> _addToIndex(String mac) async {
    final ids = _index();
    if (ids.contains(mac)) return;
    ids.add(mac);
    await _storage.putSetting(_indexKey, ids);
  }
}
