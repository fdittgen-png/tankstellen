import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/alerts/data/repositories/alert_repository.dart';
import '../../features/price_history/data/models/price_record.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/widget/data/home_widget_service.dart';
import '../notifications/notification_service.dart';
import '../storage/hive_storage.dart';
import 'background_retry.dart';

/// Manages periodic background tasks via Android WorkManager.
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
/// ## Frequency: Every 1 hour (Android may delay based on battery/Doze mode)
class BackgroundService {
  static const _priceRefreshTask = 'priceRefresh';

  /// How often WorkManager attempts to refresh prices.
  /// Android may delay based on battery/Doze mode; 1h is the minimum WorkManager honors reliably.
  static const refreshInterval = Duration(hours: 1);

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

  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _priceRefreshTask,
      _priceRefreshTask,
      frequency: refreshInterval,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundService._priceRefreshTask) {
      await _refreshPricesAndCheckAlerts();
    }
    return true;
  });
}

/// Background task: fetch latest prices for favorites, record history,
/// evaluate alerts, and fire notifications.
Future<void> _refreshPricesAndCheckAlerts() async {
  try {
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

    // 2. Fetch prices for all stations via Tankerkoenig batch endpoint
    final now = DateTime.now();
    final prices = <String, Map<String, dynamic>>{};
    if (apiKey != null && apiKey.isNotEmpty) {
      final dio = Dio(BaseOptions(
        connectTimeout: BackgroundService.bgConnectTimeout,
        receiveTimeout: BackgroundService.bgReceiveTimeout,
      ));

      // Tankerkoenig prices endpoint (batch) with retry
      const batchSize = BackgroundService.tankerkoenigBatchSize;
      for (var i = 0; i < allStationIds.length; i += batchSize) {
        final batch = allStationIds.sublist(
          i,
          i + batchSize > allStationIds.length ? allStationIds.length : i + batchSize,
        );
        final ids = batch.join(',');

        final data = await fetchWithRetry(
          dio: dio,
          url: 'https://creativecommons.tankerkoenig.de/json/prices.php',
          queryParameters: {'ids': ids, 'apikey': apiKey},
          config: const BackgroundRetryConfig(
            maxAttempts: BackgroundService.maxRetryAttempts,
            baseDelay: BackgroundService.retryBaseDelay,
          ),
        );
        if (data != null && data['ok'] == true && data['prices'] != null) {
          final rawPrices = data['prices'] as Map<String, dynamic>;
          for (final entry in rawPrices.entries) {
            if (entry.value is Map) {
              prices[entry.key] = Map<String, dynamic>.from(entry.value as Map);
            }
          }
        }
      }
      debugPrint('BackgroundService: fetched prices for ${prices.length} stations');
    }

    // 3. Record price history for each station
    if (prices.isNotEmpty) {
      for (final entry in prices.entries) {
        final stationId = entry.key;
        final p = entry.value;
        if (p['status'] == 'no prices') continue;

        final record = PriceRecord(
          stationId: stationId,
          recordedAt: now,
          e5: (p['e5'] as num?)?.toDouble(),
          e10: (p['e10'] as num?)?.toDouble(),
          diesel: (p['diesel'] as num?)?.toDouble(),
        );

        // Deduplicate: only save if last record is older than dedup window
        final existing = storage.getPriceRecords(stationId);
        final shouldSave = existing.isEmpty ||
            now.difference(DateTime.parse(existing.last['recordedAt'] as String)) >
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
        if (p['status'] == 'no prices') continue;

        final cached = storage.getCachedData('station:$stationId');
        if (cached != null && cached['data'] is Map) {
          final stationData = Map<String, dynamic>.from(cached['data'] as Map);
          if (p['e5'] != null) stationData['e5'] = (p['e5'] as num).toDouble();
          if (p['e10'] != null) stationData['e10'] = (p['e10'] as num).toDouble();
          if (p['diesel'] != null) stationData['diesel'] = (p['diesel'] as num).toDouble();
          stationData['isOpen'] = p['status'] == 'open';
          await storage.cacheData('station:$stationId', stationData);
        }
      }
    }

    // 5. Evaluate alerts (prices may be empty if all retries failed)
    final activeAlerts = alerts.where((a) => a.isActive).toList();

    if (activeAlerts.isNotEmpty && prices.isNotEmpty) {
      await NotificationService.init();
      int notificationCount = 0;

      for (final alert in activeAlerts) {
        final stationPrices = prices[alert.stationId];
        if (stationPrices == null || stationPrices['status'] == 'no prices') continue;

        double? currentPrice;
        switch (alert.fuelType) {
          case FuelType.e5:
            currentPrice = (stationPrices['e5'] as num?)?.toDouble();
          case FuelType.e10:
            currentPrice = (stationPrices['e10'] as num?)?.toDouble();
          case FuelType.diesel:
            currentPrice = (stationPrices['diesel'] as num?)?.toDouble();
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

          await NotificationService.showPriceAlert(
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

    // 6. Update home screen widget with latest favorite prices
    await HomeWidgetService.updateWidget(storage);
  } catch (e) {
    debugPrint('BackgroundService: task failed: $e');
  }
}
