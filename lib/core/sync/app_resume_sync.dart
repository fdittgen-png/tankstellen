// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import 'sync_pull_coordinator.dart';
import 'tanksync_init_retry.dart';

/// #3447 — app-resume sync: every foreground resume is a free execution
/// window (mirrors `BackgroundService.onOpportunisticWake`), so a device
/// left open for days no longer waits for the next cold start to see rows
/// synced from another device.
///
/// Policy:
///  * **debounced** — at most one pull pass per [minInterval] (15 min),
///    anchored on [SyncPullCoordinator.lastCompletedAt] so the launch pass
///    itself counts (a resume 2 min after cold start does nothing);
///  * **never during a recording** — a live trip owns the OBD2 link and
///    the CPU budget; [recordingActive] is injected from the app layer
///    (`tripRecordingProvider.isActive`, the same signal the recording
///    banner uses) because core must not import features;
///  * **init-retry piggyback (#3450)** — a pending TankSync init retry is
///    fired first, so a resume can heal a failed launch init AND pull in
///    the same window.
///
/// Wired from the ONE app lifecycle observer
/// (`TankstellenApp.didChangeAppLifecycleState`); configured by
/// `LaunchSyncPhase.wireResumeSync` during the deferred launch block.
class AppResumeSync {
  AppResumeSync._();

  /// App-wide singleton, mirroring the other core-sync coordinators.
  static final AppResumeSync instance = AppResumeSync._();

  /// Minimum gap since the last COMPLETED pull pass (#3447).
  static const Duration minInterval = Duration(minutes: 15);

  bool Function() _recordingActive = () => false;
  SyncPullCoordinator _coordinator = SyncPullCoordinator.instance;
  TankSyncInitRetry _initRetry = TankSyncInitRetry.instance;
  bool _configured = false;

  /// Install the app-layer callbacks. Idempotent; re-configuring replaces
  /// the previous wiring. [coordinator] / [initRetry] are injectable for
  /// tests only.
  void configure({
    required bool Function() recordingActive,
    SyncPullCoordinator? coordinator,
    TankSyncInitRetry? initRetry,
  }) {
    _recordingActive = recordingActive;
    _coordinator = coordinator ?? SyncPullCoordinator.instance;
    _initRetry = initRetry ?? TankSyncInitRetry.instance;
    _configured = true;
  }

  /// Reset to the unconfigured state — test isolation only.
  @visibleForTesting
  void resetForTest() {
    _recordingActive = () => false;
    _coordinator = SyncPullCoordinator.instance;
    _initRetry = TankSyncInitRetry.instance;
    _configured = false;
  }

  /// The lifecycle hook. Never throws — a sync fault must not take down
  /// the lifecycle observer. [now] is injectable for the debounce tests.
  Future<void> onAppResumed({DateTime Function() now = DateTime.now}) async {
    try {
      if (!_configured) return;
      // Never compete with a live trip for the link/CPU (#3447).
      if (_recordingActive()) return;
      // #3450 — a pending init retry gets the window first; on a late
      // success its onReady callback already runs the full pull pass.
      await _initRetry.retryNowIfPending();
      if (_coordinator.isRunning) return;
      final last = _coordinator.lastCompletedAt;
      if (last != null && now().difference(last) < minInterval) return;
      await _coordinator.pullAll(now: now);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'AppResumeSync.onAppResumed'}));
    }
  }
}
