import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/alerts/data/repositories/alert_repository.dart';
import '../../features/price_history/data/models/price_record.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/widget/data/home_widget_service.dart';
import '../constants/field_names.dart';
import '../notifications/local_notification_service.dart';
import '../services/impl/tankerkoenig_batch_price_fetcher.dart';
import '../storage/hive_storage.dart';
import '../utils/json_extensions.dart';
import 'background_price_fetcher_provider.dart';
import 'background_retry.dart';
import 'hive_isolate_lock.dart';

/// Constants and callback logic for background price refresh tasks.
///
/// ## Why a separate isolate?
/// WorkManager runs tasks in a separate Dart isolate (a lightweight thread).
/// This means:
/// - No access to the Riverpod provider graph (providers live in the main isolate)
/// - No access to BuildContext or Flutter widgets
/// - Must re-initialize Hive (each isolate has its own memory space)
/// - Must use Dio directly instead of service providers
///
/// ## What runs in background:
/// 1. Fetch latest prices for all favorite + alert stations (Tankerkoenig API)
/// 2. Record price history to Hive (dedup: skip if last record < 60 min ago)
/// 3. Update cached station data with fresh prices
/// 4. Evaluate alert thresholds and fire local push notifications
///
/// ## Frequency: Adaptive based on battery/charger state
/// - **Charging**: every 30 minutes (more frequent updates while plugged in)
/// - **On battery (not low)**: every 1 hour (standard interval)
/// - **Low battery**: tasks are skipped by WorkManager constraints
///
/// ## Platform abstraction
/// Task scheduling is handled by [BackgroundPriceFetcher] implementations:
/// - Android: [AndroidBackgroundPriceFetcher] (WorkManager)
/// - iOS: [IosBackgroundPriceFetcherStub] (no-op placeholder)
///
/// Use [createBackgroundPriceFetcher] to get the correct implementation,
/// then call `init()` to register periodic tasks.
class BackgroundService {
  /// Task name for the standard periodic price refresh.
  static const priceRefreshTask = 'priceRefresh';

  /// Task name for the charging-only periodic price refresh.
  static const priceRefreshChargingTask = 'priceRefreshCharging';

  /// Standard refresh interval when on battery (not low).
  /// Android may delay based on Doze mode; 1h is the minimum WorkManager honors reliably.
  static const refreshInterval = Duration(hours: 1);

  /// Faster refresh interval when the device is charging.
  /// Plugged-in users get fresher prices without battery impact.
  static const chargingRefreshInterval = Duration(minutes: 30);

  /// Max IDs accepted per Tankerkoenig batch prices request.
  static const tankerkoenigBatchSize = 10;

  /// Skip writing a new price-history record if the last one is more recent than this.
  /// Avoids duplicate points when the BG task runs faster than prices actually change.
  static const priceHistoryDedupWindow = Duration(minutes: 60);

  /// Keep this much price-history per station, older points are trimmed.
  static const priceHistoryRetention = Duration(days: 30);

  /// Do not re-fire the same alert within this window, prevents notification spam.
  static const alertRetriggerCooldown = Duration(hours: 4);

  /// Connect timeout for Tankerkoenig prices batch requests in the BG isolate.
  static const bgConnectTimeout = Duration(seconds: 10);

  /// Receive timeout for Tankerkoenig prices batch requests in the BG isolate.
  static const bgReceiveTimeout = Duration(seconds: 15);

  /// Max retry attempts for transient network failures in the background task.
  static const maxRetryAttempts = 3;

  /// Base delay for exponential backoff between retries.
  static const retryBaseDelay = Duration(seconds: 2);

  /// Initialize background price refresh using the platform-appropriate
  /// implementation.
  ///
  /// Delegates to [createBackgroundPriceFetcher] which returns the correct
  /// [BackgroundPriceFetcher] for the current platform.
  static Future<void> init() async {
    final fetcher = createBackgroundPriceFetcher();
    await fetcher.init();
  }

  /// Cancel all scheduled periodic tasks. Called when the user has no
  /// active alerts left — per the Tankerkönig terms of service
  /// ("Apps: requests on demand — regular non-user-initiated requests
  /// are to be avoided"). Price alerts ARE user-consented periodic
  /// polling; without them, no polling should happen.
  static Future<void> cancelAll() async {
    final fetcher = createBackgroundPriceFetcher();
    await fetcher.cancelAll();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundService.priceRefreshTask ||
        task == BackgroundService.priceRefreshChargingTask) {
      debugPrint('BackgroundService: running task "$task"');
      await _refreshPricesAndCheckAlerts();
    }
    return true;
  });
}

/// Background task: fetch latest prices for favorites, record history,
/// evaluate alerts, and fire notifications.
///
/// Uses [HiveIsolateLock] to prevent concurrent Hive access with the main
/// isolate, and closes all Hive boxes when done to release file handles.
Future<void> _refreshPricesAndCheckAlerts() async {
  HiveIsolateLock? lock;
  try {
    // Acquire file-based lock to prevent concurrent Hive access
    lock = await HiveIsolateLock.create();
    final acquired = await lock.acquire();
    if (!acquired) {
      debugPrint('BackgroundService: could not acquire Hive lock, skipping task');
      return;
    }

    // Initialize Hive in isolate with proper encryption
    await HiveStorage.initInIsolate();

    final storage = HiveStorage();

    // Load API key
    await HiveStorage.loadApiKey();
    final apiKey = storage.getApiKey();

    // 1. Get favorite + alert station IDs (union for batch price fetch)
    final favoriteIds = storage.getFavoriteIds();
    final repo = AlertRepository(storage);
    final alerts = repo.getAlerts();
    final alertStationIds = alerts
        .where((a) => a.isActive)
        .map((a) => a.stationId)
        .toSet();
    final allStationIds = {...favoriteIds, ...alertStationIds}.toList();
    debugPrint('BackgroundService: ${favoriteIds.length} favorites, ${alertStationIds.length} alert stations, ${allStationIds.length} total');

    if (allStationIds.isEmpty) return;

    // 2. Fetch prices for all stations via the shared Tankerkoenig batch
    //    fetcher. The fetcher handles chunking + parsing + retry — see
    //    TankerkoenigBatchPriceFetcher.
    final now = DateTime.now();
    final dio = Dio(BaseOptions(
      connectTimeout: BackgroundService.bgConnectTimeout,
      receiveTimeout: BackgroundService.bgReceiveTimeout,
    ));
    final fetcher = TankerkoenigBatchPriceFetcher(
      dio: dio,
      batchSize: BackgroundService.tankerkoenigBatchSize,
      retryConfig: const BackgroundRetryConfig(
        maxAttempts: BackgroundService.maxRetryAttempts,
        baseDelay: BackgroundService.retryBaseDelay,
      ),
    );
    final prices = await fetcher.fetchBatch(
      ids: allStationIds,
      apiKey: apiKey,
    );
    debugPrint('BackgroundService: fetched prices for ${prices.length} stations');

    // 3. Record price history for each station
    if (prices.isNotEmpty) {
      for (final entry in prices.entries) {
        final stationId = entry.key;
        final p = entry.value;
        if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) continue;

        final record = PriceRecord(
          stationId: stationId,
          recordedAt: now,
          e5: p.getDouble(TankerkoenigFields.e5),
          e10: p.getDouble(TankerkoenigFields.e10),
          diesel: p.getDouble(TankerkoenigFields.diesel),
        );

        // Deduplicate: only save if last record is older than dedup window
        final existing = storage.getPriceRecords(stationId);
        final lastRecordedAt = existing.isNotEmpty
            ? DateTime.tryParse(existing.last['recordedAt']?.toString() ?? '')
            : null;
        final shouldSave = existing.isEmpty ||
            lastRecordedAt == null ||
            now.difference(lastRecordedAt) >
                BackgroundService.priceHistoryDedupWindow;
        if (shouldSave) {
          final records = [
            ...existing,
            record.toJson(),
          ];
          // Trim to retention window
          final cutoff = now.subtract(BackgroundService.priceHistoryRetention);
          final trimmed = records.where((r) {
            final ts = DateTime.tryParse(r['recordedAt']?.toString() ?? '');
            return ts != null && ts.isAfter(cutoff);
          }).toList();
          await storage.savePriceRecords(stationId, trimmed.cast<Map<String, dynamic>>());
        }
      }
      debugPrint('BackgroundService: price history recorded');

      // 4. Update cached station data with fresh prices
      for (final entry in prices.entries) {
        final stationId = entry.key;
        final p = entry.value;
        if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) continue;

        final cached = storage.getCachedData('station:$stationId');
        final cachedData = cached?.getMap('data');
        if (cachedData != null) {
          final stationData = Map<String, dynamic>.from(cachedData);
          final e5 = p.getDouble(TankerkoenigFields.e5);
          final e10 = p.getDouble(TankerkoenigFields.e10);
          final diesel = p.getDouble(TankerkoenigFields.diesel);
          if (e5 != null) stationData[TankerkoenigFields.e5] = e5;
          if (e10 != null) stationData[TankerkoenigFields.e10] = e10;
          if (diesel != null) stationData[TankerkoenigFields.diesel] = diesel;
          stationData[TankerkoenigFields.isOpen] = p[TankerkoenigFields.status] == TankerkoenigFields.statusOpen;
          await storage.cacheData('station:$stationId', stationData);
        }
      }
    }

    // 5. Evaluate alerts (prices may be empty if all retries failed)
    final activeAlerts = alerts.where((a) => a.isActive).toList();

    if (activeAlerts.isNotEmpty && prices.isNotEmpty) {
      final notifier = LocalNotificationService();
      await notifier.initialize();
      int notificationCount = 0;

      for (final alert in activeAlerts) {
        final stationPrices = prices[alert.stationId];
        if (stationPrices == null || stationPrices[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) continue;

        double? currentPrice;
        switch (alert.fuelType) {
          case FuelTypeE5():
            currentPrice = stationPrices.getDouble(TankerkoenigFields.e5);
          case FuelTypeE10():
            currentPrice = stationPrices.getDouble(TankerkoenigFields.e10);
          case FuelTypeDiesel():
            currentPrice = stationPrices.getDouble(TankerkoenigFields.diesel);
          default:
            continue;
        }

        if (currentPrice != null && currentPrice <= alert.targetPrice) {
          // Honor re-trigger cooldown
          if (alert.lastTriggeredAt != null &&
              now.difference(alert.lastTriggeredAt!) <
                  BackgroundService.alertRetriggerCooldown) {
            continue;
          }

          await notifier.showPriceAlert(
            id: alert.stationId.hashCode,
            title: '${alert.stationName} - ${alert.fuelType.displayName}',
            body: '${currentPrice.toStringAsFixed(3)} \u20ac (target: ${alert.targetPrice.toStringAsFixed(3)} \u20ac)',
          );
          notificationCount++;

          // Update last triggered
          await repo.saveAlert(alert.copyWith(lastTriggeredAt: now));
        }
      }
      debugPrint('BackgroundService: $notificationCount alerts triggered');
    } else {
      debugPrint('BackgroundService: ${activeAlerts.length} active alerts, ${prices.length} prices available');
    }

    // 6. Update home screen widgets with latest favorite prices.
    //    Pass profile + settings storage so the widget can resolve the
    //    active profile's preferred fuel type and last-known GPS.
    await HomeWidgetService.updateWidget(
      storage,
      profileStorage: storage,
      settingsStorage: storage,
    );
    await HomeWidgetService.updateNearestWidget(
      storage,
      storage,
      profileStorage: storage,
    );
  } catch (e) {
    debugPrint('BackgroundService: task failed: $e');
  } finally {
    // Always close Hive boxes and release lock, even on failure.
    // This prevents file handle leaks and stale locks.
    try {
      await HiveStorage.closeIsolateBoxes();
    } catch (e) {
      debugPrint('BackgroundService: failed to close Hive boxes: $e');
    }
    lock?.release();
  }
}
