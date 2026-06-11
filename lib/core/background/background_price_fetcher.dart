// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Platform-agnostic interface for background price fetching.
///
/// Android uses WorkManager for periodic background tasks.
/// iOS will use WidgetKit background refresh (future implementation).
///
/// This abstraction allows platform-specific implementations without
/// duplicating the registration/scheduling logic across platforms.
abstract class BackgroundPriceFetcher {
  /// Initialize the background task scheduler and register periodic tasks.
  ///
  /// On Android, this initializes WorkManager and registers two periodic tasks:
  /// - Standard task (every 1h, requires battery not low)
  /// - Charging task (every 30min, requires device charging)
  ///
  /// On iOS, this will register WidgetKit background refresh (not yet implemented).
  Future<void> init();

  /// Cancel all registered background tasks.
  ///
  /// Called when the user disables background price refresh in settings,
  /// or during cleanup.
  Future<void> cancelAll();

  /// #3169 — run one opportunistic scan because the app just gained a
  /// free execution window (cold launch / foreground resume).
  ///
  /// iOS enqueues an immediate headless one-off task so the scan runs in
  /// the same coordinator lane (lock + cross-trigger cooldown + journal)
  /// as every scheduled trigger. Android and the no-op fetcher implement
  /// this as a no-op: WorkManager Tier-1 already meets the alert SLA, and
  /// an extra per-launch scan would only burn provider budget (#2866).
  Future<void> scheduleOpportunisticScan();
}
