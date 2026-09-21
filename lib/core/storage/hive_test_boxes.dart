// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';
import 'hive_isolate_ownership.dart';

/// The box opens a unit/widget test needs, split out of
/// `HiveBoxes.initForTest` (#4215).
///
/// `hive_boxes.dart` sat at 398 of its 400-line norm, and the F5
/// expense box could not be registered without pushing it over. This
/// is the half that does NOT belong to production box lifecycle: the
/// same opens, unencrypted and without secure storage, standing in for
/// `HiveBoxes.init()` under test. `HiveBoxes.initForTest` delegates
/// here, so every existing call site is unchanged.
///
/// The production sets (`_encryptedBoxes`, `_deferredBoxes`,
/// `_encryptedDeferredBoxes`) deliberately stayed behind: several
/// guards in `test/core/storage/hive_boxes_test.dart` read them out of
/// that file's source, and a set that moves out of the scan is a set
/// that stops being checked.
class HiveTestBoxes {
  HiveTestBoxes._();

  /// Opens the boxes a test needs and marks them main-isolate-owned.
  static Future<void> openAll() async {
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    await Hive.openBox<dynamic>(HiveBoxes.favorites);
    await Hive.openBox<dynamic>(HiveBoxes.cache);
    await Hive.openBox<dynamic>(HiveBoxes.profiles);
    await Hive.openBox<dynamic>(HiveBoxes.priceHistory);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    // #584 — service reminders live in their own box so tests that
    // exercise the vehicle feature can open it without pulling in the
    // rest of the app. String-typed to match runtime.
    await Hive.openBox<String>(HiveBoxes.serviceReminders);
    // #797 — paused trips box, string-typed JSON, matches runtime.
    await Hive.openBox<String>(HiveBoxes.obd2PausedTrips);
    await Hive.openBox<String>(HiveBoxes.obd2NegotiatedProtocol); // #2261
    // #1303 — active-trip snapshot box, string-typed JSON.
    await Hive.openBox<String>(HiveBoxes.obd2ActiveTrip);
    // #579 — velocity detector snapshots. String-typed JSON so the
    // same one-adapter pattern covers unit tests + runtime.
    await Hive.openBox<String>(HiveBoxes.priceSnapshots);
    // #1686 — schema-version meta box, mirrors the runtime open.
    await Hive.openBox<int>(HiveBoxes.boxSchema);
    // #2670 — initForTest stands in for the main isolate's init(): the
    // boxes it opens are main-isolate-owned, so closeIsolateBoxes()
    // leaves them open (mirroring the foreground-isolate scenario).
    HiveIsolateOwnership.markOwned(const [
      HiveBoxes.settings, HiveBoxes.favorites, HiveBoxes.cache,
      HiveBoxes.profiles, HiveBoxes.priceHistory, HiveBoxes.alerts,
      HiveBoxes.serviceReminders, HiveBoxes.obd2PausedTrips,
      HiveBoxes.obd2NegotiatedProtocol, HiveBoxes.obd2ActiveTrip,
      HiveBoxes.priceSnapshots, HiveBoxes.boxSchema,
    ]);
  }
}
