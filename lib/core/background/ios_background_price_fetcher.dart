// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'background_price_fetcher.dart';
import 'background_service.dart';

/// iOS implementation of [BackgroundPriceFetcher] using the workmanager
/// iOS backend (BGTaskScheduler) — #2414.
///
/// ## How iOS background scheduling works here (workmanager 0.9.x)
/// On iOS 13+ the plugin maps a Dart [Workmanager.registerPeriodicTask] onto
/// a **BGAppRefreshTask**. Two things must line up for that to work, and they
/// live outside Dart:
///
///   1. `ios/Runner/Info.plist` lists the identifier under
///      `BGTaskSchedulerPermittedIdentifiers` and declares the `fetch` /
///      `processing` `UIBackgroundModes`.
///   2. `ios/Runner/AppDelegate.swift` calls
///      `WorkmanagerPlugin.registerPeriodicTask(withIdentifier:frequency:)`
///      for the SAME identifier, and installs the plugin-registrant callback
///      so plugins (Hive, notifications, etc.) are available in the background
///      Flutter engine.
///
///   The Dart `uniqueName` passed to [Workmanager.registerPeriodicTask] MUST
///   equal that identifier — [IosBackgroundTaskIds.appRefresh]. The
///   `frequency` is set in `AppDelegate.swift`, NOT here: per the plugin docs,
///   "Unlike Android, you cannot set frequency for iOS here rather you have to
///   set in AppDelegate.swift while registering the task."
///
/// ## Honest reliability framing
/// iOS schedules BGAppRefreshTask **opportunistically** against the user's
/// app-usage budget — it is sparse, OS-throttled, and **never real-time**.
/// A task that runs longer than ~30 s may be terminated. WidgetKit cannot
/// trigger a scan on iOS (a widget timeline reload is not a background-task
/// wake), so the home-widget trigger (#2412) is Android-only by design.
///
/// The single shared [callbackDispatcher] handles both the BGAppRefresh wake
/// (reported as [Workmanager.iOSBackgroundTask] for the legacy fetch path, or
/// the [IosBackgroundTaskIds.appRefresh] identifier for the BGTask path) and
/// the Android tasks; it routes everything through
/// [BackgroundAlertScanCoordinator].
class IosBackgroundPriceFetcher implements BackgroundPriceFetcher {
  final Workmanager _workmanager;

  /// Creates an iOS background price fetcher. Accepts an optional
  /// [Workmanager] instance for testing.
  IosBackgroundPriceFetcher({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  @override
  Future<void> init() async {
    await _workmanager.initialize(callbackDispatcher);

    // Schedule the BGAppRefreshTask. The identifier must match the value
    // registered in AppDelegate.swift + Info.plist. iOS owns the cadence;
    // the frequency declared in AppDelegate.swift is a *hint*, not a
    // guarantee — the OS schedules opportunistically.
    await _workmanager.registerPeriodicTask(
      IosBackgroundTaskIds.appRefresh,
      IosBackgroundTaskIds.appRefresh,
    );
    debugPrint(
        'IosBackgroundPriceFetcher: registered BGAppRefreshTask '
        '"${IosBackgroundTaskIds.appRefresh}" (OS-budgeted, best-effort)');
  }

  @override
  Future<void> cancelAll() async {
    await _workmanager.cancelAll();
  }
}
