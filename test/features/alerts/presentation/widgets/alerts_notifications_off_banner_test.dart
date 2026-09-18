// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_delivery.dart';
import 'package:tankstellen/core/notifications/notification_providers.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_notifications_off_banner.dart';

import '../../../../helpers/pump_app.dart';

/// A notifier whose OS answer the test sets.
class _Os implements NotificationService, NotificationDeliveryProbe {
  _Os(this.blocked);
  NotificationDelivery? blocked;
  int settingsOpened = 0;

  @override
  Future<NotificationDelivery?> blockedDelivery(
          NotificationChannelKind channel) async =>
      blocked;

  @override
  Future<bool> openNotificationSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async => blocked == null;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}

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

/// #4335 — "notifications are off", with a way out, on the alerts screen.
void main() {
  const banner = ValueKey('alerts-notifications-off-banner');
  const action = ValueKey('alerts-notifications-off-open-settings');

  Future<_Os> pump(WidgetTester tester, NotificationDelivery? blocked,
      {Locale locale = const Locale('en')}) async {
    final os = _Os(blocked);
    await pumpApp(
      tester,
      const AlertsNotificationsOffBanner(),
      overrides: [notificationServiceProvider.overrideWithValue(os)],
      locale: locale,
    );
    return os;
  }

  testWidgets('permission revoked: says so, and opens the settings',
      (tester) async {
    final os = await pump(tester, NotificationDelivery.suppressedPermission);

    expect(find.byKey(banner), findsOneWidget);
    expect(find.text('Notifications are off'), findsOneWidget);
    expect(find.textContaining('notifications for this app are turned off'),
        findsOneWidget);
    expect(find.textContaining('still checked'), findsOneWidget,
        reason: 'honest: the scans did not stop');

    await tester.tap(find.byKey(action));
    await tester.pump();
    expect(os.settingsOpened, 1);
  });

  testWidgets('channel disabled: names the price-alert notifications',
      (tester) async {
    await pump(tester, NotificationDelivery.suppressedChannel);
    expect(find.textContaining('price alert notifications are turned off'),
        findsOneWidget);
  });

  testWidgets('notifications on: nothing', (tester) async {
    await pump(tester, null);
    expect(find.byKey(banner), findsNothing);
  });

  testWidgets('a probe that cannot answer: nothing — unknown is not "off"',
      (tester) async {
    await pump(tester, NotificationDelivery.failed);
    expect(find.byKey(banner), findsNothing);
  });

  testWidgets('coming back from the settings with notifications on clears it',
      (tester) async {
    final os = await pump(tester, NotificationDelivery.suppressedPermission);
    expect(find.byKey(banner), findsOneWidget);

    os.blocked = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(banner), findsNothing);
  });

  testWidgets('localized: German', (tester) async {
    await pump(tester, NotificationDelivery.suppressedPermission,
        locale: const Locale('de'));
    expect(find.text('Benachrichtigungen sind aus'), findsOneWidget);
    expect(find.text('Einstellungen öffnen'), findsOneWidget);
  });

  testWidgets('localized: French', (tester) async {
    await pump(tester, NotificationDelivery.suppressedChannel,
        locale: const Locale('fr'));
    expect(find.text('Les notifications sont désactivées'), findsOneWidget);
    expect(find.text('Ouvrir les réglages'), findsOneWidget);
  });
}
