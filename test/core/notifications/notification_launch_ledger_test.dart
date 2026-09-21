// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';
import 'package:tankstellen/core/notifications/notification_launch_ledger.dart';
import 'package:tankstellen/core/notifications/notification_launch_listener.dart';
import 'package:tankstellen/core/notifications/notification_tap_dispatcher.dart';

import '../../helpers/silence_error_logger.dart';

/// #4317 — `LocalNotificationService.initialize()` moved past the first
/// frame. These tests drive [NotificationLaunchListener] through the tap
/// orderings `flutter_local_notifications` 22.3.0 actually produces while
/// init is pending (read from its iOS/Android sources; see the ledger's
/// doc), and prove no tap is dropped and none is routed twice.

/// Launch details the test can change between probes, like the plugin's
/// native state changes when a tap arrives.
class _FakeLaunchDetails extends LocalNotificationService {
  _FakeLaunchDetails() : super(plugin: _NoPlugin());
  String? payload;
  int probes = 0;

  @override
  Future<String?> getColdLaunchPayload() async {
    probes++;
    return payload;
  }
}

class _NoPlugin extends Fake implements FlutterLocalNotificationsPlugin {}

class _RecordingHandler extends NotificationLaunchHandler {
  _RecordingHandler() : super(GoRouter(routes: const []));
  final routed = <String?>[];

  @override
  void handle(String? rawPayload) => routed.add(rawPayload);
}

class _ThrowingInitPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async =>
      throw StateError('native init failed');
}

void main() {
  silenceErrorLoggerSpool();

  late _FakeLaunchDetails details;
  late _RecordingHandler handler;

  setUp(() {
    NotificationLaunchLedger.resetForTest();
    details = _FakeLaunchDetails();
    handler = _RecordingHandler();
  });

  tearDown(NotificationLaunchLedger.resetForTest);

  /// The ledger's completer must be created inside the widget test's fake
  /// async zone: completing one made in `setUp` (the root zone) schedules
  /// its listeners on the real microtask queue, which `pump` never drains.
  void inFakeZone() => NotificationLaunchLedger.resetForTest();

  /// Lets the probe's platform round-trip resolve, then produces a frame:
  /// the cold route is pushed from a post-frame callback, and a post-frame
  /// callback alone does not schedule one.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    tester.binding.scheduleFrame();
    await tester.pump();
  }

  Future<void> mount(WidgetTester tester, {Key? key}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [notificationLaunchHandlerProvider.overrideWithValue(handler)],
      child: NotificationLaunchListener(
        key: key,
        coldLaunchService: details,
        child: const SizedBox(),
      ),
    ));
    await settle(tester);
  }

  testWidgets('a cold launch routes while plugin init is still pending — '
      'and forever pending does not stop it', (tester) async {
    inFakeZone();
    details.payload = 'cold';
    await mount(tester);
    expect(handler.routed, ['cold']);
    expect(NotificationLaunchLedger.isPluginReady, isFalse);
  });

  testWidgets('iOS: a tap that lands in the launch details before init is '
      'routed once init finishes', (tester) async {
    inFakeZone();
    await mount(tester);
    expect(handler.routed, isEmpty);

    // Native `_initialized` is false → the plugin stores the tap as launch
    // details instead of forwarding it.
    details.payload = 'tapped-during-init';
    NotificationLaunchLedger.markPluginReady();
    await settle(tester);

    expect(handler.routed, ['tapped-during-init']);
    expect(details.probes, 2, reason: 'exactly one re-probe after init');
  });

  testWidgets('iOS: the cold-launch payload is not routed a second time by '
      'the post-init re-probe', (tester) async {
    inFakeZone();
    details.payload = 'cold';
    await mount(tester);
    NotificationLaunchLedger.markPluginReady();
    await settle(tester);
    expect(handler.routed, ['cold']);
  });

  testWidgets('Android: the channel buffer draining the SAME tap the probe '
      'already routed via setIntent does not navigate twice', (tester) async {
    inFakeZone();
    details.payload = 'warm-during-splash';
    await mount(tester);
    expect(handler.routed, ['warm-during-splash']);

    // initialize() registers the handler → the buffered message drains
    // into the dispatcher before init completes.
    NotificationTapDispatcher.instance.dispatch('warm-during-splash');
    await settle(tester);
    NotificationLaunchLedger.markPluginReady();
    await settle(tester);

    expect(handler.routed, ['warm-during-splash']);
  });

  testWidgets('Android: a buffered tap the probe did NOT see is routed',
      (tester) async {
    inFakeZone();
    await mount(tester);
    NotificationTapDispatcher.instance.dispatch('buffered');
    await settle(tester);
    expect(handler.routed, ['buffered']);
  });

  testWidgets('after init every stream tap is a fresh gesture — the same '
      'payload twice routes twice', (tester) async {
    inFakeZone();
    NotificationLaunchLedger.markPluginReady();
    await mount(tester);
    NotificationTapDispatcher.instance.dispatch('p');
    await settle(tester);
    NotificationTapDispatcher.instance.dispatch('p');
    await settle(tester);
    expect(handler.routed, ['p', 'p']);
  });

  testWidgets('a remount (language change rebuilds the tree) does not '
      'replay the cold-launch deep link', (tester) async {
    inFakeZone();
    details.payload = 'cold';
    await mount(tester, key: const ValueKey('de'));
    NotificationLaunchLedger.markPluginReady();
    await settle(tester);
    await mount(tester, key: const ValueKey('en'));
    await settle(tester);
    expect(handler.routed, ['cold']);
  });

  test('initialize() opens the ledger even when the plugin init throws',
      () async {
    final service = LocalNotificationService(plugin: _ThrowingInitPlugin());
    await expectLater(service.initialize(), throwsA(isA<StateError>()));
    expect(NotificationLaunchLedger.isPluginReady, isTrue,
        reason: 'a failed init must not leave the launch listener waiting');
  });

  test('reserveEarlyTapBuffer keeps every tap sent before a handler exists',
      () async {
    const channel = 'tankstellen.test/early_taps_4317';
    // The same resize, applied to a private channel so the test does not
    // depend on — or disturb — the plugin channel's global buffer.
    ui.channelBuffers.resize(channel, NotificationLaunchLedger.earlyTapBufferSize);
    for (var i = 0; i < 3; i++) {
      ui.channelBuffers.push(
          channel, ByteData(1)..setUint8(0, i), (ByteData? _) {});
    }

    final received = <int>[];
    final drained = Completer<void>();
    ui.channelBuffers.setListener(channel, (data, callback) {
      received.add(data!.getUint8(0));
      callback(null);
      if (received.length == 3) drained.complete();
    });
    await drained.future.timeout(const Duration(seconds: 5));
    ui.channelBuffers.clearListener(channel);

    expect(received, [0, 1, 2]);
  });

  test('the early-tap buffer is sized on the plugin channel', () {
    expect(NotificationLaunchLedger.pluginChannel,
        'dexterous.com/flutter/local_notifications');
    expect(() => NotificationLaunchLedger.reserveEarlyTapBuffer(),
        returnsNormally);
  });
}
