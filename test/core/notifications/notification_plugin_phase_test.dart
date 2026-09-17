// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';
import 'package:tankstellen/core/notifications/notification_launch_ledger.dart';
import 'package:tankstellen/core/notifications/notification_plugin_phase.dart';

import '../../helpers/silence_error_logger.dart';

class _Plugin extends Fake implements FlutterLocalNotificationsPlugin {
  _Plugin({this.fail = false});
  final bool fail;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (fail) throw StateError('native init failed');
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
          T extends FlutterLocalNotificationsPlatform>() =>
      null;
}

/// #4162 — the notification plugin's lifecycle and the tap routing table.
void main() {
  silenceErrorLoggerSpool();

  setUp(NotificationLaunchLedger.resetForTest);
  tearDown(NotificationLaunchLedger.resetForTest);

  group('the routing table', () {
    test('is total: all 12 (phase, source, routed) combinations map', () {
      for (final phase in NotificationPluginPhase.values) {
        for (final source in TapSource.values) {
          for (final routed in [false, true]) {
            expect(kLaunchTapRouting[(phase, source, routed)], isNotNull,
                reason: '${phase.name}/${source.name}/$routed');
          }
        }
      }
      expect(kLaunchTapRouting, hasLength(12));
    });

    test('a null payload is always dropped', () {
      for (final key in kLaunchTapRouting.keys) {
        expect(
            launchTapRoute(key.$1, key.$2,
                payload: null, alreadyRouted: key.$3),
            TapRoute.drop);
      }
    });

    test('a probed payload routes once per process, in every phase', () {
      for (final phase in NotificationPluginPhase.values) {
        expect(kLaunchTapRouting[(phase, TapSource.probe, false)],
            TapRoute.routeAndClaim);
        expect(kLaunchTapRouting[(phase, TapSource.probe, true)],
            TapRoute.drop);
      }
    });

    test('a stream tap before the plugin is ready deduplicates like a probe; '
        'after it, every tap is a fresh gesture', () {
      expect(
          kLaunchTapRouting[
              (NotificationPluginPhase.pending, TapSource.stream, true)],
          TapRoute.drop);
      for (final phase in [
        NotificationPluginPhase.ready,
        NotificationPluginPhase.initFailed,
      ]) {
        for (final routed in [false, true]) {
          expect(kLaunchTapRouting[(phase, TapSource.stream, routed)],
              TapRoute.routeAndRecord);
        }
      }
    });
  });

  group('the plugin phase', () {
    test('the table: pending leads to ready or initFailed, both terminal', () {
      expect(kNotificationPluginTransitions[NotificationPluginPhase.pending],
          {NotificationPluginPhase.ready, NotificationPluginPhase.initFailed});
      expect(kNotificationPluginTransitions[NotificationPluginPhase.ready],
          isEmpty);
      expect(
          kNotificationPluginTransitions[NotificationPluginPhase.initFailed],
          isEmpty);
    });

    test('a successful initialize makes it ready', () async {
      await LocalNotificationService(plugin: _Plugin()).initialize();
      expect(NotificationLaunchLedger.pluginPhase,
          NotificationPluginPhase.ready);
      expect(NotificationLaunchLedger.isPluginReady, isTrue);
    });

    test('PARTIAL RESTORE — a failed initialize is initFailed, opens the '
        'ledger, and taps stay routable', () async {
      await expectLater(
          LocalNotificationService(plugin: _Plugin(fail: true)).initialize(),
          throwsA(isA<StateError>()));
      expect(NotificationLaunchLedger.pluginPhase,
          NotificationPluginPhase.initFailed);
      expect(NotificationLaunchLedger.isPluginReady, isTrue);
      await expectLater(NotificationLaunchLedger.pluginReady, completes);
      expect(NotificationLaunchLedger.routeFor(TapSource.probe, 'cold'),
          TapRoute.routeAndClaim);
    });

    test('the first finish decides — a later initialize does not move it',
        () async {
      await LocalNotificationService(plugin: _Plugin()).initialize();
      await expectLater(
          LocalNotificationService(plugin: _Plugin(fail: true)).initialize(),
          throwsA(isA<StateError>()));
      expect(NotificationLaunchLedger.pluginPhase,
          NotificationPluginPhase.ready,
          reason: 'a foreground-isolate scan re-initializes; the launch '
              'listener must not see the plugin go back');
    });

    test('THROTTLE — a burst of distinct early taps routes each once, and '
        'the buffered duplicates of all of them are dropped', () {
      const burst = NotificationLaunchLedger.earlyTapBufferSize;
      final routed = <String>[];
      void tap(TapSource source, String payload) {
        switch (NotificationLaunchLedger.routeFor(source, payload)) {
          case TapRoute.routeAndClaim:
            NotificationLaunchLedger.claimLaunchPayload(payload);
            routed.add(payload);
          case TapRoute.routeAndRecord:
            NotificationLaunchLedger.recordDelivered(payload);
            routed.add(payload);
          case TapRoute.drop:
            break;
        }
      }

      for (var i = 0; i < burst; i++) {
        tap(TapSource.probe, 'p$i');
        tap(TapSource.stream, 'p$i'); // the same tap, drained from the buffer
      }
      expect(routed, [for (var i = 0; i < burst; i++) 'p$i']);
    });
  });
}
