// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:workmanager/workmanager.dart';

import 'background_price_fetcher.dart';
import 'background_service.dart';

/// Android implementation of [BackgroundPriceFetcher] using WorkManager.
///
/// Registers ONE periodic alert/price-scan task at the twice-daily cadence
/// (~every 12h, [BackgroundService.refreshInterval]) — the Epic #2860 EXIT
/// GATE (#2866) rate-limit / ToS safeguard for the now-multi-country scan.
/// The task is skipped when the battery is low ([requiresBatteryNotLow]).
/// The old 30-min charging task was removed: it would have let a multi-country
/// scan hit a provider more than twice a day, breaching the cadence guarantee.
///
/// #2413 — the task carries a `NetworkType.connected` constraint so a wake
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

    // #2300 — register with ExistingPeriodicWorkPolicy.update so a repeated
    // init() (every app launch) is idempotent: it refreshes the existing task
    // instead of stacking duplicate periodic work that could fire two refresh
    // isolates in the same window. Concurrent-access safety is still
    // backstopped by HiveIsolateLock's exclusive lock.

    // Twice-daily task (#2866): runs ~every 12h when battery is not low.
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
  }

  @override
  Future<void> cancelAll() async {
    await _workmanager.cancelAll();
  }
}
