// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'hive_open_timing.dart';

/// The boxes the FIRST FRAME cannot be painted without, and how they are
/// opened.
///
/// Split out of `HiveBoxes.init` at #4110, which is when the file reached
/// the 400-line cap. It is a real seam rather than a length dodge: the
/// box-name registry (what boxes exist, which are encrypted, which the
/// main isolate owns) is one concern, and "which subset gates the first
/// frame, opened in parallel, each one timed" is another. The deferred
/// set already lives apart for the same reason (#1794).
abstract final class HiveFirstFrameBoxes {
  /// Open every first-frame-critical box in one parallel batch.
  ///
  /// Each open is timed by [HiveOpenTiming] so the startup trace can name
  /// the long pole — the opens run concurrently, so the enclosing
  /// `hive_open` phase never could.
  static Future<void> openAll(HiveAesCipher? cipher) async {
    // #4110 — a local alias so each open stays on one line: the batch
    // has to read as a batch, not as twenty lines of plumbing.
    Future<Box<T>> timed<T>(String n, Future<Box<T>> Function() open) =>
        timed(n, open);

    // Phase 2 — open the first-frame-critical boxes in one parallel
    // batch. #1686 — a box damaged beyond Hive's crash recovery throws
    // here; it is re-tagged as a HiveCorruptionException for the startup
    // error path rather than crashing on a raw HiveError.
    try {
      await Future.wait<Box<dynamic>>([
        timed(HiveBoxes.settings, () => Hive.openBox(HiveBoxes.settings, encryptionCipher: cipher)),
        timed(HiveBoxes.profiles, () => Hive.openBox(HiveBoxes.profiles, encryptionCipher: cipher)),
        timed(HiveBoxes.favorites, () => Hive.openBox(HiveBoxes.favorites, encryptionCipher: cipher)),
        timed(HiveBoxes.cache, () => Hive.openBox(HiveBoxes.cache, encryptionCipher: cipher)),
        timed(HiveBoxes.priceHistory,
            () => Hive.openBox(HiveBoxes.priceHistory, encryptionCipher: cipher)),
        timed(HiveBoxes.alerts, () => Hive.openBox(HiveBoxes.alerts, encryptionCipher: cipher)),
        // #1105 — isolate error spool: the background isolate writes
        // here before Riverpod is available, so it must be open now.
        timed(HiveBoxes.isolateErrorSpool, () => Hive.openBox<String>(HiveBoxes.isolateErrorSpool)),
        // #1373 — central feature-flag set: read during the first build.
        timed(HiveBoxes.featureFlags, () => Hive.openBox<dynamic>(HiveBoxes.featureFlags)),
        // #1517 — active "use mode" profile: gates the first route.
        timed(HiveBoxes.appProfile, () => Hive.openBox<dynamic>(HiveBoxes.appProfile)),
        // #1686 — schema-version meta box. Unencrypted: small integers.
        timed(HiveBoxes.boxSchema, () => Hive.openBox<int>(HiveBoxes.boxSchema)),
      ]);
      // HiveError is Hive's runtime storage-failure type, not a bug.
    } on HiveError catch (e, st) { // ignore: avoid_catching_errors
      // #3979 — keep Hive's own stack (a plain throw dropped the frame
      // naming the corrupt box).
      Error.throwWithStackTrace(HiveCorruptionException(
          'a storage box could not be opened (${e.message})'), st);
    }
  }
}
