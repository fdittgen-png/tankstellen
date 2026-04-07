import 'package:workmanager/workmanager.dart';

import 'background_price_fetcher.dart';
import 'background_service.dart';

/// Android implementation of [BackgroundPriceFetcher] using WorkManager.
///
/// Registers two periodic tasks with different constraints for
/// adaptive battery-aware scheduling:
/// - Standard task: every 1h, skipped when battery is low
/// - Charging task: every 30min, only when device is plugged in
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

    // Standard task: runs every 1h when battery is not low.
    // Skipped automatically by Android when battery drops below ~15%.
    await _workmanager.registerPeriodicTask(
      BackgroundService.priceRefreshTask,
      BackgroundService.priceRefreshTask,
      frequency: BackgroundService.refreshInterval,
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
