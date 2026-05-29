// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_providers.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/developer_tools_screen.dart';

import '../../../../../helpers/pump_app.dart';

/// TraceStorage that never touches Hive — the screen reads `count`
/// during build.
class _StubTraceStorage extends TraceStorage {
  @override
  int get count => 0;
}

/// Records every notification fired by the screen's actions so the test
/// can assert the test-alert / test-notification path reaches the
/// service. Permission is granted by default; set [permissionGranted] to
/// false to exercise the blocked path.
class _FakeNotifier implements NotificationService {
  _FakeNotifier({this.permissionGranted = true});

  final bool permissionGranted;
  final List<({int id, String title, String body})> fired = [];

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    fired.add((id: id, title: title, body: body));
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  group('DeveloperToolsScreen (#2248)', () {
    List<Object> overrides({
      required bool debugOn,
      _FakeNotifier? notifier,
    }) =>
        [
          enabledFeaturesProvider.overrideWithValue(
            debugOn ? {Feature.debugMode} : <Feature>{},
          ),
          buildChannelProvider.overrideWithValue(BuildChannel.beta),
          traceStorageProvider.overrideWithValue(_StubTraceStorage()),
          notificationServiceProvider
              .overrideWithValue(notifier ?? _FakeNotifier()),
        ];

    testWidgets('renders the dev tools when debugMode is ON', (tester) async {
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true),
      );

      expect(find.byKey(const ValueKey('error-log-export-button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-fire-test-notification')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-run-test-alert')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-feature-flag-dump')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-clear-caches')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('debug-copy-diagnostics')),
          findsOneWidget);
    });

    testWidgets('renders nothing when debugMode is OFF (defensive guard)',
        (tester) async {
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: false),
      );

      // The defensive guard collapses the body to an empty shrink so a
      // stale deep-link can never expose the tools.
      expect(find.byKey(const ValueKey('error-log-export-button')),
          findsNothing);
      expect(find.byKey(const ValueKey('debug-fire-test-notification')),
          findsNothing);
      expect(find.byKey(const ValueKey('debug-run-test-alert')),
          findsNothing);
    });

    testWidgets('Fire test notification invokes the notification service',
        (tester) async {
      final notifier = _FakeNotifier();
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(
        find.byKey(const ValueKey('debug-fire-test-notification')),
      );
      await tester.pumpAndSettle();

      expect(notifier.fired, hasLength(1));
    });

    testWidgets('Run test alert pipeline invokes the notification service',
        (tester) async {
      final notifier = _FakeNotifier();
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(find.byKey(const ValueKey('debug-run-test-alert')));
      await tester.pumpAndSettle();

      expect(notifier.fired, hasLength(1),
          reason: 'the synthetic match must drive the real pipeline to '
              'deliver exactly one notification');
    });

    testWidgets('blocked notifications fire nothing on Fire test notification',
        (tester) async {
      final notifier = _FakeNotifier(permissionGranted: false);
      await pumpApp(
        tester,
        const DeveloperToolsScreen(),
        overrides: overrides(debugOn: true, notifier: notifier),
      );

      await tester.tap(
        find.byKey(const ValueKey('debug-fire-test-notification')),
      );
      await tester.pumpAndSettle();

      expect(notifier.fired, isEmpty);
    });
  });
}
