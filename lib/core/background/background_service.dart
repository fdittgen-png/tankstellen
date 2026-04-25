import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/alerts/data/price_snapshot_store.dart';
import '../../features/alerts/data/radius_alert_dedup.dart';
import '../../features/alerts/data/radius_alert_runner.dart';
import '../../features/alerts/data/radius_alert_store.dart';
import '../../features/alerts/data/repositories/alert_repository.dart';
import '../../features/alerts/data/velocity_alert_cooldown.dart';
import '../../features/alerts/data/velocity_alert_runner.dart';
import '../../features/alerts/domain/radius_alert_evaluator.dart';
import '../../features/alerts/domain/velocity_alert_detector.dart';
import '../../features/search/data/models/search_params.dart';
import '../../features/price_history/data/models/price_record.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import '../../features/widget/data/home_widget_service.dart';
import '../constants/field_names.dart';
import '../notifications/local_notification_service.dart';
import '../services/impl/tankerkoenig_batch_price_fetcher.dart';
import '../services/impl/tankerkoenig_station_service.dart';
import '../storage/hive_storage.dart';
import '../storage/storage_keys.dart';
import '../sync/ntfy_service.dart';
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

    if (allStationIds.isEmpty) {
      // #609 — users without favorites still need a populated nearest
      // widget. Run the real-search builder before bailing.
      await _refreshNearestWidgetFromSearch(storage);
      return;
    }

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

      // #580 — ntfy.sh push runs alongside local notification when the
      // user has configured a topic. Reads Hive settings so no Supabase
      // / Riverpod access is needed from the background isolate.
      final ntfyEnabled = storage.getSetting(StorageKeys.ntfyEnabled)
              as bool? ??
          false;
      final ntfyTopic = storage.getSetting(StorageKeys.ntfyTopic) as String?;
      final ntfyService = (ntfyEnabled &&
              ntfyTopic != null &&
              ntfyTopic.isNotEmpty)
          ? NtfyService()
          : null;

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

          // #580 — fire-and-forget ntfy.sh push. Best-effort; a network
          // hiccup must not block the local notification already fired.
          if (ntfyService != null) {
            try {
              await ntfyService.sendPriceAlert(
                topic: ntfyTopic!,
                stationName: alert.stationName,
                fuelType: alert.fuelType.displayName,
                currentPrice: currentPrice,
                targetPrice: alert.targetPrice,
              );
            } catch (e) {
              debugPrint('BackgroundService: ntfy push failed: $e');
            }
          }

          // Update last triggered
          await repo.saveAlert(alert.copyWith(lastTriggeredAt: now));
        }
      }
      debugPrint('BackgroundService: $notificationCount alerts triggered');
    } else {
      debugPrint('BackgroundService: ${activeAlerts.length} active alerts, ${prices.length} prices available');
    }

    // 5b. #579 — Velocity detector: rapid drops across multiple nearby
    //     stations. Runs even when no per-station alert exists so the
    //     user gets notified about a wider price slide. Snapshots are
    //     pruned by the store itself; cooldown is per fuel type.
    if (prices.isNotEmpty) {
      try {
        final notifier = LocalNotificationService();
        await notifier.initialize();
        await _runVelocityDetector(
          storage: storage,
          prices: prices,
          now: now,
          notifier: notifier,
        );
      } catch (e) {
        debugPrint('BackgroundService: velocity detector failed: $e');
      }
    }

    // 5c. #578 phase 3 — Radius alerts: iterate every enabled
    //     RadiusAlert, query stations within its radius, and fire a
    //     notification when any station is at or below the
    //     threshold. Dedup remembers (alert, station) → (price, ts)
    //     so we don't re-notify on every 1 h cycle while the station
    //     stays cheap.
    try {
      final notifier = LocalNotificationService();
      await notifier.initialize();
      await _runRadiusAlerts(
        storage: storage,
        now: now,
        notifier: notifier,
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('BackgroundService: radius alert runner failed: $e');
    }

    // 6. Update home screen widgets with latest favorite prices.
    //    Pass profile + settings storage so the widget can resolve the
    //    active profile's preferred fuel type and last-known GPS.
    await HomeWidgetService.updateWidget(
      storage,
      profileStorage: storage,
      settingsStorage: storage,
    );
    // #609 — nearest widget now queries a real search against the active
    // country's API (when supported in the BG isolate) instead of just
    // sorting favorites by distance. Shared helper so the early-return
    // path above also runs it.
    await _refreshNearestWidgetFromSearch(storage);
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

/// #579 — orchestrate the velocity detector from the BG isolate.
///
/// Builds per-station [VelocityStationObservation]s by joining the
/// freshly fetched prices with the `station:<id>` cache (for
/// coordinates), then hands off to [VelocityAlertRunner] which owns
/// snapshot recording, detection, cooldown, and notification firing.
///
/// Extracted so a future test can drive the same code path with a
/// fake notifier + seeded snapshots.
Future<void> _runVelocityDetector({
  required HiveStorage storage,
  required Map<String, Map<String, dynamic>> prices,
  required DateTime now,
  required LocalNotificationService notifier,
}) async {
  final runner = VelocityAlertRunner(
    snapshotStore: PriceSnapshotStore(),
    cooldown: VelocityAlertCooldown(),
    notifier: notifier,
    copyBuilder: _buildVelocityCopy,
  );
  final config = await runner.loadConfig();
  final fuelKey = _tankerkoenigKeyFor(config.fuelType);
  if (fuelKey == null) {
    debugPrint('BackgroundService: velocity skipped — ${config.fuelType.apiValue} not in Tankerkoenig response');
    return;
  }

  final observations = <VelocityStationObservation>[];
  for (final entry in prices.entries) {
    final stationId = entry.key;
    final p = entry.value;
    if (p[TankerkoenigFields.status] == TankerkoenigFields.statusNoPrices) {
      continue;
    }
    final price = p.getDouble(fuelKey);
    if (price == null) continue;
    final cached = storage.getCachedData('station:$stationId');
    final data = cached?.getMap('data');
    final lat = data?.getDouble('lat');
    final lng = data?.getDouble('lng');
    if (lat == null || lng == null) continue;
    observations.add(VelocityStationObservation(
      stationId: stationId,
      price: price,
      lat: lat,
      lng: lng,
    ));
  }
  if (observations.isEmpty) {
    debugPrint('BackgroundService: velocity detector has no usable observations');
    return;
  }

  final userLat = storage.getSetting(StorageKeys.userPositionLat) as num?;
  final userLng = storage.getSetting(StorageKeys.userPositionLng) as num?;

  final event = await runner.run(
    observations: observations,
    now: now,
    userLat: userLat?.toDouble(),
    userLng: userLng?.toDouble(),
  );
  if (event != null) {
    debugPrint(
        'BackgroundService: velocity alert ${event.fuelType.apiValue}, '
        'count=${event.stationCount}, max=${event.maxDropCents.toStringAsFixed(1)}ct');
  }
}

/// Map [FuelType] → Tankerkoenig JSON key. The BG isolate only
/// fetches E5/E10/diesel today (see [_refreshPricesAndCheckAlerts])
/// so other fuels return `null` and skip velocity detection until
/// we broaden the batch fetcher.
String? _tankerkoenigKeyFor(FuelType fuelType) {
  return switch (fuelType) {
    FuelTypeE5() => TankerkoenigFields.e5,
    FuelTypeE10() => TankerkoenigFields.e10,
    FuelTypeDiesel() => TankerkoenigFields.diesel,
    _ => null,
  };
}

/// Build notification copy for a velocity event. The BG isolate
/// can't resolve the full ARB bundle (no BuildContext) so we pick
/// German vs English from [Platform.localeName] and format with
/// the same placeholders the ARB keys use.
VelocityAlertCopy _buildVelocityCopy(VelocityAlertEvent event) {
  final fuelLabel = event.fuelType.displayName.toUpperCase();
  final stationCount = event.stationCount;
  final maxCents = event.maxDropCents.round();
  final isGerman = Platform.localeName.toLowerCase().startsWith('de');
  if (isGerman) {
    return VelocityAlertCopy(
      title: '$fuelLabel an Tankstellen in der Nähe gefallen',
      body:
          '$stationCount Tankstellen um bis zu $maxCents¢ in der letzten Stunde gefallen',
    );
  }
  return VelocityAlertCopy(
    title: '$fuelLabel dropped at nearby stations',
    body:
        '$stationCount stations dropped by up to $maxCents¢ in the last hour',
  );
}

/// #578 phase 3 — orchestrate radius-alert evaluation from the BG
/// isolate.
///
/// Builds a per-alert sample list by searching the country's
/// StationService for stations within the alert's radius, then hands
/// off to [RadiusAlertRunner] which owns evaluator + dedup +
/// notification firing.
///
/// Today the BG isolate only has a working [TankerkoenigStationService]
/// (matches the per-station alert + velocity detector scope). Alerts
/// centred on non-DE coordinates are skipped with a log line rather
/// than dropped silently, so the user can tell why nothing arrived.
/// Expanding BG coverage to every country API is tracked separately.
Future<void> _runRadiusAlerts({
  required HiveStorage storage,
  required DateTime now,
  required LocalNotificationService notifier,
  required String? apiKey,
}) async {
  final store = RadiusAlertStore();
  final alerts = await store.list();
  final active = alerts.where((a) => a.enabled).toList();
  if (active.isEmpty) {
    debugPrint('BackgroundService: no active radius alerts');
    return;
  }

  // Without a Tankerkoenig key the only useful source is the shared
  // cache; skip rather than pretend we can search.
  if (apiKey == null || apiKey.isEmpty) {
    debugPrint(
        'BackgroundService: radius alerts skipped — no Tankerkoenig API key');
    return;
  }

  final dio = Dio(BaseOptions(
    baseUrl: 'https://creativecommons.tankerkoenig.de/json',
    connectTimeout: BackgroundService.bgConnectTimeout,
    receiveTimeout: BackgroundService.bgReceiveTimeout,
    queryParameters: {'apikey': apiKey},
  ));
  final service = TankerkoenigStationService(dio);

  final runner = RadiusAlertRunner(
    store: store,
    dedup: RadiusAlertDedup(),
    notifier: notifier,
    copyBuilder: _buildRadiusAlertCopy,
  );

  final fired = await runner.run(
    now: now,
    samplesFor: (alert) async {
      try {
        final result = await service.searchStations(
          SearchParams(
            lat: alert.centerLat,
            lng: alert.centerLng,
            radiusKm: alert.radiusKm,
          ),
        );
        final samples = <StationPriceSample>[];
        for (final station in result.data) {
          samples.addAll(StationPriceSample.fromStation(station));
        }
        return samples;
      } catch (e) {
        debugPrint(
            'BackgroundService: radius alert samples for ${alert.id} failed: $e');
        return const <StationPriceSample>[];
      }
    },
  );
  debugPrint('BackgroundService: ${fired.length} radius alerts fired');
}

/// Build notification copy for a radius alert (#1012 phase 2 grouped
/// fire). The BG isolate can't resolve the full ARB bundle (no
/// BuildContext), so we pick German vs English from
/// [Platform.localeName] and interpolate placeholders the same way
/// the main-isolate preview does.
///
/// Title summarises the alert as `<label>: N stations ≤ €X`. Body
/// renders one line per top-N matching station (cheapest first) and
/// appends `+ X more` when matches got truncated.
RadiusAlertCopy _buildRadiusAlertCopy(RadiusAlertGroupedEvent event) {
  final threshold = event.alert.threshold.toStringAsFixed(3);
  final label = event.alert.label;
  final isGerman = Platform.localeName.toLowerCase().startsWith('de');
  // Total visible matches *plus* the truncated tail — the title number
  // should reflect everything the user could see if they tapped in.
  final total = event.matches.length + event.truncatedMoreCount;
  final lines = event.matches
      .map((m) => '${m.stationId} ${m.pricePerLiter.toStringAsFixed(3)} €')
      .toList();
  if (event.truncatedMoreCount > 0) {
    lines.add(isGerman
        ? '+ ${event.truncatedMoreCount} weitere'
        : '+ ${event.truncatedMoreCount} more');
  }
  final body = lines.join('\n');
  if (isGerman) {
    return RadiusAlertCopy(
      title: '$label: $total Tankstellen ≤ $threshold €',
      body: body,
    );
  }
  return RadiusAlertCopy(
    title: '$label: $total stations ≤ $threshold €',
    body: body,
  );
}

/// Run the new nearest-widget builder from the background isolate.
///
/// Instantiates a minimal [TankerkoenigStationService] because that's the
/// only API for which we can assemble a working Dio here without pulling
/// in the full Riverpod graph. Countries without a DE-style key-based API
/// fall back to the legacy favorites-distance widget path by passing
/// `stationService: null` to [HomeWidgetService.updateNearestWidget].
///
/// The key gate mirrors the existing background price refresh — which
/// is also Tankerkoenig-only in the BG isolate today. Expanding this to
/// other countries is tracked separately.
Future<void> _refreshNearestWidgetFromSearch(HiveStorage storage) async {
  try {
    final apiKey = storage.getApiKey();
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    if (hasKey) {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://creativecommons.tankerkoenig.de/json',
        connectTimeout: BackgroundService.bgConnectTimeout,
        receiveTimeout: BackgroundService.bgReceiveTimeout,
        queryParameters: {'apikey': apiKey},
      ));
      final service = TankerkoenigStationService(dio);
      await HomeWidgetService.updateNearestWidget(
        storage,
        storage,
        profileStorage: storage,
        stationService: service,
      );
    } else {
      // No API key → degrade to legacy favorites-distance path.
      await HomeWidgetService.updateNearestWidget(
        storage,
        storage,
        profileStorage: storage,
      );
    }
  } catch (e) {
    debugPrint('BackgroundService: nearest widget refresh failed: $e');
  }
}
