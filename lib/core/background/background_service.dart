// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/logging/error_logger.dart';
import '../../features/alerts/data/radius_alert_store.dart';
import '../storage/hive_storage.dart';
import 'background_alert_scan_coordinator.dart';
import 'background_price_fetcher_provider.dart';
import 'background_price_history_writer.dart';
import 'notification_templates.dart';

/// Background price-refresh scheduling + the WorkManager / iOS BGTask
/// callback entry point.
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
/// The actual scan (price fetch, history dedup, alert evaluation, widget
/// refresh) lives in [BackgroundAlertScanCoordinator] (#2415) so every
/// trigger — the WorkManager periodic tasks here, the Android home-widget
/// refresh (#2412), and the iOS BGAppRefreshTask (#2414) — runs the same
/// code and shares one cross-trigger dedup/cooldown gate. This callback is
/// deliberately thin: it just maps the task name to a
/// [BackgroundScanTrigger] and delegates.
///
/// ## Frequency: Adaptive based on battery/charger state
/// - **Charging**: every 30 minutes (more frequent updates while plugged in)
/// - **On battery (not low)**: every 1 hour (standard interval)
/// - **Low battery**: tasks are skipped by WorkManager constraints
///
/// Background scanning is **best-effort, never real-time** — Android delays
/// periodic work under Doze and iOS schedules BGAppRefresh opportunistically.
///
/// ## Platform abstraction
/// Task scheduling is handled by [BackgroundPriceFetcher] implementations:
/// - Android: [AndroidBackgroundPriceFetcher] (WorkManager)
/// - iOS: [IosBackgroundPriceFetcher] (workmanager iOS backend / BGTask)
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

  // Retry / dedup / batch constants live on BackgroundAlertScanCoordinator
  // (#2415) so every trigger shares one tuning surface. Kept here as thin
  // forwarders for backwards-compatible call sites + existing tests.

  /// Max IDs accepted per Tankerkoenig batch prices request.
  static const tankerkoenigBatchSize =
      BackgroundAlertScanCoordinator.tankerkoenigBatchSize;

  /// Skip writing a new price-history record if the last one is more recent.
  static const priceHistoryDedupWindow =
      BackgroundPriceHistoryWriter.dedupWindow;

  /// Keep this much price-history per station; older points are trimmed.
  static const priceHistoryRetention = BackgroundPriceHistoryWriter.retention;

  /// Do not re-fire the same per-station alert within this window.
  static const alertRetriggerCooldown =
      BackgroundAlertScanCoordinator.priceAlertRetriggerCooldown;

  /// Connect / receive timeouts for the BG-isolate Dio client.
  static const bgConnectTimeout =
      BackgroundAlertScanCoordinator.bgConnectTimeout;
  static const bgReceiveTimeout =
      BackgroundAlertScanCoordinator.bgReceiveTimeout;

  /// Max retry attempts + base backoff for transient network failures.
  static const maxRetryAttempts =
      BackgroundAlertScanCoordinator.maxRetryAttempts;
  static const retryBaseDelay = BackgroundAlertScanCoordinator.retryBaseDelay;

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

  /// Start or stop background polling based on whether ANY user-consented
  /// alert is active — a per-station [PriceAlert] OR a [RadiusAlert]
  /// (#2210). Previously only price alerts gated the scheduler, so a
  /// radius-only user got no WorkManager task and radius alerts never
  /// fired. Idempotent: safe to call after every alert mutation and at
  /// startup. Cancels only when BOTH alert kinds are empty.
  static Future<void> reconcile() async {
    try {
      final hasPriceAlert =
          HiveStorage().getAlerts().any((a) => a['isActive'] == true);
      var hasRadiusAlert = false;
      try {
        hasRadiusAlert = (await RadiusAlertStore().list()).any((a) => a.enabled);
      } catch (_) {
        // Radius store unreadable (e.g. box not open) — treat as none.
      }
      if (hasPriceAlert || hasRadiusAlert) {
        // #2306 — resolve the localized notification templates HERE, in
        // the main isolate, where the active in-app locale is known, and
        // stash them in Hive settings. The OS-spawned background isolate
        // has no BuildContext and an unreliable Platform.localeName, so it
        // reads these templates back instead of branching de/en itself.
        await _persistNotificationTemplates();
        await init();
      } else {
        await cancelAll();
      }
    } catch (e, st) {
      // Never let a scheduling hiccup crash an alert mutation or startup.
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: const {'where': 'BackgroundService.reconcile'}));
    }
  }

  /// #2306 — resolve the localized notification templates for the active
  /// in-app language and persist them to Hive settings so the background
  /// isolate can render alerts in the user's language without a
  /// BuildContext. The active language mirrors `ActiveLanguage`'s
  /// persisted `active_language_code` setting; absent (never picked) we
  /// fall back to the platform locale, then English.
  static Future<void> _persistNotificationTemplates() async {
    try {
      final lang =
          HiveStorage().getSetting('active_language_code') as String?;
      final templates =
          BackgroundNotificationTemplates.resolveForLanguage(lang);
      await HiveStorage().putSetting(
          BackgroundNotificationTemplates.storageKey, templates.encode());
    } catch (e, st) {
      // Non-fatal: the isolate falls back to live resolution from the
      // persisted language code if the blob is missing.
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'BackgroundService._persistNotificationTemplates'
      }));
    }
  }
}

/// Top-level WorkManager / iOS BGTask entry point (must be a top-level
/// function annotated `vm:entry-point` so the background isolate can find
/// it). Maps the task name onto a [BackgroundScanTrigger] and delegates to
/// the shared [BackgroundAlertScanCoordinator] — see #2415.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final trigger = _triggerForTask(task);
    if (trigger == null) {
      debugPrint('BackgroundService: ignoring unknown task "$task"');
      return true;
    }
    debugPrint('BackgroundService: running task "$task" (${trigger.tag})');
    await BackgroundAlertScanCoordinator().scan(trigger: trigger);
    return true;
  });
}

/// Resolve the [BackgroundScanTrigger] for a WorkManager / iOS task name.
///
/// On iOS the workmanager backend reports background-fetch wakeups as
/// [Workmanager.iOSBackgroundTask]; the BGAppRefreshTask registered in
/// `AppDelegate.swift` reports its own identifier. Both funnel into the
/// iOS trigger. Returns null for task names we don't recognise so the
/// dispatcher can no-op instead of scanning on a stray callback.
BackgroundScanTrigger? _triggerForTask(String task) {
  switch (task) {
    case BackgroundService.priceRefreshTask:
      return BackgroundScanTrigger.workManagerPeriodic;
    case BackgroundService.priceRefreshChargingTask:
      return BackgroundScanTrigger.workManagerCharging;
    case Workmanager.iOSBackgroundTask:
    case IosBackgroundTaskIds.appRefresh:
      return BackgroundScanTrigger.iosBackgroundRefresh;
    default:
      return null;
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
}
