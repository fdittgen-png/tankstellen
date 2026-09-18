// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The iOS BGTask identifiers and the processing-lane submission (#2414,
/// #3169). Moved out of `background_service.dart` (which re-exports this
/// file) when the schedule's owner (#4162) needed the room under the
/// 400-line cap.
library;

import 'package:workmanager/workmanager.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';

/// Submit (or replace) the pending BGProcessingTask request (#3169).
///
/// One scheduling surface shared by [IosBackgroundPriceFetcher.init] (arm
/// on every reconcile) and [callbackDispatcher] (re-arm after each run,
/// because a processing submission is one-shot). `earliestBeginDate` is the
/// delay below; iOS then runs the task in an idle window of its choosing —
/// typically overnight, often while charging. Requires network (the scan is
/// useless without it) but NOT external power, to maximise run chances.
///
/// Never throws — scheduling is best-effort; the host side already logs a
/// rejected submission. A failure here must not fail the scan that
/// triggered the re-arm.
Future<void> scheduleIosProcessingTask(Workmanager workmanager) async {
  try {
    await workmanager.registerProcessingTask(
      IosBackgroundTaskIds.processing,
      IosBackgroundTaskIds.processing,
      initialDelay: IosBackgroundTaskIds.processingEarliestDelay,
      constraints: Constraints(networkType: NetworkType.connected),
    );
    log.debug(
        'BGProcessingTask armed ("${IosBackgroundTaskIds.processing}", '
        'OS-budgeted, best-effort)',
        tag: 'BackgroundService');
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.background, context: const {'where': 'scheduleIosProcessingTask'});
  }
}

/// iOS BGTaskScheduler identifiers. Must match the values registered in
/// `ios/Runner/AppDelegate.swift` and listed under
/// `BGTaskSchedulerPermittedIdentifiers` in `ios/Runner/Info.plist` — all
/// three break together (#2414).
class IosBackgroundTaskIds {
  IosBackgroundTaskIds._();

  /// BGAppRefreshTask identifier for the periodic price scan.
  // i18n-ignore: bundle-id-derived task identifier, not user-facing.
  static const String appRefresh = 'de.tankstellen.tankstellen.background';

  /// BGProcessingTask identifier (#3169) — the second BGTask lane. Must be
  /// listed in `BGTaskSchedulerPermittedIdentifiers` and registered via
  /// `WorkmanagerPlugin.registerBGProcessingTask` in AppDelegate.swift.
  // i18n-ignore: bundle-id-derived task identifier, not user-facing.
  static const String processing = 'de.tankstellen.tankstellen.processing';

  /// One-off task identifier the native SlcWakeBridge enqueues on a
  /// significant-location-change wake (#3169). NOT a BGTask — it rides a
  /// plain `beginBackgroundTask` window, so it needs no Info.plist entry;
  /// it only has to match `SlcWakeBridge.taskIdentifier` in
  /// AppDelegate.swift.
  // i18n-ignore: bundle-id-derived task identifier, not user-facing.
  static const String slcWake = 'de.tankstellen.tankstellen.slcWake';

  /// One-off task identifier for the opportunistic foreground-wake scan
  /// (#3169). Like [slcWake], a `beginBackgroundTask` one-off — no
  /// Info.plist entry needed.
  // i18n-ignore: bundle-id-derived task identifier, not user-facing.
  static const String opportunistic =
      'de.tankstellen.tankstellen.opportunistic';

  /// Earliest-begin delay for a BGProcessingTask submission. Long enough
  /// that the lane complements (rather than duplicates) the BGAppRefresh
  /// lane and the foreground opportunistic scans; iOS adds its own idle
  /// scheduling on top, typically landing the run overnight.
  static const Duration processingEarliestDelay = Duration(hours: 4);
}
