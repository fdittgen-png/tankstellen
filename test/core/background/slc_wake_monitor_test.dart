// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/ios_slc_wake_monitor.dart';
import 'package:tankstellen/core/background/slc_wake_monitor.dart';

/// #3169 — significant-location-change wake monitoring: the cross-platform
/// facade seam decision table. The iOS channel contract + fault injection
/// live in `ios_slc_wake_monitor_test.dart`.
void main() {
  group('createSlcWakeMonitor platform seam', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('iOS gets the channel-backed monitor', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(createSlcWakeMonitor(), isA<IosSlcWakeMonitor>());
    });

    test('Android gets the no-op (WorkManager Tier-1 already meets the SLA)',
        () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(createSlcWakeMonitor(), isA<NoopSlcWakeMonitor>());
    });

    test('desktop/test hosts get the no-op', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(createSlcWakeMonitor(), isA<NoopSlcWakeMonitor>());
    });
  });

  group('NoopSlcWakeMonitor', () {
    test('setEnabled completes for both states (never throws)', () async {
      final monitor = NoopSlcWakeMonitor();
      await expectLater(monitor.setEnabled(true), completes);
      await expectLater(monitor.setEnabled(false), completes);
    });
  });
}
