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

  static const _encryptedBoxes = {settings, profiles};
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
    await Hive.openBox(favorites);
    await Hive.openBox(cache);
    await Hive.openBox(priceHistory);
    await Hive.openBox(alerts);
  }

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    await Hive.initFlutter();
    final cipher = await _loadCipher();
    await Hive.openBox(settings, encryptionCipher: cipher);
    await Hive.openBox(favorites);
    await Hive.openBox(alerts);
    await Hive.openBox(cache);
    await Hive.openBox(priceHistory);
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
