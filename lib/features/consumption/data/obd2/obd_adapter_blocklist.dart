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

  /// Persists the latest belief for [elmId]. No-op when [elmId] is
  /// empty — we won't have a stable key to recall by next session
  /// either, so storing the value would just leak.
  Future<void> recordBelief(String elmId, double brokenConfidence) async {
    if (elmId.isEmpty) return;
    await _storage.putSetting('$_keyPrefix$elmId', brokenConfidence);
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
}
