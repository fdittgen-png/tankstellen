// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'hive_cipher_loader.dart';
import 'hive_isolate_ownership.dart';

/// Background-isolate box lifecycle, split out of [HiveBoxes] (#3689).
///
/// A WorkManager scan runs in its own isolate with its own Hive registry,
/// but on the SAME box files the foreground holds open. Hive forbids that
/// (one file, one isolate); [HiveIsolateLock] serialises the background
/// acquirers against each other, yet the foreground keeps its handles open
/// throughout. The one file-level mutation a background open could still
/// perform is COMPACTION: Hive auto-compacts on write/delete thresholds and
/// renames `<box>.hivec` over `<box>.hive` — yanking the file out from
/// under the foreground's open handle. Field log 2026-08-09: a
/// `PathNotFoundException: cannot rename …cache.hivec` followed by a dead
/// foreground cache box (`FileSystemException: File closed` on every put
/// until restart). Every background open therefore pins
/// [_neverCompact] — a background isolate reads and writes, but NEVER
/// rewrites the file. The foreground (sole long-lived owner) keeps Hive's
/// default compaction.
class HiveIsolateBoxes {
  HiveIsolateBoxes._();

  /// #3689 — background isolates must never rename box files. See class doc.
  static bool _neverCompact(int entries, int deletedEntries) => false;

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    await Hive.initFlutter();
    final cipher = await HiveCipherLoader.loadGuarded();
    Future<Box<T>> open<T>(String name, {HiveAesCipher? boxCipher}) =>
        Hive.openBox<T>(name,
            encryptionCipher: boxCipher, compactionStrategy: _neverCompact);
    await open<dynamic>(HiveBoxes.settings, boxCipher: cipher);
    await open<dynamic>(HiveBoxes.favorites, boxCipher: cipher);
    // #2205 — BG widget reads the profile.
    await open<dynamic>(HiveBoxes.profiles, boxCipher: cipher);
    await open<dynamic>(HiveBoxes.alerts, boxCipher: cipher);
    await open<dynamic>(HiveBoxes.cache, boxCipher: cipher);
    await open<dynamic>(HiveBoxes.priceHistory, boxCipher: cipher);
    // #579 — velocity detector reads/writes snapshots from the BG
    // isolate, mirroring the main-isolate open above.
    await open<String>(HiveBoxes.priceSnapshots);
    // #1105 — isolate error spool: background-isolate errors written
    // here while Riverpod is unavailable, drained by the foreground
    // initialiser into TraceRecorder.
    await open<String>(HiveBoxes.isolateErrorSpool);
    // #2866 — feature flags (uncipher'd, mirroring the foreground open) so the
    // background scan can read the developer-mode flag to dev-gate the #2824
    // data-access trace export. Best-effort; the scan no-ops the trace if this
    // is unavailable.
    await open<dynamic>(HiveBoxes.featureFlags);
  }

  /// Close the Hive boxes opened by [initInIsolate] at the end of a
  /// background task to release file handles.
  ///
  /// #2670 — boxes [HiveIsolateOwnership] records as main-isolate-owned (from
  /// `HiveBoxes.init` / `initDeferred` / `initForTest`) are **skipped**: when
  /// the scan ran inside the foreground isolate these are the live, shared
  /// global handles the rest of the app still uses, and closing them produced
  /// the `FileSystemException: File closed, path='…/cache.hive'` field crash.
  /// A true spawned `dart:isolate` worker never ran `init`, so its registry
  /// is empty and every [initInIsolate] handle is still closed.
  static Future<void> closeIsolateBoxes() async {
    final boxNames = [
      HiveBoxes.settings,
      HiveBoxes.favorites,
      HiveBoxes.alerts,
      HiveBoxes.cache,
      HiveBoxes.priceHistory,
      HiveBoxes.priceSnapshots,
      HiveBoxes.isolateErrorSpool,
      HiveBoxes.featureFlags,
    ];
    for (final name in boxNames) {
      if (HiveIsolateOwnership.isOwned(name)) continue;
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<dynamic>(name).close();
        }
      } catch (e, st) {
        debugPrint('HiveIsolateBoxes: failed to close box "$name": $e\n$st');
      }
    }
  }
}
