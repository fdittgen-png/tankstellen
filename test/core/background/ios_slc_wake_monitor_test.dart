// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/ios_slc_wake_monitor.dart';

/// #3169 — the iOS SLC monitor's channel contract with the native
/// `SlcWakeBridge` (AppDelegate.swift), plus the never-throws fault
/// injection (#2349 contract lint).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(IosSlcWakeMonitor.channelName);
  final binding = TestDefaultBinaryMessengerBinding.instance;

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('the channel name matches the native SlcWakeBridge', () {
    // Two ends of one contract: AppDelegate.swift serves this channel.
    expect(IosSlcWakeMonitor.channelName, 'tankstellen/slc_wake');
  });

  test('setEnabled forwards the boolean to the native bridge', () async {
    final received = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      received.add(call);
      return null;
    });

    final monitor = IosSlcWakeMonitor();
    await monitor.setEnabled(true);
    await monitor.setEnabled(false);

    expect(received.map((c) => c.method), ['setEnabled', 'setEnabled']);
    expect(received.map((c) => c.arguments), [true, false]);
  });

  test('never throws when the native side errors (fault injection)',
      () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      throw PlatformException(code: 'boom');
    });
    await expectLater(IosSlcWakeMonitor().setEnabled(true), completes);
  });

  test('never throws when no handler is registered (engine not ready)',
      () async {
    // No mock handler installed → MissingPluginException path.
    await expectLater(IosSlcWakeMonitor().setEnabled(true), completes);
  });
}
