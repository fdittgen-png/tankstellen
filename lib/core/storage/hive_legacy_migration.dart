// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// One-time migration of pre-encryption plaintext Hive boxes into their
/// encrypted equivalents (#1686).
///
/// Extracted from `HiveBoxes` (#2670) so the box-lifecycle file stays under
/// the file-length norm. The behaviour is unchanged: corruption is never
/// resolved by deleting user data — a box Hive cannot open at all is left on
/// disk for `HiveBoxes.init`'s Phase 2 to surface as a corruption error.
class HiveLegacyMigration {
  HiveLegacyMigration._();

  /// Migrate a pre-encryption plaintext [boxName] into an encrypted box.
  ///
  /// A box already written with the cipher opens cleanly — nothing to do.
  /// When the cipher open fails, a plaintext open is attempted: a box that
  /// still carries plaintext data is migrated; one that fails the plaintext
  /// open too is damaged and is **left on disk untouched**. A box Hive cannot
  /// open at all then surfaces in `init`'s Phase 2 as a corruption error.
  static Future<void> migrateLegacyPlaintextBox(
      String boxName, HiveAesCipher cipher) async {
    try {
      final box = await Hive.openBox<dynamic>(boxName, encryptionCipher: cipher);
      await box.close();
      return; // Already encrypted, or a fresh install.
    } catch (_) {
      // Fall through — the box may be a pre-encryption plaintext box.
    }

    Box<dynamic> plain;
    try {
      plain = await Hive.openBox(boxName);
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('Hive: "$boxName" unreadable during the migration probe '
          '— left on disk for Phase 2 to surface.');
      return;
    }

    await migrateToEncrypted(boxName, plain, cipher);
  }

  /// Copies an already-open plaintext [plain] box into an encrypted box of
  /// the same name (#1686).
  ///
  /// The plaintext file is deleted only *after* its entries are held in
  /// memory, so an interruption mid-migration cannot lose data — a crash
  /// leaves the still-intact plaintext box, never an empty one.
  static Future<void> migrateToEncrypted(
      String boxName, Box<dynamic> plain, HiveAesCipher cipher) async {
    final entries = Map<dynamic, dynamic>.from(plain.toMap());
    await plain.close();

    await Hive.deleteBoxFromDisk(boxName);
    final encryptedBox =
        await Hive.openBox<dynamic>(boxName, encryptionCipher: cipher);
    if (entries.isNotEmpty) {
      await encryptedBox.putAll(entries);
    }
    await encryptedBox.close();
    debugPrint('Hive: migrated "$boxName" to encrypted storage '
        '(${entries.length} entries)');
  }
}
