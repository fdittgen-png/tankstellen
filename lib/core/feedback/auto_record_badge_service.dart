import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent counter of unseen auto-recorded trips, surfaced as a
/// launcher-icon badge (#1004 phase 5).
///
/// The number on the home-screen icon answers the user's question
/// "did anything happen while I was driving?" without requiring the
/// app to be opened. Each time the auto-record path saves a new trip
/// (phase 4) [increment] is called; opening the corresponding trip
/// detail screen calls [decrement]. When the counter reaches zero the
/// badge disappears.
///
/// ## Why a Dart-side counter
///
/// `AppBadgePlus` is fire-and-forget — the launcher process owns the
/// rendered badge and we have no way to query "what number is showing
/// right now?". Persisting the count locally lets the service answer
/// `count` synchronously, survive app restarts, and recover when the
/// platform call fails (e.g. on a launcher that doesn't expose a
/// badge API).
///
/// ## Why platform exceptions don't propagate
///
/// Some Android launchers (AOSP, certain custom skins) reject the
/// shortcut-badger intent. Throwing back into the trip-save / detail-
/// open path would either lose a saved trip or block navigation —
/// both far worse than a missing badge. Instead the service logs via
/// `debugPrint` and keeps the Dart-level state consistent.
class AutoRecordBadgeService {
  /// `SharedPreferences` key holding the int counter. Versioned so a
  /// future schema change can ignore legacy values without colliding.
  static const String storageKey = 'auto_record_badge_count_v1';

  final Future<void> Function(int) _setBadge;
  final SharedPreferences _prefs;

  AutoRecordBadgeService({
    Future<void> Function(int)? setBadge,
    required SharedPreferences prefs,
  })  : _setBadge = setBadge ?? _defaultSetBadge,
        _prefs = prefs;

  /// Read current count without side effects. Defaults to 0 when no
  /// value has been persisted yet.
  int get count => _prefs.getInt(storageKey) ?? 0;

  /// Increment the unseen-trip counter by one and update the launcher
  /// badge. Persists the new count before attempting the platform
  /// call so a launcher-reject leaves the Dart state correct for the
  /// next boot.
  Future<void> increment() async {
    final next = count + 1;
    await _writeCount(next);
    await _safeSetBadge(next);
  }

  /// Decrement the counter, clamped at 0. When the counter reaches 0
  /// the launcher badge is removed.
  Future<void> decrement() async {
    final current = count;
    final next = current > 0 ? current - 1 : 0;
    await _writeCount(next);
    await _safeSetBadge(next);
  }

  /// Reset the counter to 0 and clear the launcher badge. Reserved
  /// for the "Mark all as read" affordance shipping in a later phase.
  Future<void> markAllAsRead() async {
    await _writeCount(0);
    await _safeSetBadge(0);
  }

  Future<void> _writeCount(int value) async {
    try {
      await _prefs.setInt(storageKey, value);
    } catch (e, st) {
      debugPrint('AutoRecordBadgeService write failed: $e\n$st');
    }
  }

  Future<void> _safeSetBadge(int value) async {
    try {
      await _setBadge(value);
    } catch (e, st) {
      // Launcher does not support badges, or the platform plugin
      // raised. Don't propagate — the Dart-level counter is the
      // source of truth and survives the next launch attempt.
      debugPrint('AutoRecordBadgeService setBadge($value) failed: $e\n$st');
    }
  }

  /// Default platform-side hook. `app_badge_plus` documents
  /// `updateBadge(0)` as the cross-platform "remove badge" call, so
  /// we don't need a separate clear path.
  static Future<void> _defaultSetBadge(int count) {
    return AppBadgePlus.updateBadge(count);
  }
}
