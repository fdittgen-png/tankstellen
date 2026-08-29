// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/storage_repository.dart';
import '../feedback/feedback_consent.dart';
import '../feedback/github_issue_reporter_provider.dart';
import 'hive_boxes.dart';

/// #3867 (Epic #3865, GDPR Art. 17) — the ONE local erasure.
///
/// "Delete all data" used to clear three boxes and the API key — and leave
/// every recorded GPS trip, the OBD2 baselines, the alerts, the VIN-keyed
/// and MAC-keyed adapter caches, the service reminders and the error
/// traces on the device, while the privacy policy claimed the opposite.
/// Two divergent copies of that wipe existed. This class replaces both:
/// it is driven by [HiveBoxes.allBoxes] (the registry every new box must
/// join — `test/core/storage/local_data_eraser_test.dart` fails otherwise),
/// so a box cannot be forgotten by construction.
class LocalDataEraser {
  LocalDataEraser._();

  /// Wipe everything the app stores on this device.
  ///
  /// [extraWipes] are feature-owned steps core cannot import (the
  /// home-screen widget container, the trip WAL file) — the call sites in
  /// `features/profile` pass them. Every step is independent: a failing
  /// one is logged and the rest still run, so the user never ends up
  /// with a half-erased device because one box was locked.
  static Future<LocalErasureResult> eraseAll({
    required StorageRepository storage,
    List<Future<void> Function()> extraWipes = const [],
  }) async {
    final failed = <String>[];
    Future<void> step(String name, Future<void> Function() run) async {
      try {
        await run();
      } catch (e, st) {
        failed.add(name);
        debugPrint('LocalDataEraser: $name failed: $e\n$st');
      }
    }

    for (final box in HiveBoxes.allBoxes) {
      await step('box:$box', () => _wipeBox(box));
    }
    // Staging boxes a crashed encryption migration may have left behind.
    for (final box in HiveBoxes.allBoxes) {
      final staging = '${box}_enc_staging';
      await step('box:$staging', () async {
        if (await Hive.boxExists(staging)) {
          await Hive.deleteBoxFromDisk(staging);
        }
      });
    }
    await step('apiKeys', storage.deleteAllApiKeys);
    await step('supabaseAnonKey', storage.deleteSupabaseAnonKey);
    await step('githubToken',
        () => const FlutterSecureStorage().delete(key: kGithubFeedbackTokenKey));
    await step('feedbackConsent', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(FeedbackConsent.storageKey);
    });
    await step('imageCache', () async {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    for (var i = 0; i < extraWipes.length; i++) {
      await step('extra:$i', extraWipes[i]);
    }
    return LocalErasureResult(failedSteps: List.unmodifiable(failed));
  }

  /// The box phase alone — no secure storage, prefs or image cache — so a
  /// plain Hive test directory can exercise the registry-driven wipe.
  @visibleForTesting
  static Future<LocalErasureResult> eraseBoxesForTest() async {
    final failed = <String>[];
    for (final box in HiveBoxes.allBoxes) {
      try {
        await _wipeBox(box);
      } catch (e, st) {
        failed.add('box:$box');
        debugPrint('LocalDataEraser: box $box failed: $e\n$st');
      }
    }
    return LocalErasureResult(failedSteps: List.unmodifiable(failed));
  }

  /// An open box is cleared in place (its cipher and file stay valid for
  /// the running app); a closed box that exists on disk is deleted.
  static Future<void> _wipeBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<dynamic>(name).clear();
    } else if (await Hive.boxExists(name)) {
      await Hive.deleteBoxFromDisk(name);
    }
  }
}

/// What [LocalDataEraser.eraseAll] could not erase — empty on success.
/// The UI names the failed steps instead of claiming a clean device.
class LocalErasureResult {
  const LocalErasureResult({required this.failedSteps});
  final List<String> failedSteps;
  bool get complete => failedSteps.isEmpty;
}
