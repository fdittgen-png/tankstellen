// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'ios_slc_wake_monitor.dart';

/// Facade over iOS significant-location-change (SLC) wake monitoring
/// (#3169) — one of the free alert-delivery mitigations: when the device
/// moves ~500 m+ (cell-tower granularity) iOS wakes the app, and the
/// native bridge piggybacks that wake into an opportunistic headless
/// alert scan (the `slcWake` journal trigger).
///
/// This is the designated cross-platform seam (CLAUDE.md / #2350): shared
/// code ([BackgroundService.reconcile]) talks to this interface only;
/// platform selection happens in [createSlcWakeMonitor]. Android does not
/// need it (WorkManager Tier-1 already meets the alert SLA), so every
/// non-iOS platform gets the no-op.
///
/// ## Honest permission framing
/// SLC delivery to a backgrounded/terminated app requires an *existing*
/// "Always" location grant. The native bridge checks the current
/// authorization and silently stays off without it — it NEVER prompts;
/// alerts must not escalate the location permission the user chose for
/// other features (search / radar / trip recording).
abstract class SlcWakeMonitor {
  /// Arm ([enabled] true) or disarm SLC wake monitoring. Called from
  /// [BackgroundService.reconcile] after every alert mutation + at
  /// startup, mirroring the BGTask schedule's lifecycle: monitoring runs
  /// only while at least one alert is active. Idempotent; never throws.
  Future<void> setEnabled(bool enabled);
}

/// No-op monitor for every platform without an SLC backend (Android,
/// desktop, test hosts).
class NoopSlcWakeMonitor implements SlcWakeMonitor {
  @override
  Future<void> setEnabled(bool enabled) async {
    // No SLC wake backend on this platform (#3169).
  }
}

/// Creates the platform-appropriate [SlcWakeMonitor]. Selection is on
/// [defaultTargetPlatform] — the same idiom as the auto-record
/// orchestrator factories — so tests can steer it via
/// [debugDefaultTargetPlatformOverride].
SlcWakeMonitor createSlcWakeMonitor() =>
    defaultTargetPlatform == TargetPlatform.iOS
        ? IosSlcWakeMonitor()
        : NoopSlcWakeMonitor();
