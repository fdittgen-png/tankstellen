// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'hive_cipher_loader.dart';
import 'hive_isolate_ownership.dart';
import 'impl/hive_directory_resolver.dart';
import '../logging/app_log.dart';
import '../logging/error_logger.dart';

/// One background-isolate box: its name, whether it is encrypted, and —
/// carried in [T] — the value type it is opened at (#4053).
///
/// The type is the whole point of this class existing. `HiveIsolateBoxes`
/// used to keep the open set and the close set as two hand-written lists,
/// and both possible drifts had happened by the time the field log of
/// 2026-09-11 was exported: `price_snapshots` and `isolate_error_spool`
/// are opened as `Box<String>` but were closed through
/// `Hive.box<dynamic>(name)`, which throws "already open and of type
/// Box[String]" — 30 of that export's 48 traces, one pair per background
/// scan, neither box ever released — while `profiles` was absent from the
/// close list altogether and leaked in silence.
///
/// [open] and [closeIfOpen] both resolve `T` from the instance, so a
/// `_IsolateBox<String>` sitting in a `List<_IsolateBox<Object?>>` list still
/// closes at `Box<String>`. One list, walked in both directions: a box
/// cannot be opened and then forgotten, nor closed at the wrong type.
class _IsolateBox<T> {
  const _IsolateBox(this.name, {this.ciphered = false});

  final String name;
  final bool ciphered;

  Future<void> open(HiveAesCipher? cipher) async {
    await Hive.openBox<T>(
      name,
      encryptionCipher: ciphered ? cipher : null,
      compactionStrategy: HiveIsolateBoxes.neverCompact,
    );
  }

  Future<void> closeIfOpen() async {
    if (Hive.isBoxOpen(name)) await Hive.box<T>(name).close();
  }
}

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
  static bool neverCompact(int entries, int deletedEntries) => false;

  /// The ONE box set a background isolate opens — walked by
  /// [initInIsolate] to open and by [closeIsolateBoxes] to close, so the
  /// two can never disagree about membership or value type (#4053).
  ///
  /// Adding a box here is the only step needed; there is no second list
  /// to remember.
  static const List<_IsolateBox<Object?>> _boxes = [
    _IsolateBox<dynamic>(HiveBoxes.settings, ciphered: true),
    _IsolateBox<dynamic>(HiveBoxes.favorites, ciphered: true),
    // #2205 — BG widget reads the profile.
    _IsolateBox<dynamic>(HiveBoxes.profiles, ciphered: true),
    _IsolateBox<dynamic>(HiveBoxes.alerts, ciphered: true),
    _IsolateBox<dynamic>(HiveBoxes.cache, ciphered: true),
    _IsolateBox<dynamic>(HiveBoxes.priceHistory, ciphered: true),
    // #579 — velocity detector reads/writes snapshots from the BG
    // isolate, mirroring the main-isolate open above.
    _IsolateBox<String>(HiveBoxes.priceSnapshots),
    // #2866 — feature flags (uncipher'd, mirroring the foreground open) so
    // the background scan can read the developer-mode flag to dev-gate the
    // #2824 data-access trace export. Best-effort; the scan no-ops the
    // trace if this is unavailable.
    _IsolateBox<dynamic>(HiveBoxes.featureFlags),
    // #1105 — isolate error spool: background-isolate errors written
    // here while Riverpod is unavailable, drained by the foreground
    // initialiser into TraceRecorder. #4067 — LAST on purpose: a warn
    // about any other box's close routes into this spool and would
    // re-open it, so every warn is emitted before this one closes.
    _IsolateBox<String>(HiveBoxes.isolateErrorSpool),
  ];

  /// The names [initInIsolate] opens — the drift-guard test reads this.
  @visibleForTesting
  static List<String> get isolateBoxNames =>
      [for (final b in _boxes) b.name];

  /// Initialize Hive in a background isolate with proper encryption.
  static Future<void> initInIsolate() async {
    // #3747 — must resolve the SAME base dir as HiveBoxes.init (on iOS:
    // Application Support), or a background isolate would open a
    // parallel empty box set in Documents.
    await HiveDirectoryResolver.initHive();
    final cipher = await HiveCipherLoader.loadGuarded();
    for (final box in _boxes) {
      await box.open(cipher);
    }
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
    // #4067 — collect first, warn second, close the spool third. In a
    // background isolate `log.warn` lands in IsolateErrorSpool, which
    // lazily re-opens `isolate_error_spool`; warning while walking used to
    // re-open the very handle this walk had just released.
    final failures = <(String, Object, StackTrace)>[];
    for (final box in _boxes) {
      if (box.name == HiveBoxes.isolateErrorSpool) continue;
      if (HiveIsolateOwnership.isOwned(box.name)) continue;
      try {
        await box.closeIfOpen();
      } catch (e, st) {
        failures.add((box.name, e, st));
      }
    }
    for (final (name, e, st) in failures) {
      log.warn('HiveIsolateBoxes: failed to close box "$name"',
          error: e, stack: st, layer: ErrorLayer.storage);
    }
    // The spool itself, last. If THIS close fails the spool is still
    // open, so the warn below re-opens nothing — it is the one warn that
    // cannot cause the #4067 leak.
    // The spool itself, last. If THIS close fails the spool is still
    // open, so the warn below re-opens nothing — it is the one warn that
    // cannot cause the #4067 leak.
    if (HiveIsolateOwnership.isOwned(HiveBoxes.isolateErrorSpool)) return;
    try {
      if (Hive.isBoxOpen(HiveBoxes.isolateErrorSpool)) {
        await Hive.box<String>(HiveBoxes.isolateErrorSpool).close();
      }
    } catch (e, st) {
      log.warn('HiveIsolateBoxes: failed to close the error spool',
          error: e, stack: st, layer: ErrorLayer.storage);
    }
  }
}
