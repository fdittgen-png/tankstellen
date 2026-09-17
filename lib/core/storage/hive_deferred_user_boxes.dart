// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../error/guarded.dart';
import '../logging/error_logger.dart';
import 'hive_boxes.dart';
import 'hive_open_timing.dart';

/// Encrypted USER-DATA boxes that no initial route reads, opened after the
/// first frame or on first use (#4318).
///
/// `HiveFirstFrameBoxes` used to open these before the app could launch.
/// `Hive.openBox` decrypts and deserializes every value on the main
/// isolate — #4110 is the standing proof of what that costs once a box
/// grows — so a box belongs there only when a supported cold-start route
/// reads it synchronously. `priceHistory` does not: its readers are the
/// station detail (which awaits it, below), two widget refreshers and the
/// privacy dashboard, and every one of them now waits here first.
///
/// ## Contract
///
/// * **Single-flight and idempotent.** Every caller of [ensureOpen] for a
///   box shares ONE open future; an open box answers immediately.
/// * **Same key, same corruption semantics.** The cipher is the one
///   `HiveBoxes.init` loaded and checked against the files on disk (#4118),
///   passed in by [arm] — no second KeyStore read. A box Hive cannot open
///   surfaces as the same [HiveCorruptionException] the first-frame batch
///   raises, is logged, and its file is left on disk. The failure is
///   remembered: this launch does not retry a damaged file.
/// * **Unarmed means unmanaged.** Before `HiveBoxes.init` has armed it
///   (widget tests, `HiveStorage.initForTest`, background isolates that
///   open their own boxes) this class opens nothing and every gate passes.
abstract final class HiveDeferredUserBoxes {
  /// The boxes managed here.
  static const Set<String> names = {HiveBoxes.priceHistory};

  static bool _armed = false;
  static HiveAesCipher? _cipher;
  static final Map<String, Future<void>> _opens = {};

  /// The open itself — a seam so a race or corruption test can hold or
  /// fail it. Production: `Hive.openBox` with the armed cipher.
  @visibleForTesting
  static Future<Box<dynamic>> Function(String name, HiveAesCipher? cipher)
      opener = _hiveOpen;

  /// A failing `Hive.openBox` rethrows to its awaiter AND completes its
  /// internal `_openingBoxes` completer with the same error, which nobody
  /// listens to — an uncaught async error on top of the real one (the
  /// trap `IsolateErrorSpool` documents). The open runs in a guarded zone
  /// so only the awaited copy reaches [_open]'s typed handling.
  static Future<Box<dynamic>> _hiveOpen(String name, HiveAesCipher? cipher) {
    final result = Completer<Box<dynamic>>();
    unawaited(runZonedGuarded<Future<void>>(() async {
      try {
        result.complete(
            await Hive.openBox<dynamic>(name, encryptionCipher: cipher));
      } catch (e, st) {
        if (!result.isCompleted) result.completeError(e, st);
      }
    }, (e, st) {
      // The orphaned duplicate lands here; forward it only if the awaited
      // copy has not already settled the result.
      if (!result.isCompleted) result.completeError(e, st);
    }));
    return result.future;
  }

  /// Hands over the cipher `HiveBoxes.init` loaded. From here on, a closed
  /// managed box is opened on demand.
  static void arm(HiveAesCipher? cipher) {
    _armed = true;
    _cipher = cipher;
  }

  /// Whether a synchronous reader of [name] may read now: the box is open,
  /// or it is not managed in this process. False only while it is opening
  /// or after it failed to open.
  static bool isReadable(String name) => !_armed || Hive.isBoxOpen(name);

  /// Opens [name] once; concurrent callers share the same future. Throws
  /// [HiveCorruptionException] when the box cannot be opened.
  static Future<void> ensureOpen(String name) {
    assert(names.contains(name), '$name is not a deferred user-data box');
    if (!_armed || Hive.isBoxOpen(name)) return _opens[name] ?? Future.value();
    return _opens[name] ??= _open(name);
  }

  /// [ensureOpen] for callers that only need to WAIT: completes normally
  /// once the attempt has finished, whatever its outcome (the failure is
  /// already logged). Pair with [isReadable].
  static Future<void> settled(String name) =>
      ensureOpen(name).then<void>((_) {}, onError: (Object _) {});

  /// Waits for [name], then runs [body] only if the box is readable — for
  /// post-frame housekeeping that must neither read a closed box nor fail
  /// again on one whose failure is already logged.
  static Future<void> whenReadable(
      String name, Future<Object?> Function() body) async {
    await settled(name);
    if (isReadable(name)) await body();
  }

  static Future<void> _open(String name) async {
    try {
      await HiveOpenTiming.timed(name, () => opener(name, _cipher),
          phase: HiveOpenTiming.deferredPhase);
      // HiveError is Hive's runtime storage-failure type, not a bug.
    } on HiveError catch (e, st) { // ignore: avoid_catching_errors
      final failure = HiveCorruptionException(
          'the deferred box "$name" could not be opened (${e.message})');
      logFailure(failure, st,
          where: 'HiveDeferredUserBoxes.ensureOpen',
          layer: ErrorLayer.storage,
          extra: {'box': name});
      Error.throwWithStackTrace(failure, st);
    }
  }

  /// Test isolation only.
  @visibleForTesting
  static void resetForTest() {
    _armed = false;
    _cipher = null;
    _opens.clear();
    opener = _hiveOpen;
  }
}
