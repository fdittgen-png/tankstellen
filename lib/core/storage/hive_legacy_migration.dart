// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/app_log.dart';
import '../logging/error_logger.dart';
import 'hive_box_key_probe.dart';
import 'impl/hive_directory_resolver.dart';

/// One-time migration of pre-encryption plaintext Hive boxes into their
/// encrypted equivalents (#1686).
///
/// Extracted from `HiveBoxes` (#2670) so the box-lifecycle file stays under
/// the file-length norm. Corruption is never resolved by deleting user
/// data, and since #4372 no box file is opened with the key until its own
/// frame checksum says it is not plaintext.
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
  /// box. The happy path of [migrateLegacyPlaintextBox] was "open the box
  /// with the cipher, close it again" (#4372 replaced that open with a
  /// read-only frame check), and `HiveBoxes.init`'s Phase 2 then
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

  /// Suffix of the encrypted staging box a plaintext box is copied into
  /// before its plaintext file is deleted (#4372). The same suffix
  /// `HiveTripBoxEncryption` uses, so `LocalDataEraser` already erases a
  /// staging box a crash left behind.
  @visibleForTesting
  static String stagingBoxName(String boxName) => '${boxName}_enc_staging';

  /// Test seam: the write of the plaintext records into the staging box,
  /// so a failure mid-copy can be injected.
  @visibleForTesting
  static Future<void> Function(Box<dynamic> staging, Map<dynamic, dynamic>)
      stagingWriter = _putAll;

  static Future<void> _putAll(
          Box<dynamic> box, Map<dynamic, dynamic> entries) =>
      box.putAll(entries);

  /// Reset [stagingWriter]. Call from `tearDown`.
  @visibleForTesting
  static void resetForTest() => stagingWriter = _putAll;

  /// Migrate a pre-encryption plaintext [boxName] into an encrypted box.
  ///
  /// #4372 — this used to open the box WITH the cipher first and expect a
  /// plaintext file to throw. Hive does not throw there: its crash recovery
  /// reads the plaintext frames as corrupt and TRUNCATES the file (#4118).
  /// The plaintext branch was unreachable and every legacy box came back
  /// empty. So the file is now classified from its own frame checksum
  /// ([HiveBoxKeyProbe.classify]) and no keyed open ever touches it:
  ///
  /// * **plaintext** → [migrateToEncrypted];
  /// * **under the key, empty, missing** → nothing to migrate, except a
  ///   staging box a crash left between "plaintext deleted" and "records
  ///   promoted", which is promoted now;
  /// * **unknown** (no Hive path, unreadable file) → the normal path, as
  ///   before: nothing here can tell what the file is.
  ///
  /// Throws when a copy cannot be verified. The plaintext file is then
  /// still intact, the done flag stays unset, and the launch fails into
  /// the cause-unknown recovery screen instead of letting Phase 2 open
  /// the plaintext file with the key — the next launch retries.
  static Future<void> migrateLegacyPlaintextBox(
      String boxName, HiveAesCipher cipher) async {
    final path = HiveDirectoryResolver.hivePath;
    if (path == null) return;
    final BoxFileKind kind;
    final BoxFileKind stagingKind;
    try {
      kind = HiveBoxKeyProbe.classify(_file(path, boxName), cipher);
      stagingKind = HiveBoxKeyProbe.classify(
          _file(path, stagingBoxName(boxName)), cipher);
    } catch (e, st) {
      log.warn('HiveLegacyMigration: "$boxName" could not be classified',
          error: e, stack: st, layer: ErrorLayer.storage);
      return;
    }
    if (kind == BoxFileKind.plaintext) {
      await migrateToEncrypted(
          boxName, await Hive.openBox<dynamic>(boxName), cipher);
      return;
    }
    final mainIsSafe =
        kind == BoxFileKind.empty || kind == BoxFileKind.underKey;
    if (mainIsSafe && stagingKind == BoxFileKind.underKey) {
      await _promote(boxName, cipher);
    }
  }

  /// Copies an already-open plaintext [plain] box into an encrypted box of
  /// the same name (#1686), crash-safe (#4372).
  ///
  /// The records reach disk under the key — in a staging box, verified —
  /// BEFORE the plaintext file is deleted. A failure mid-copy therefore
  /// leaves the plaintext file intact for the next launch; a crash after
  /// the delete leaves the verified staging box, which the next launch
  /// promotes. At no point do the records exist only in memory.
  static Future<void> migrateToEncrypted(
      String boxName, Box<dynamic> plain, HiveAesCipher cipher) async {
    final entries = Map<dynamic, dynamic>.from(plain.toMap());
    final staging = await Hive.openBox<dynamic>(stagingBoxName(boxName),
        encryptionCipher: cipher);
    try {
      await stagingWriter(staging, entries);
      _verify(staging, entries, stagingBoxName(boxName));
    } finally {
      await staging.close();
    }
    await plain.close();
    await Hive.deleteBoxFromDisk(boxName);
    await _promote(boxName, cipher);
    debugPrint('Hive: migrated "$boxName" to encrypted storage '
        '(${entries.length} entries)');
  }

  /// Staging → the real box, verified, then the staging box is deleted.
  /// Every write is an upsert, so a repeat after a crash is harmless.
  static Future<void> _promote(String boxName, HiveAesCipher cipher) async {
    final stagingName = stagingBoxName(boxName);
    final staging =
        await Hive.openBox<dynamic>(stagingName, encryptionCipher: cipher);
    final entries = Map<dynamic, dynamic>.from(staging.toMap());
    await staging.close();
    final target =
        await Hive.openBox<dynamic>(boxName, encryptionCipher: cipher);
    try {
      await target.putAll(entries);
      _verify(target, entries, boxName);
    } finally {
      await target.close();
    }
    await Hive.deleteBoxFromDisk(stagingName);
  }

  static void _verify(
      Box<dynamic> box, Map<dynamic, dynamic> entries, String name) {
    if (box.length < entries.length || !entries.keys.every(box.containsKey)) {
      throw StateError('HiveLegacyMigration: "$name" holds ${box.length} of '
          '${entries.length} records after the copy');
    }
  }

  // Hive lower-cases box names for their files.
  static File _file(String path, String boxName) =>
      File('$path/${boxName.toLowerCase()}.hive');
}
