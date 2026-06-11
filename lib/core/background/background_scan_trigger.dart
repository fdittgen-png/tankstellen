// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Where a background scan came from. Threaded through to the dedup store
/// for diagnostics, used in debug logging, and persisted verbatim in the
/// #3147 scan journal so a maintainer can tell from one export which wake
/// source drove (or skipped) every scan.
///
/// Extracted from `background_alert_scan_coordinator.dart` when the #3169
/// mitigation lanes pushed that file over the 400-line cap; the
/// coordinator re-exports it, so existing importers are unaffected.
enum BackgroundScanTrigger {
  /// WorkManager periodic task (`priceRefresh`) — the baseline Android path,
  /// the twice-daily alert/price scan (#2866).
  workManagerPeriodic,

  /// Android home-widget refresh callback (#2412) — an opportunistic extra
  /// wake while the widget is on the home screen, NOT a reliability
  /// guarantee.
  androidWidget,

  /// iOS BGAppRefreshTask (#2414) — OS-budgeted, sparse, never real-time.
  iosBackgroundRefresh,

  /// iOS BGProcessingTask (#3169) — a SECOND, longer-budget BGTask lane
  /// alongside BGAppRefresh. iOS typically runs processing tasks during
  /// overnight idle/charging windows, giving the scan a daily-ish extra
  /// wake the app-refresh budget alone does not provide. One-shot per
  /// submission: the dispatcher re-arms it after every run.
  iosBgProcessing,

  /// iOS significant-location-change wake (#3169) — the OS relaunched the
  /// app because the device moved ~500m+ (cell-tower granularity). Only
  /// armed while alerts are active AND the user already granted Always
  /// location; an opportunistic extra wake, NOT a reliability guarantee.
  iosSlcWake,

  /// Opportunistic scan on an app-foreground wake (#3169) — the user
  /// opened/resumed the app, so we get free execution time. Runs in the
  /// same headless one-off lane as every other trigger; the cross-trigger
  /// cooldown absorbs rapid foreground/background flapping.
  opportunistic;

  /// Stable, log-friendly tag persisted alongside the last-scan timestamp.
  String get tag => switch (this) {
        BackgroundScanTrigger.workManagerPeriodic => 'workmanager_periodic',
        BackgroundScanTrigger.androidWidget => 'android_widget',
        BackgroundScanTrigger.iosBackgroundRefresh => 'ios_bg_refresh',
        // #3169 — the iOS mitigation triggers. The #3147 journal persists
        // these tags, so the alert SLA is field-verifiable per wake source
        // from one export.
        BackgroundScanTrigger.iosBgProcessing => 'bgProcessing',
        BackgroundScanTrigger.iosSlcWake => 'slcWake',
        BackgroundScanTrigger.opportunistic => 'opportunistic',
      };
}
