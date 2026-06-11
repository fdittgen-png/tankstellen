// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../storage/hive_boxes.dart';

/// Per-install device identity for multi-device sync forensics (#3125).
///
/// With cross-device identity shipped (#3079/#3080) the same account
/// writes from several phones, but synced rows and tombstones carried no
/// origin marker — "which of my two phones deleted this vehicle, and was
/// it the buggy build?" was unanswerable. Sync writes now stamp:
///
/// - [deviceId] — a random UUID minted once per install and persisted in
///   the `settings` Hive box. It identifies the *install*, not the user
///   or the hardware (no serial / IDFA / fingerprint), so it adds no
///   tracking surface: it only ever travels to the user's own sync rows,
///   which RLS already scopes to the user.
/// - [appVersion] — the running build, so a misbehaving release is
///   attributable after the fact.
///
/// The id is lazily minted on first use. If the settings box isn't open
/// (background isolate, unit test), the minted id is session-stable but
/// not persisted — forensics still distinguish devices within the
/// session, and the next foreground use persists a durable one.
class SyncDeviceIdentity {
  SyncDeviceIdentity._();

  /// The `settings`-box key the install id persists under.
  static const settingsKey = 'sync_device_id';

  static String? _cached;

  /// The stable per-install device id (random UUID — see class doc).
  /// Never throws: a storage fault degrades to a session-stable id.
  static String get deviceId {
    final cached = _cached;
    if (cached != null) return cached;
    String? id;
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        final box = Hive.box(HiveBoxes.settings);
        id = box.get(settingsKey) as String?;
        if (id == null) {
          id = const Uuid().v4();
          unawaited(box.put(settingsKey, id));
        }
      }
    } catch (e, st) {
      debugPrint('SyncDeviceIdentity: settings box unavailable ($e) — '
          'using a session-stable id\n$st');
      id = null;
    }
    return _cached = id ?? const Uuid().v4();
  }

  /// The running app build, stamped alongside [deviceId].
  static String get appVersion => AppConstants.appVersion;

  /// Clear (or pin) the cached id between tests.
  @visibleForTesting
  static void resetForTest([String? id]) => _cached = id;
}
