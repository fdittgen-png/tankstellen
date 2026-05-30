// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:workmanager/workmanager.dart';

import 'background_price_fetcher.dart';
import 'background_service.dart';

/// Android implementation of [BackgroundPriceFetcher] using WorkManager.
///
/// Registers two periodic tasks with different constraints for
/// adaptive battery-aware scheduling:
/// - Standard task: every 1h, skipped when battery is low
/// - Charging task: every 30min, only when device is plugged in
///
/// #2413 — both tasks carry a `NetworkType.connected` constraint so a wake
/// without connectivity is deferred by WorkManager instead of firing a dead
/// request. The schedule is re-established after a reboot by [BootReceiver]
/// (Android) re-running [BackgroundService.init] via the `bootReregister`
/// one-off task.
class AndroidBackgroundPriceFetcher implements BackgroundPriceFetcher {
  final Workmanager _workmanager;

  /// Creates an Android background price fetcher.
  ///
  /// Accepts an optional [Workmanager] instance for testing.
  AndroidBackgroundPriceFetcher({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  @override
  Future<void> init() async {
    await _workmanager.initialize(callbackDispatcher);

    // #2300 — register both tasks with ExistingPeriodicWorkPolicy.update so a
    // repeated init() (every app launch) is idempotent: it refreshes the
    // existing chain instead of stacking duplicate periodic work that could
    // fire two refresh isolates in the same window. Concurrent-access safety
    // between the two cadences is still backstopped by HiveIsolateLock's
    // exclusive lock.

    // Standard task: runs every 1h when battery is not low.
    // Skipped automatically by Android when battery drops below ~15%.
    await _workmanager.registerPeriodicTask(
      BackgroundService.priceRefreshTask,
      BackgroundService.priceRefreshTask,
      frequency: BackgroundService.refreshInterval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );

    // Charging task: runs every 30min when device is plugged in.
    // Gives fresher prices at no battery cost.
    await _workmanager.registerPeriodicTask(
      BackgroundService.priceRefreshChargingTask,
      BackgroundService.priceRefreshChargingTask,
      frequency: BackgroundService.chargingRefreshInterval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresCharging: true,
      ),
    );
  }

  @override
  Future<void> cancelAll() async {
    await _workmanager.cancelAll();
  }
}
