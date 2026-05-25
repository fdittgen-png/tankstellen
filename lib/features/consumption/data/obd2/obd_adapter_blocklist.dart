// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/data/storage_repository.dart';

/// Persistent per-adapter broken-MAP blocklist (#1423 phase 4).
///
/// Stores the latest [BrokenMapBelief.pointEstimate] keyed by ELM
/// firmware identifier (whatever `ATI` returned during pair). The
/// populator recalls this BEFORE running an idle probe at the next
/// pair attempt — when a known-broken adapter is recognised, the
/// warning surfaces immediately without a fresh probe round.
///
/// Backed by [SettingsStorage] (Hive `settings` box). One key per
/// adapter under the [_keyPrefix] namespace, value is the raw
/// `double` confidence in `[0.0, 1.0]`.
///
/// Stateless and idempotent: subsequent calls with a different
/// confidence overwrite the previous value. Empty IDs are ignored
/// (the populator falls back to a fresh probe).
class ObdAdapterBlocklist {
  final SettingsStorage _storage;

  const ObdAdapterBlocklist(this._storage);

  /// Settings-box key prefix; one entry per adapter ELM ID. Chosen
  /// to avoid collisions with the existing `setupSkipped` /
  /// `apiKey` / etc. keys in the same box.
  static const _keyPrefix = 'obdAdapterBroken:';

  /// Settings-box key for the index of known adapter ELM IDs.
  ///
  /// [SettingsStorage] exposes no key-enumeration, so the blocklist
  /// keeps its own additive index: every [recordBelief] appends the id
  /// here, and [entries] reads it back. Additive — no migration, old
  /// per-adapter values written before the index existed simply won't
  /// appear in the diagnostics surface (#1622).
  static const _indexKey = 'obdAdapterBroken:__ids';

  /// Persists the latest belief for [elmId]. No-op when [elmId] is
  /// empty — we won't have a stable key to recall by next session
  /// either, so storing the value would just leak.
  Future<void> recordBelief(String elmId, double brokenConfidence) async {
    if (elmId.isEmpty) return;
    await _storage.putSetting('$_keyPrefix$elmId', brokenConfidence);
    await _addToIndex(elmId);
  }

  /// Recalls the persisted belief for [elmId]. Returns null when no
  /// observation has ever been recorded for this adapter, when
  /// [elmId] is empty, or when the stored value isn't a `double`
  /// (defensive against legacy entries / Hive type drift).
  Future<double?> recall(String elmId) async {
    if (elmId.isEmpty) return null;
    final raw = _storage.getSetting('$_keyPrefix$elmId');
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return null;
  }

  /// Every adapter currently on the blocklist, keyed by ELM ID with
  /// its recorded broken-confidence in `[0.0, 1.0]` (#1622).
  ///
  /// Reads the [_indexKey] roster, then recalls each entry — an id
  /// whose value was cleared (see [clearEntry]) is skipped, so the
  /// returned map only ever holds adapters with a live belief.
  Future<Map<String, double>> entries() async {
    final result = <String, double>{};
    for (final elmId in _index()) {
      final confidence = await recall(elmId);
      if (confidence != null) result[elmId] = confidence;
    }
    return result;
  }

  /// Removes [elmId] from the blocklist (#1622) — the manual escape
  /// hatch for a healthy adapter that was mis-flagged.
  ///
  /// [SettingsStorage] has no key-delete, so the stored confidence is
  /// neutralised to `null` (which makes [recall] return null, exactly
  /// as if the adapter had never been observed) and the id is dropped
  /// from the index.
  Future<void> clearEntry(String elmId) async {
    if (elmId.isEmpty) return;
    await _storage.putSetting('$_keyPrefix$elmId', null);
    final remaining = _index()..remove(elmId);
    await _storage.putSetting(_indexKey, remaining);
  }

  /// Current index roster, read defensively against Hive type drift.
  List<String> _index() {
    final raw = _storage.getSetting(_indexKey);
    if (raw is List) return raw.whereType<String>().toList();
    return <String>[];
  }

  Future<void> _addToIndex(String elmId) async {
    final ids = _index();
    if (ids.contains(elmId)) return;
    ids.add(elmId);
    await _storage.putSetting(_indexKey, ids);
  }
}
