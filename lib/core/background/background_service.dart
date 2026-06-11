// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/logging/error_logger.dart';
import '../../features/alerts/data/radius_alert_store.dart';
import '../storage/hive_storage.dart';
import 'background_alert_scan_coordinator.dart';
import 'background_price_fetcher.dart';
import 'background_price_fetcher_provider.dart';
import 'background_price_history_writer.dart';
import 'notification_templates.dart';
import 'slc_wake_monitor.dart';

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
/// ## Frequency: twice per day (Epic #2860 EXIT GATE, #2866)
/// The periodic scan runs ~every 12h (twice daily). Since the scan now polls
/// every feasible country's provider, the cadence is the core rate-limit / ToS
/// safeguard — twice-daily + the once-per-country-per-scan grouping + the
/// shared per-provider [ProviderRequestBudget] bound every provider to well
/// inside its limits. The low-battery skip ([Constraints.requiresBatteryNotLow])
/// stays; the old 30-min charging cadence was dropped (it would have breached
/// twice-daily for a multi-country scan).
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

  /// One-off task name enqueued by the Android [BootReceiver] after a
  /// reboot (#2413). Handling it re-registers the periodic tasks so the
  /// schedule survives a device restart even if WorkManager's own boot
  /// reschedule did not fire. Must match `BootReceiver.BOOT_REREGISTER_TASK`.
  static const bootReregisterTask = 'bootReregister';

  /// One-off task name enqueued by the Android home-widget provider whenever
  /// the OS refreshes the widget (#2412). While the widget is on the home
  /// screen its periodic OS refreshes are extra, opportunistic wake
  /// opportunities — complementary to the WorkManager periodic tasks, NOT a
  /// reliability guarantee. The coordinator's cross-trigger cooldown keeps
  /// this from double-fetching alongside a concurrent periodic task. Must
  /// match `FuelPriceWidgetProvider.WIDGET_SCAN_TASK`.
  static const widgetRefreshScanTask = 'widgetRefreshScan';

  /// Periodic alert/price-scan cadence — **twice per day** (~every 12h).
  ///
  /// Epic #2860 EXIT GATE (#2866): the background scan now polls *every*
  /// feasible country's provider, so the cadence is the core rate-limit / ToS
  /// safeguard. Twice-daily — combined with the once-per-country-per-scan
  /// grouping (the registry-driven [BackgroundPriceSource]) and the shared
  /// per-provider [ProviderRequestBudget] — keeps every provider comfortably
  /// inside its published limits: no provider can be hit more than ~twice a
  /// day by a background scan, batched per country. (The previous 1h standard
  /// + 30min charging cadences breached that for a multi-country scan, so the
  /// charging variant was dropped and the standard one raised to 12h.) Android
  /// may still delay the wake under Doze — best-effort, never punctual.
  static const refreshInterval = Duration(hours: 12);

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
      final active = await hasActiveAlerts();
      if (active) {
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
      // #3169 — significant-location-change wake (iOS only; no-op
      // elsewhere via the facade seam). Armed only while alerts are
      // active, and the native side additionally requires an existing
      // Always location grant — it never prompts.
      await createSlcWakeMonitor().setEnabled(active);
    } catch (e, st) {
      // Never let a scheduling hiccup crash an alert mutation or startup.
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: const {'where': 'BackgroundService.reconcile'}));
    }
  }

  /// Whether ANY user-consented alert is active — a per-station
  /// [PriceAlert] OR a [RadiusAlert]. The single gate every scheduling
  /// surface shares ([reconcile], [onOpportunisticWake]). Never throws on
  /// a missing/unreadable radius store; a missing alerts box DOES throw —
  /// callers wrap.
  static Future<bool> hasActiveAlerts() async {
    final hasPriceAlert =
        HiveStorage().getAlerts().any((a) => a['isActive'] == true);
    var hasRadiusAlert = false;
    try {
      hasRadiusAlert = (await RadiusAlertStore().list()).any((a) => a.enabled);
    } catch (_) {
      // Radius store unreadable (e.g. box not open) — treat as none.
    }
    return hasPriceAlert || hasRadiusAlert;
  }

  /// #3169 — opportunistic scan on an app-foreground wake (cold launch +
  /// every resume). On iOS this is one of the few execution windows the
  /// OS reliably grants, so a user who opens the app gets a fresh alert
  /// pass without waiting for the sparse BGTask budget; the coordinator's
  /// cross-trigger cooldown (10 min) makes rapid resumes free. Android's
  /// fetcher implements it as a no-op — WorkManager Tier-1 already meets
  /// the SLA and an extra scan would only burn provider budget (#2866).
  ///
  /// Never throws — a scan opportunity is best-effort by definition and
  /// must not break app startup or the lifecycle observer. [fetcher] and
  /// [alertsGate] are injectable for tests (fault injection on the
  /// never-throws contract).
  static Future<void> onOpportunisticWake({
    BackgroundPriceFetcher? fetcher,
    Future<bool> Function()? alertsGate,
  }) async {
    try {
      final active = await (alertsGate ?? hasActiveAlerts)();
      if (!active) return;
      await (fetcher ?? createBackgroundPriceFetcher())
          .scheduleOpportunisticScan();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: const {'where': 'BackgroundService.onOpportunisticWake'}));
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
    // #2413 — boot re-arm: re-register the periodic tasks rather than scan.
    // The BootReceiver enqueues this one-off after a reboot.
    if (task == BackgroundService.bootReregisterTask) {
      debugPrint('BackgroundService: re-registering periodic tasks after boot');
      await BackgroundService.init();
      return true;
    }

    final trigger = _triggerForTask(task);
    if (trigger == null) {
      debugPrint('BackgroundService: ignoring unknown task "$task"');
      return true;
    }
    debugPrint('BackgroundService: running task "$task" (${trigger.tag})');
    await BackgroundAlertScanCoordinator().scan(trigger: trigger);

    // #3169 — a BGProcessingTask submission is ONE-SHOT (unlike the
    // BGAppRefresh lane, which the workmanager plugin re-submits inside its
    // native handler). Re-arm it here, after the scan, so the processing
    // lane keeps firing across days without the app being opened.
    if (task == IosBackgroundTaskIds.processing) {
      await scheduleIosProcessingTask(Workmanager());
    }
    return true;
  });
}

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
    debugPrint('BackgroundService: BGProcessingTask armed '
        '("${IosBackgroundTaskIds.processing}", OS-budgeted, best-effort)');
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.background, e, st,
        context: const {'where': 'scheduleIosProcessingTask'}));
  }
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
    case BackgroundService.widgetRefreshScanTask:
      return BackgroundScanTrigger.androidWidget;
    case Workmanager.iOSBackgroundTask:
    case IosBackgroundTaskIds.appRefresh:
      return BackgroundScanTrigger.iosBackgroundRefresh;
    // #3169 — the iOS alert-delivery mitigation lanes.
    case IosBackgroundTaskIds.processing:
      return BackgroundScanTrigger.iosBgProcessing;
    case IosBackgroundTaskIds.slcWake:
      return BackgroundScanTrigger.iosSlcWake;
    case IosBackgroundTaskIds.opportunistic:
      return BackgroundScanTrigger.opportunistic;
    default:
      return null;
  }
}

/// Exposes the file-private task-name → trigger mapping so the scheduling
/// decision table is unit-testable (#3169) without widening the dispatcher's
/// API surface.
@visibleForTesting
BackgroundScanTrigger? debugTriggerForTask(String task) =>
    _triggerForTask(task);

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
