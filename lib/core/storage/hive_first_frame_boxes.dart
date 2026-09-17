// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'hive_open_timing.dart';

/// One box the first frame cannot be painted without: its name, the
/// initial-route reader that makes it so, and how it is opened.
typedef FirstFrameBox = ({
  String name,
  String consumer,
  Future<Box<dynamic>> Function(HiveAesCipher? cipher) open,
});

/// The boxes the FIRST FRAME cannot be painted without, and how they are
/// opened.
///
/// Split out of `HiveBoxes.init` at #4110, which is when the file reached
/// the 400-line cap. It is a real seam rather than a length dodge: the
/// box-name registry (what boxes exist, which are encrypted, which the
/// main isolate owns) is one concern, and "which subset gates the first
/// frame, opened in parallel, each one timed" is another. The deferred
/// set already lives apart for the same reason (#1794).
///
/// ## A contract, not a list (#4318)
///
/// Every box here names the initial-route consumer that reads it before
/// or while the first useful screen renders — and
/// `test/app/startup/first_frame_route_matrix_test.dart` RUNS those routes
/// with only these boxes open. A box that cannot name one does not belong:
/// `openBox` deserializes every value on the main isolate before the app
/// can launch. #4318 moved `priceHistory` (to `HiveDeferredUserBoxes`) and
/// the isolate error spool (opened lazily by `IsolateErrorSpool`) out.
abstract final class HiveFirstFrameBoxes {
  /// The verified first-frame storage contract (#4318).
  static final List<FirstFrameBox> contract = [
    (
      name: HiveBoxes.settings,
      consumer: 'router redirect — consent + setup gates; tile proxy and '
          'Sentry consent read before runApp',
      open: (c) => Hive.openBox(HiveBoxes.settings, encryptionCipher: c),
    ),
    (
      name: HiveBoxes.profiles,
      consumer: 'landing resolution (active profile landingScreen) and the '
          '#555 default-profile seed',
      open: (c) => Hive.openBox(HiveBoxes.profiles, encryptionCipher: c),
    ),
    (
      name: HiveBoxes.favorites,
      consumer: 'favorites landing — FavoriteStations.build lists the '
          'stored stations synchronously; a closed box reads as empty',
      open: (c) => Hive.openBox(HiveBoxes.favorites, encryptionCipher: c),
    ),
    (
      name: HiveBoxes.cache,
      consumer: 'search/map landing auto-search on the first post-frame '
          'callback — the chain reads cache-first, a closed box is a silent '
          'miss that turns cached prices into a network wait',
      open: (c) => Hive.openBox(HiveBoxes.cache, encryptionCipher: c),
    ),
    (
      name: HiveBoxes.alerts,
      consumer: 'favorites landing on a wide/landscape screen renders '
          'AlertsBody beside the list; the sync AlertNotifier reads it',
      open: (c) => Hive.openBox(HiveBoxes.alerts, encryptionCipher: c),
    ),
    (
      // #1373 — central feature-flag set: read during the first build.
      name: HiveBoxes.featureFlags,
      consumer: 'enabledFeaturesProvider during the first build',
      open: (_) => Hive.openBox<dynamic>(HiveBoxes.featureFlags),
    ),
    (
      // #1517 — active "use mode" profile: gates the first route.
      name: HiveBoxes.appProfile,
      consumer: 'use-mode profile that gates the onboarding route',
      open: (_) => Hive.openBox<dynamic>(HiveBoxes.appProfile),
    ),
    (
      // #1686 — schema-version meta box. Unencrypted: small integers.
      name: HiveBoxes.boxSchema,
      consumer: 'schema stamps + migration guard run before launch',
      open: (_) => Hive.openBox<int>(HiveBoxes.boxSchema),
    ),
  ];

  /// The box names in [contract].
  static Set<String> get names => {for (final box in contract) box.name};

  /// Open every first-frame-critical box in one parallel batch.
  ///
  /// Each open is timed by [HiveOpenTiming] so the startup trace can name
  /// the long pole — the opens run concurrently, so the enclosing
  /// `hive_open` phase never could.
  ///
  /// #4116 — the timing call MUST name HiveOpenTiming explicitly. A bulk
  /// rename once turned a local alias into `timed(n, open) => timed(n,
  /// open)`, which recursed on every cold start inside the boxes the first
  /// frame cannot be painted without, while 16,626 tests that read the
  /// SOURCE TEXT passed. The batch is executed by its tests now.
  static Future<void> openAll(HiveAesCipher? cipher) async {
    // Phase 2 — #1686: a box damaged beyond Hive's crash recovery throws
    // here; it is re-tagged as a HiveCorruptionException for the startup
    // error path rather than crashing on a raw HiveError.
    try {
      await Future.wait<Box<dynamic>>([
        for (final box in contract)
          HiveOpenTiming.timed(box.name, () => box.open(cipher)),
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
