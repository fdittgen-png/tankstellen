import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';

/// Per-alert-per-station notification dedup state for [RadiusAlert]
/// (#578 phase 3).
///
/// Without a rate limit the periodic background check would re-notify
/// every cycle while a station is below the user's threshold — a 1 h
/// WorkManager interval would dump 24 identical notifications per day
/// until the price climbs back. The dedup store remembers the last
/// (price, firedAt) per (alertId, stationId) and allows a new
/// notification only when either:
///   a) the new price dropped further (by at least [priceDropEpsilon])
///      since the last fire — the user genuinely wants to know it's
///      even cheaper, OR
///   b) [dedupWindow] has elapsed since the last fire — the reminder
///      is fresh enough to surface again.
///
/// Persists under the already-encrypted [HiveBoxes.alerts] box under
/// the `radius_alert_dedup:<alertId>:<stationId>` key prefix so it
/// lives alongside the per-station PriceAlerts and the RadiusAlert
/// definitions themselves — one less box to open in the BG isolate.
class RadiusAlertDedup {
  /// Key prefix under [HiveBoxes.alerts]. Exposed so tests and
  /// potential future migrations can iterate over dedup rows
  /// without depending on this class's internals.
  static const String keyPrefix = 'radius_alert_dedup:';

  /// How long after a fire we suppress the same (alert, station)
  /// unless the price drops further. 12 h matches the issue spec —
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
    } catch (e) {
      debugPrint('RadiusAlertDedup: alerts box unavailable: $e');
      return null;
    }
  }

  String _key(String alertId, String stationId) =>
      '$keyPrefix$alertId:$stationId';

  /// Decide whether to notify for this (alert, station) pair.
  ///
  /// Returns `true` when the caller should fire a notification — i.e.
  /// either nothing has ever been recorded, or the price dropped
  /// further since the last fire, or the dedup window has expired.
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

  /// Stamp a fire — persist the (price, now) pair so the next
  /// [shouldNotify] call can gate correctly.
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

  /// Drop every dedup row owned by [alertId]. Called when the user
  /// deletes the RadiusAlert so stale (alertId, stationId) rows
  /// don't leak into the box forever.
  Future<void> clearForAlert(String alertId) async {
    final box = _boxOrNull();
    if (box == null) return;
    final prefix = '$keyPrefix$alertId:';
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
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
        .where((k) => k.startsWith(keyPrefix))
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
    final raw = box.get(_key(alertId, stationId));
    if (raw == null) return null;
    try {
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return _LastFire.fromJson(decoded);
      }
      if (raw is Map) return _LastFire.fromJson(raw);
    } catch (e) {
      debugPrint(
          'RadiusAlertDedup: corrupt dedup row for $alertId/$stationId: $e');
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
