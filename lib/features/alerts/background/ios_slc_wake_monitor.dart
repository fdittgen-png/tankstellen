// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/logging/error_logger.dart';
import 'slc_wake_monitor.dart';

/// iOS implementation of [SlcWakeMonitor] (#3169): a thin client of the
/// `SlcWakeBridge` defined in `ios/Runner/AppDelegate.swift`.
///
/// The native side owns ALL the CoreLocation state:
///   * starts/stops `startMonitoringSignificantLocationChanges()`,
///   * persists the enabled flag in `UserDefaults` so a cold relaunch via
///     `UIApplication.LaunchOptionsKey.location` can resume monitoring
///     before any Flutter engine exists,
///   * gates on an existing `.authorizedAlways` grant and NEVER prompts,
///   * throttles wakes and enqueues the headless one-off scan task
///     (`IosBackgroundTaskIds.slcWake`) that funnels into the shared
///     [BackgroundAlertScanCoordinator].
///
/// Never throws: a missing handler (engine not ready, ancient build) or a
/// platform error degrades to "no SLC wakes" — which is exactly the
/// pre-#3169 behaviour — and is logged for the trace export.
class IosSlcWakeMonitor implements SlcWakeMonitor {
  /// Must match `SlcWakeBridge.channelName` in AppDelegate.swift.
  static const String channelName = 'tankstellen/slc_wake';

  final MethodChannel _channel;

  /// Creates the monitor. [channel] is injectable for tests.
  IosSlcWakeMonitor({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', enabled);
    } catch (e, st) {
      // Best-effort mitigation: losing the SLC lane must never break the
      // alert mutation / startup path that reconciled it.
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'IosSlcWakeMonitor.setEnabled',
      }));
    }
  }
}
