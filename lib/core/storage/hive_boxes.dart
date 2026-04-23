import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Shared Hive box names and initialization logic.
///
/// All domain stores access their boxes through this class.
/// Box-opening, encryption setup, and migration live here so
/// that each domain store stays focused on its own data operations.
class HiveBoxes {
  HiveBoxes._();

  static const String settings = 'settings';
  static const String favorites = 'favorites';
  static const String cache = 'cache';
  static const String profiles = 'profiles';
  static const String priceHistory = 'price_history';
  static const String alerts = 'alerts';

  /// Per-vehicle per-situation consumption baselines (#769). Plain
  /// averages like "7.2 L/100 km at highway cruise" are not PII and
  /// live outside the encrypted set to keep startup cheap.
  static const String obd2Baselines = 'obd2_baselines';

  /// Rolling log of finalised OBD2 trips (#726). Aggregated driving
  /// metrics (distance, avg L/100 km, harsh events). Treated like the
  /// baselines box: unencrypted, opened once at startup.
  static const String obd2TripHistory = 'obd2_trip_history';

  /// Earned gamification badges (#781). One JSON payload per earned
  /// badge keyed by enum name; not PII.
  static const String achievements = 'achievements';

  /// Supported-PID bitmap cache (#811). Keyed by VIN (preferred) or
  /// `make:model:year` (fallback when the car doesn't return a VIN).
  /// Values are sorted `List<int>` of PID indices the car implements
  /// for Mode 01. Small, not PII, opened unencrypted like the other
  /// OBD2 boxes.
  static const String obd2SupportedPids = 'obd2_supported_pids';

  /// Odometer-based service reminders (#584). One JSON payload per
  /// reminder keyed by reminder id. Not PII (label + interval +
  /// odometer) — unencrypted to keep startup cheap, same as
  /// [obd2Baselines] and [achievements].
  static const String serviceReminders = 'service_reminders';

  /// In-flight OBD2 trips that were paused by a transient Bluetooth
  /// drop (#797 phase 1). One JSON payload per paused session keyed by
  /// the session id (ISO start timestamp). Entries are consumed by
  /// [TripRecordingController.resume] or auto-finalised into
  /// [obd2TripHistory] when the grace window expires. Same privacy
  /// treatment as the other OBD2 boxes — unencrypted, opened once at
  /// startup.
  static const String obd2PausedTrips = 'obd2_paused_trips';

  static const _encryptedBoxes = {
    settings,
    profiles,
    favorites,
    cache,
    priceHistory,
    alerts,
  };
  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  static Future<HiveAesCipher> _loadCipher() async {
    const secureStorage = FlutterSecureStorage();
    final existing = await secureStorage.read(key: _hiveEncryptionKeyName);
    if (existing != null) {
      final keyBytes = base64Url.decode(existing);
      return HiveAesCipher(keyBytes);
    }
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveEncryptionKeyName,
      value: base64UrlEncode(key),
    );
    return HiveAesCipher(key);
  }

  static Future<void> _migrateToEncrypted(
      String boxName, HiveAesCipher cipher) async {
    Box oldBox;
    try {
      oldBox = await Hive.openBox('${boxName}_migration_check');
      await oldBox.close();
      await Hive.deleteBoxFromDisk('${boxName}_migration_check');
      oldBox = await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('Hive migration: $boxName already encrypted or empty');
      return;
    }
    if (oldBox.isEmpty) {
      await oldBox.close();
      return;
    }
    final entries = Map<dynamic, dynamic>.from(oldBox.toMap());
    await oldBox.close();
    await Hive.deleteBoxFromDisk(boxName);
    final encryptedBox =
        await Hive.openBox(boxName, encryptionCipher: cipher);
    for (final entry in entries.entries) {
      await encryptedBox.put(entry.key, entry.value);
    }
    await encryptedBox.close();
    debugPrint(
        'Hive migration: $boxName migrated to encrypted (${entries.length} entries)');
  }

  /// Initialize all Hive boxes for the main isolate.
  static Future<void> init() async {
    await Hive.initFlutter();
    final cipher = await _loadCipher();
    for (final boxName in _encryptedBoxes) {
      try {
        final box = await Hive.openBox(boxName, encryptionCipher: cipher);
        await box.close();
      } catch (e) {
        debugPrint('Hive: migrating $boxName to encrypted storage');
        await _migrateToEncrypted(boxName, cipher);
      }
    }
    await Hive.openBox(settings, encryptionCipher: cipher);
    await Hive.openBox(profiles, encryptionCipher: cipher);
    await Hive.openBox(favorites, encryptionCipher: cipher);
    await Hive.openBox(cache, encryptionCipher: cipher);
    await Hive.openBox(priceHistory, encryptionCipher: cipher);
    await Hive.openBox(alerts, encryptionCipher: cipher);
    // #769 — OBD2 baselines are unencrypted JSON strings; low
    // sensitivity and opened once at startup like the other boxes.
    await Hive.openBox<String>(obd2Baselines);
    // #726 — OBD2 trip history: rolling log of finalised trips.
    await Hive.openBox<String>(obd2TripHistory);
    // #781 — gamification badges: one entry per earned badge.
    await Hive.openBox<String>(achievements);
    // #811 — supported-PID bitmap cache (per VIN, or make:model:year
    // fallback). Values are JSON-encoded `List<int>` of PID indices,
    // mirroring the storage idiom used by the other OBD2 boxes so
    // we don't need a custom adapter.
    await Hive.openBox<String>(obd2SupportedPids);
    // #584 — odometer-based service reminders: one entry per reminder.
    await Hive.openBox<String>(serviceReminders);
    // #797 — partial OBD2 trips paused by a BT drop. Same string-typed
    // JSON pattern as [obd2TripHistory] so one box adapter covers both.
    await Hive.openBox<String>(obd2PausedTrips);
  }

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    await Hive.initFlutter();
    final cipher = await _loadCipher();
    await Hive.openBox(settings, encryptionCipher: cipher);
    await Hive.openBox(favorites, encryptionCipher: cipher);
    await Hive.openBox(alerts, encryptionCipher: cipher);
    await Hive.openBox(cache, encryptionCipher: cipher);
    await Hive.openBox(priceHistory, encryptionCipher: cipher);
  }

  /// Close all Hive boxes opened by [initInIsolate].
  ///
  /// Must be called at the end of every background task to release file
  /// handles and prevent race conditions with the main isolate.
  static Future<void> closeIsolateBoxes() async {
    final boxNames = [settings, favorites, alerts, cache, priceHistory];
    for (final name in boxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).close();
        }
      } catch (e) {
        debugPrint('HiveBoxes: failed to close box "$name": $e');
      }
    }
  }

  @visibleForTesting
  static Future<void> initForTest() async {
    await Hive.openBox(settings);
    await Hive.openBox(favorites);
    await Hive.openBox(cache);
    await Hive.openBox(profiles);
    await Hive.openBox(priceHistory);
    await Hive.openBox(alerts);
    // #584 — service reminders live in their own box so tests that
    // exercise the vehicle feature can open it without pulling in the
    // rest of the app. String-typed to match runtime.
    await Hive.openBox<String>(serviceReminders);
    // #797 — paused trips box, string-typed JSON, matches runtime.
    await Hive.openBox<String>(obd2PausedTrips);
  }

  /// Safely converts any Hive map to a typed map.
  /// Returns null if input is not a Map.
  static Map<String, dynamic>? toStringDynamicMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return _deepConvert(value);
    if (value is Map) {
      return _deepConvert(Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      ));
    }
    return null;
  }

  /// Recursively convert nested Hive `_Map` to `Map<String, dynamic>`.
  static Map<String, dynamic> _deepConvert(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Map && value is! Map<String, dynamic>) {
        return MapEntry(key, toStringDynamicMap(value));
      }
      if (value is List) {
        return MapEntry(key, value.map((e) {
          if (e is Map) return toStringDynamicMap(e);
          return e;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }
}
