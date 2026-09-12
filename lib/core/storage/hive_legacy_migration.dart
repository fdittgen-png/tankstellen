// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';

/// One-time migration of pre-encryption plaintext Hive boxes into their
/// encrypted equivalents (#1686).
///
/// Extracted from `HiveBoxes` (#2670) so the box-lifecycle file stays under
/// the file-length norm. The behaviour is unchanged: corruption is never
/// resolved by deleting user data — a box Hive cannot open at all is left on
/// disk for `HiveBoxes.init`'s Phase 2 to surface as a corruption error.
class HiveLegacyMigration {
  HiveLegacyMigration._();

  /// The `boxSchema` key recording that the plaintext migration is done
  /// (#4110).
  static const String doneKey = 'legacy_plaintext_migrated';

  /// The value [doneKey] carries once the probes have run to completion.
  static const int doneValue = 1;

  /// Whether the one-time plaintext migration still has anything to do.
  ///
  /// Pure and visible so the skip can be asserted directly rather than
  /// inferred from timings.
  @visibleForTesting
  static bool isNeeded(Box<int> meta) => meta.get(doneKey) != doneValue;

  /// Run the plaintext probes ONCE, ever, and record that they ran.
  ///
  /// #4110 — this used to happen on every cold start, for every encrypted
  /// box. The happy path of [migrateLegacyPlaintextBox] is "open the box
  /// with the cipher, close it again", and `HiveBoxes.init`'s Phase 2 then
  /// opens all six a SECOND time — so every launch paid twelve opens where
  /// six would do. Worse, Hive's default compaction can fire on that
  /// close, so the probe could rewrite the whole `cache` file before the
  /// real open even began, and `cache` is the box the health counters show
  /// evicting dozens of entries a day.
  ///
  /// None of that work can find anything after the first successful
  /// migration, or on a fresh install. It is gated now — which is right
  /// regardless of how much of the 8.9 s cold start it turns out to own,
  /// because work that cannot produce an effect should not be on the
  /// critical path at all. The `hive_migrate` sub-phase in the startup
  /// trace will say how much it was.
  ///
  /// The flag lives in `boxSchema`: unencrypted, integer-valued and tiny,
  /// so reading it costs far less than one probe.
  static Future<void> runOnce(
    Iterable<String> encryptedBoxes,
    HiveAesCipher cipher,
    Box<int> meta,
  ) async {
    if (!isNeeded(meta)) return;
    await Future.wait<void>(
      encryptedBoxes.map((name) => migrateLegacyPlaintextBox(name, cipher)),
    );
    // Written only after every probe completed. A crash mid-migration
    // leaves the flag unset, so the next launch probes again — the
    // conservative direction, since a missed migration loses data and a
    // repeated probe only costs time.
    await meta.put(doneKey, doneValue);
  }

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
      // ignore: silent_catch — Fall through — the box may be a pre-encryption plaintext box.
    }

    Box<dynamic> plain;
    try {
      plain = await Hive.openBox(boxName);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': 'HiveLegacyMigration: plaintext probe failed for $boxName'
      }));
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
