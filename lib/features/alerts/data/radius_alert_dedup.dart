import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';

/// Notification dedup state for [RadiusAlert].
///
/// Two dedup scopes coexist (#578 phase 3 + #1012 phase 2):
///
///  * Per-alert (used as the gating decision): the runner now fires
///    one grouped notification per alert per cycle, so the dedup
///    *decision* is keyed on the alert id alone. The store remembers
///    the cheapest match price at the last fire so a deeper drop
///    inside the dedup window still bypasses suppression.
///  * Per-(alert, station): preserved for phase 3's per-station deep-
///    link payload, which needs to know "when did we last tell the
///    user about this station, and at what price?". The runner
///    refreshes every per-station row that appeared in the grouped
///    fire so the deep-link logic can read accurate timestamps.
///
/// Without a rate limit the periodic background check would re-notify
/// every cycle while a station is below the user's threshold — a 1 h
/// WorkManager interval would dump 24 identical notifications per day
/// until the price climbs back. The dedup store remembers the last
/// (price, firedAt) pair and allows a new notification only when:
///   a) the cheapest current price dropped further (by at least
///      [priceDropEpsilon]) since the last fire — the user genuinely
///      wants to know it's even cheaper, OR
///   b) [dedupWindow] has elapsed since the last fire — the reminder
///      is fresh enough to surface again.
///
/// Persists under the already-encrypted [HiveBoxes.alerts] box under
/// the `radius_alert_dedup:<alertId>:<stationId>` (per-station) and
/// `radius_alert_dedup_alert:<alertId>` (per-alert) key prefixes so
/// it lives alongside the per-station PriceAlerts and the RadiusAlert
/// definitions themselves — one less box to open in the BG isolate.
class RadiusAlertDedup {
  /// Key prefix for per-(alert, station) rows under [HiveBoxes.alerts].
  /// Exposed so tests and potential future migrations can iterate
  /// over dedup rows without depending on this class's internals.
  static const String keyPrefix = 'radius_alert_dedup:';

  /// Key prefix for the alert-level dedup row (#1012 phase 2). The
  /// runner gates fires off this row; per-station rows under
  /// [keyPrefix] still exist as a side-record for phase 3 deep-links.
  static const String alertKeyPrefix = 'radius_alert_dedup_alert:';

  /// How long after a fire we suppress the same alert unless the
  /// cheapest match drops further. 12 h matches the issue spec —
  /// short enough that a genuine dip the user missed resurfaces
  /// before the next commute, long enough that a flat "still below
  /// threshold" cycle stays quiet overnight.
  static const Duration dedupWindow = Duration(hours: 12);

  /// Minimum price improvement (EUR/L) that qualifies as "dropped
  /// further". Anything smaller is treated as noise from API jitter
  /// and suppressed within the dedup window.
  static const double priceDropEpsilon = 0.001;

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      debugPrint('RadiusAlertDedup: alerts box unavailable: $e\n$st');
      return null;
    }
  }

  String _key(String alertId, String stationId) =>
      '$keyPrefix$alertId:$stationId';

  String _alertKey(String alertId) => '$alertKeyPrefix$alertId';

  /// Decide whether to notify for this (alert, station) pair.
  ///
  /// Returns `true` when the caller should fire a notification — i.e.
  /// either nothing has ever been recorded, or the price dropped
  /// further since the last fire, or the dedup window has expired.
  ///
  /// Retained from #578 phase 3 because the per-station ledger is
  /// still useful for phase 3 deep-link payloads. Phase 2's runner
  /// uses [shouldNotifyAlert] for the actual gating decision instead.
  Future<bool> shouldNotify({
    required String alertId,
    required String stationId,
    required double currentPrice,
    required DateTime now,
  }) async {
    final last = await _lastFire(alertId: alertId, stationId: stationId);
    if (last == null) return true;
    if (currentPrice <= last.price - priceDropEpsilon) return true;
    if (now.difference(last.firedAt) >= dedupWindow) return true;
    return false;
  }

  /// Decide whether to notify for [alertId] given the cheapest match
  /// in this cycle (#1012 phase 2). The runner now fires one grouped
  /// notification per alert, so the gating decision lives at the
  /// alert level rather than per-station.
  ///
  /// Returns `true` when:
  ///   * no previous alert-level fire is recorded,
  ///   * the cheapest match dropped at least [priceDropEpsilon] below
  ///     the cheapest match at the last fire (further-drop override),
  ///   * or the [dedupWindow] has elapsed since the last fire.
  Future<bool> shouldNotifyAlert({
    required String alertId,
    required double cheapestPrice,
    required DateTime now,
  }) async {
    final last = await _lastAlertFire(alertId);
    if (last == null) return true;
    if (cheapestPrice <= last.price - priceDropEpsilon) return true;
    if (now.difference(last.firedAt) >= dedupWindow) return true;
    return false;
  }

  /// Stamp a fire — persist the per-(alert, station) (price, now)
  /// pair so the next [shouldNotify] / phase-3 deep-link lookup can
  /// gate correctly.
  Future<void> recordFire({
    required String alertId,
    required String stationId,
    required double price,
    required DateTime now,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'RadiusAlertDedup.recordFire: alerts box closed, dropping $alertId/$stationId');
      return;
    }
    await box.put(
      _key(alertId, stationId),
      jsonEncode({
        'price': price,
        'firedAt': now.toIso8601String(),
      }),
    );
  }

  /// Stamp an alert-level fire (#1012 phase 2). Stores the cheapest
  /// match price at fire time so [shouldNotifyAlert] can apply the
  /// further-drop override on the next cycle.
  Future<void> recordAlertFire({
    required String alertId,
    required double cheapestPrice,
    required DateTime now,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'RadiusAlertDedup.recordAlertFire: alerts box closed, dropping $alertId');
      return;
    }
    await box.put(
      _alertKey(alertId),
      jsonEncode({
        'price': cheapestPrice,
        'firedAt': now.toIso8601String(),
      }),
    );
  }

  /// Drop every dedup row owned by [alertId] (per-station + alert-
  /// level). Called when the user deletes the RadiusAlert so stale
  /// rows don't leak into the box forever.
  Future<void> clearForAlert(String alertId) async {
    final box = _boxOrNull();
    if (box == null) return;
    final stationPrefix = '$keyPrefix$alertId:';
    final alertKey = _alertKey(alertId);
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(stationPrefix) || k == alertKey)
        .toList();
    if (keys.isEmpty) return;
    await box.deleteAll(keys);
  }

  /// Drop every dedup row. Only used by tests and by the "clear all
  /// data" troubleshoot action — never called on the happy path.
  @visibleForTesting
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    final keys = box.keys
        .whereType<String>()
        .where((k) =>
            k.startsWith(keyPrefix) || k.startsWith(alertKeyPrefix))
        .toList();
    if (keys.isEmpty) return;
    await box.deleteAll(keys);
  }

  Future<_LastFire?> _lastFire({
    required String alertId,
    required String stationId,
  }) async {
    final box = _boxOrNull();
    if (box == null) return null;
    return _readRow(box.get(_key(alertId, stationId)),
        context: '$alertId/$stationId');
  }

  Future<_LastFire?> _lastAlertFire(String alertId) async {
    final box = _boxOrNull();
    if (box == null) return null;
    return _readRow(box.get(_alertKey(alertId)), context: 'alert:$alertId');
  }

  _LastFire? _readRow(Object? raw, {required String context}) {
    if (raw == null) return null;
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return _LastFire.fromJson(decoded);
      }
      if (raw is Map) return _LastFire.fromJson(raw);
    } catch (e, st) {
      debugPrint('RadiusAlertDedup: corrupt dedup row for $context: $e\n$st');
    }
    return null;
  }
}

/// Internal parsed record — not exported because callers only need
/// the `shouldNotify` / `recordFire` verbs.
class _LastFire {
  final double price;
  final DateTime firedAt;
  const _LastFire({required this.price, required this.firedAt});

  factory _LastFire.fromJson(Map raw) {
    final priceRaw = raw['price'];
    final tsRaw = raw['firedAt'];
    final price = priceRaw is num ? priceRaw.toDouble() : null;
    final firedAt =
        tsRaw is String ? DateTime.tryParse(tsRaw) : null;
    if (price == null || firedAt == null) {
      throw FormatException('Invalid dedup row: $raw');
    }
    return _LastFire(price: price, firedAt: firedAt);
  }
}
