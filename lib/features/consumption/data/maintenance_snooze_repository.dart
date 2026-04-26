import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../domain/entities/maintenance_suggestion.dart';

/// Per-signal snooze persistence for the predictive-maintenance card
/// (#1124).
///
/// Stores one ISO-8601 timestamp per [MaintenanceSignal] under the
/// already-encrypted `settings` box — same idiom as
/// [VelocityAlertCooldown] (#579), which also keeps small per-feature
/// timestamps next to the rest of the user preferences instead of
/// introducing yet another Hive box. `hive_boxes.dart` is one of the
/// hottest files in the parallel-worker rotation; reusing
/// `HiveBoxes.settings` keeps this PR off that file.
///
/// Snooze contract:
///   * `snooze(signal, until)` writes the ISO-8601 string for the
///     given signal. A subsequent `isSnoozed(signal, now)` returns
///     `true` while `now < until`.
///   * `isSnoozed` is forgiving: corrupt timestamps are logged and
///     treated as "not snoozed" so a manual edit / Hive corruption
///     can never permanently silence a maintenance signal.
///   * `clear(signal)` removes the entry — used by the "show again"
///     debug affordance and the test cleanup helpers.
class MaintenanceSnoozeRepository {
  /// Key prefix used in the `settings` box. Keys take the form
  /// `maintenance.snooze.<signal-name>`, where `<signal-name>` is the
  /// enum's `.name`. Keeping the prefix as a const lets tests assert
  /// the exact storage key without hard-coding a string literal.
  static const String keyPrefix = 'maintenance.snooze.';

  /// Default snooze duration applied by the "Snooze 30 days" button
  /// on the maintenance card. Exposed as a const so the card and the
  /// provider read the same value.
  static const Duration defaultSnoozeDuration = Duration(days: 30);

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
      return Hive.box(HiveBoxes.settings);
    } catch (e, st) {
      debugPrint(
          'MaintenanceSnoozeRepository: settings box unavailable: $e\n$st');
      return null;
    }
  }

  String keyFor(MaintenanceSignal signal) => '$keyPrefix${signal.name}';

  /// Snooze [signal] until [until]. Subsequent [isSnoozed] calls
  /// before that timestamp return `true`.
  Future<void> snooze({
    required MaintenanceSignal signal,
    required DateTime until,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'MaintenanceSnoozeRepository.snooze: settings box closed, dropping ${signal.name}');
      return;
    }
    await box.put(keyFor(signal), until.toIso8601String());
  }

  /// Convenience: snooze [signal] for [defaultSnoozeDuration] starting
  /// at [now].
  Future<void> snoozeForDefault({
    required MaintenanceSignal signal,
    required DateTime now,
  }) {
    return snooze(signal: signal, until: now.add(defaultSnoozeDuration));
  }

  /// Returns `true` when [signal] is currently snoozed, i.e. there is
  /// a stored timestamp and it is in the future. Corrupt entries are
  /// treated as "not snoozed".
  bool isSnoozed({
    required MaintenanceSignal signal,
    required DateTime now,
  }) {
    final until = _snoozedUntil(signal);
    if (until == null) return false;
    return until.isAfter(now);
  }

  /// Read the snooze timestamp for [signal], if any. Returns null when
  /// no entry exists or when the stored value can't be parsed.
  DateTime? _snoozedUntil(MaintenanceSignal signal) {
    final box = _boxOrNull();
    if (box == null) return null;
    final raw = box.get(keyFor(signal));
    if (raw == null) return null;
    try {
      return DateTime.tryParse(raw.toString());
    } catch (e, st) {
      debugPrint(
          'MaintenanceSnoozeRepository: corrupt timestamp for ${signal.name}: $e\n$st');
      return null;
    }
  }

  /// Drop the snooze entry for [signal]. Used by the "show again"
  /// debug affordance (not yet shipped) and by the test cleanup
  /// helpers.
  Future<void> clear(MaintenanceSignal signal) async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.delete(keyFor(signal));
  }

  /// Drop every snooze entry. Test-only — not exposed to the app.
  @visibleForTesting
  Future<void> clearAll() async {
    final box = _boxOrNull();
    if (box == null) return;
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(keyPrefix))
        .toList();
    await box.deleteAll(keys);
  }
}
