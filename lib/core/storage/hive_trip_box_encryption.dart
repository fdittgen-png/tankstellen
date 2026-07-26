// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../logging/error_logger.dart';

/// One-time migration of the four plaintext OBD2 trip boxes into
/// encrypted storage (#3611 — security-audit wave 1).
///
/// The trip boxes (`obd2_trip_history`, `obd2_active_trip`,
/// `obd2_paused_trips`, `obd2_baselines`) historically opened WITHOUT
/// the AES cipher the rest of the PII-bearing boxes use. Trips carry
/// driving telemetry (timestamps, distances, GPS paths since #1374), so
/// wave 1 moves them under the same [HiveAesCipher] that
/// `HiveCipherLoader` provides — with a crash-safe on-disk migration.
///
/// ## Why a persisted marker instead of an open-probe
/// Opening a Hive box in the WRONG mode (plain file with a cipher, or
/// encrypted file without one) does not reliably throw — Hive runs its
/// crash recovery ("Recovering corrupted box."), discards every frame
/// it cannot decode and TRUNCATES the file. A probe-by-open therefore
/// destroys the very data it probes. The migration instead stamps
/// `<box>.encrypted` into the `box_schema` meta box (the #1686
/// schema-version box) and NEVER opens a box in a mode the marker
/// state doesn't guarantee.
///
/// ## Crash safety (never lose trips)
/// A Hive box name maps to ONE file, so the plain and encrypted forms
/// cannot coexist under the canonical name. The migration stages
/// through a sibling encrypted box, copying BEFORE deleting:
///
/// 1. plain `X` → encrypted staging `X_enc_staging` (upsert, idempotent)
/// 2. stamp `X.encrypted` in the meta box (from here on `X` is only
///    ever opened WITH the cipher)
/// 3. delete plain `X` (its data is durably held in staging)
/// 4. encrypted staging → encrypted `X` (upsert, idempotent)
/// 5. delete staging
///
/// A crash between any two steps is recovered on the next launch: a
/// surviving staging box is the "promotion pending" marker, every copy
/// is an upsert, and a leftover plain file after step 2 is safely
/// superseded by the complete staging copy. At no point does trip data
/// exist only in memory.
class HiveTripBoxEncryption {
  HiveTripBoxEncryption._();

  /// Name of the schema meta box (`HiveBoxes.boxSchema`). Duplicated
  /// here (rather than importing `hive_boxes.dart`, which imports this
  /// file) — the #1686 box name is pinned by tests and stable.
  static const String metaBoxName = 'box_schema';

  /// Suffix of the crash-recovery staging box (its existence doubles as
  /// the "promotion in progress" marker on disk).
  @visibleForTesting
  static String stagingBoxName(String boxName) => '${boxName}_enc_staging';

  /// Meta-box key stamping that [boxName] now stores encrypted data.
  @visibleForTesting
  static String encryptedMarkerKey(String boxName) => '$boxName.encrypted';

  /// Test seam for the plaintext open — lets a fault-injection test
  /// drive the unreadable-box path without depending on how a given
  /// Hive version surfaces file corruption (its crash recovery often
  /// salvages-and-truncates instead of throwing).
  @visibleForTesting
  static Future<Box<String>> Function(String boxName) plainOpener =
      _defaultPlainOpener;

  static Future<Box<String>> _defaultPlainOpener(String boxName) =>
      Hive.openBox<String>(boxName);

  /// Reset the [plainOpener] seam. Call from `tearDown`.
  @visibleForTesting
  static void resetForTesting() {
    plainOpener = _defaultPlainOpener;
  }

  /// Migrates a formerly-plaintext trip box [boxName] to encrypted
  /// storage under [cipher], resuming any interrupted migration first.
  ///
  /// Never throws: a fault here must not take down `initDeferred` — the
  /// subsequent encrypted open surfaces any box that is genuinely
  /// unreadable. A plain box that cannot be read is LEFT ON DISK
  /// untouched (mirroring `HiveLegacyMigration`), never deleted.
  static Future<void> migrate(String boxName, HiveAesCipher cipher) async {
    final staging = stagingBoxName(boxName);
    try {
      final meta = await Hive.openBox<int>(metaBoxName);
      final stamped = meta.get(encryptedMarkerKey(boxName)) == 1;
      final hasStaging = await Hive.boxExists(staging);
      if (stamped && !hasStaging) return; // fast path: already migrated

      if (!stamped) {
        if (await Hive.boxExists(boxName)) {
          // Legacy plaintext box on disk (the marker guarantees it was
          // never written with the cipher) — stage its entries under
          // the cipher BEFORE deleting or stamping anything.
          Box<String> plain;
          try {
            plain = await plainOpener(boxName);
          } catch (e, st) {
            // Unreadable even as plaintext: damaged. Leave the file on
            // disk for recovery, but stamp so the box is only ever
            // opened encrypted from now on — future trips stay safe.
            unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
              'where': 'HiveTripBoxEncryption: plaintext open failed',
              'box': boxName,
            }));
            await meta.put(encryptedMarkerKey(boxName), 1);
            return;
          }
          final entries = Map<dynamic, String>.from(plain.toMap());
          final stagingBox =
              await Hive.openBox<String>(staging, encryptionCipher: cipher);
          await stagingBox.putAll(entries); // upsert — idempotent on retry
          await stagingBox.close();
          await plain.close();
          // Every entry is durably staged: stamp, then drop the plain file.
          await meta.put(encryptedMarkerKey(boxName), 1);
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('Hive: staged "$boxName" for encryption '
              '(${entries.length} entries)');
        } else {
          // Fresh install — nothing to migrate, stamp and move on.
          await meta.put(encryptedMarkerKey(boxName), 1);
        }
      }

      if (await Hive.boxExists(staging)) {
        await _promoteStaging(boxName, staging, cipher);
        // Belt-and-braces for the resumed-promotion path (a crash after
        // staging but before the stamp cannot occur in the step order
        // above, but stamping here keeps the invariant self-healing).
        await meta.put(encryptedMarkerKey(boxName), 1);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': 'HiveTripBoxEncryption: migration failed',
        'box': boxName,
      }));
    }
  }

  /// Copies the staged encrypted entries into the canonical encrypted
  /// [boxName] (upsert) and removes the staging box. Idempotent — safe
  /// to re-run after a crash at any point. A leftover plain file under
  /// [boxName] (crash between stamp and delete) is superseded here: the
  /// cipher open discards it and the complete staging copy refills it.
  static Future<void> _promoteStaging(
      String boxName, String staging, HiveAesCipher cipher) async {
    final stagingBox =
        await Hive.openBox<String>(staging, encryptionCipher: cipher);
    final target =
        await Hive.openBox<String>(boxName, encryptionCipher: cipher);
    await target.putAll(Map<dynamic, String>.from(stagingBox.toMap()));
    await target.close();
    await stagingBox.close();
    await Hive.deleteBoxFromDisk(staging);
    debugPrint('Hive: "$boxName" migrated to encrypted storage');
  }
}
