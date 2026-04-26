import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../search/domain/entities/fuel_type.dart';

/// Per-fuel cooldown tracker for the velocity alert detector (#579).
///
/// A single user-visible notification per fuel type per cooldown
/// window is plenty — firing "E10 dropped" ten times in an hour
/// would just train the user to swipe the channel away. This store
/// simply remembers "last fired at" per fuel type and answers
/// `canFire(fuelType, now)` against a caller-supplied window.
///
/// Persists under the already-encrypted `settings` box (one tiny
/// string per fuel) rather than introducing yet another box —
/// cooldown state is neither large nor independently useful.
class VelocityAlertCooldown {
  /// Key prefix in the settings box — one entry per fuel apiValue.
  static const String keyPrefix = 'velocity_cooldown:';

  Box? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.settings)) return null;
      return Hive.box(HiveBoxes.settings);
    } catch (e, st) {
      debugPrint('VelocityAlertCooldown: settings box unavailable: $e\n$st');
      return null;
    }
  }

  String _key(FuelType fuelType) => '$keyPrefix${fuelType.apiValue}';

  /// Return `true` when either no alert has ever fired for
  /// [fuelType] or when `now - lastFired >= cooldown`.
  Future<bool> canFire({
    required FuelType fuelType,
    required DateTime now,
    required Duration cooldown,
  }) async {
    final last = await _lastFired(fuelType);
    if (last == null) return true;
    return now.difference(last) >= cooldown;
  }

  /// Stamp [fuelType] as having fired at [now]. Subsequent
  /// [canFire] calls within the cooldown window return `false`.
  Future<void> recordFired({
    required FuelType fuelType,
    required DateTime now,
  }) async {
    final box = _boxOrNull();
    if (box == null) {
      debugPrint(
          'VelocityAlertCooldown.recordFired: settings box closed, dropping ${fuelType.apiValue}');
      return;
    }
    await box.put(_key(fuelType), now.toIso8601String());
  }

  /// Read the last-fired stamp, if any. Corrupt values are logged
  /// and treated as "never fired".
  Future<DateTime?> _lastFired(FuelType fuelType) async {
    final box = _boxOrNull();
    if (box == null) return null;
    final raw = box.get(_key(fuelType));
    if (raw == null) return null;
    try {
      final parsed = DateTime.tryParse(raw.toString());
      return parsed;
    } catch (e, st) {
      debugPrint('VelocityAlertCooldown: corrupt timestamp for ${fuelType.apiValue}: $e\n$st');
      return null;
    }
  }

  /// Drop every cooldown entry. Used by tests.
  @visibleForTesting
  Future<void> clear() async {
    final box = _boxOrNull();
    if (box == null) return;
    final keys = box.keys
        .whereType<String>()
        .where((k) => k.startsWith(keyPrefix))
        .toList();
    await box.deleteAll(keys);
  }
}
