import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';

/// A hand-written fake of [FlutterLocalNotificationsPlugin] that records
/// every interaction. Implements the public surface we exercise; falls
/// back to mocktail's [Fake] for everything else so unrelated plugin
/// methods don't blow up the test if they're touched indirectly.
class _FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<_ShowCall> showCalls = [];
  final List<int> cancelledIds = [];
  int cancelAllCalls = 0;
  bool initializeCalled = false;
  InitializationSettings? lastInitSettings;
  DidReceiveNotificationResponseCallback? lastOnDidReceiveResponse;

  /// Configurable launch-details for [getNotificationAppLaunchDetails].
  /// Set [launchDetailsThrows] to force the throwing path.
  NotificationAppLaunchDetails? launchDetails;
  bool launchDetailsThrows = false;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    lastInitSettings = settings;
    lastOnDidReceiveResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    showCalls.add(_ShowCall(
      id: id,
      title: title,
      body: body,
      details: notificationDetails,
      payload: payload,
    ));
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    if (launchDetailsThrows) {
      throw Exception('boom');
    }
    return launchDetails;
  }
}

class _ShowCall {
  _ShowCall({
    required this.id,
    required this.title,
    required this.body,
    required this.details,
    required this.payload,
  });

  final int id;
  final String? title;
  final String? body;
  final NotificationDetails? details;
  final String? payload;
}

void main() {
  late _FakeFlutterLocalNotificationsPlugin fakePlugin;
  late LocalNotificationService service;

  setUp(() {
    fakePlugin = _FakeFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(plugin: fakePlugin);
  });

  group('LocalNotificationService.showPriceAlert', () {
    test('forwards id/title/body/payload to plugin.show', () async {
      await service.showPriceAlert(
        id: 42,
        title: 'Shell - E10',
        body: '1.459 EUR (target: 1.500 EUR)',
        payload: '{"type":"radius_alert","stationId":"abc"}',
      );

      expect(fakePlugin.showCalls, hasLength(1));
      final call = fakePlugin.showCalls.single;
      expect(call.id, 42);
      expect(call.title, 'Shell - E10');
      expect(call.body, '1.459 EUR (target: 1.500 EUR)');
      expect(call.payload, '{"type":"radius_alert","stationId":"abc"}');
    });

    test('uses the price_alerts channel with HIGH importance/priority',
        () async {
      await service.showPriceAlert(id: 1, title: 't', body: 'b');

      final android = fakePlugin.showCalls.single.details?.android;
      expect(android, isNotNull);
      expect(android!.channelId, 'price_alerts');
      expect(android.channelName, 'Price Alerts');
      expect(android.channelDescription,
          'Notifications when fuel prices drop below your target');
      expect(android.importance, Importance.high);
      expect(android.priority, Priority.high);
    });

    test('payload defaults to null when caller omits it', () async {
      await service.showPriceAlert(id: 7, title: 't', body: 'b');

      expect(fakePlugin.showCalls.single.payload, isNull);
    });

    test('multiple alerts each record a separate show call', () async {
      await service.showPriceAlert(id: 1, title: 'a', body: 'a');
      await service.showPriceAlert(id: 2, title: 'b', body: 'b');
      await service.showPriceAlert(id: 3, title: 'c', body: 'c');

      expect(fakePlugin.showCalls.map((c) => c.id), [1, 2, 3]);
    });
  });

  group('LocalNotificationService.showServiceReminder', () {
    test('forwards id/title/body to plugin.show', () async {
      await service.showServiceReminder(
        id: 99,
        title: 'Oil change due',
        body: 'Odometer crossed 15,000 km',
      );

      expect(fakePlugin.showCalls, hasLength(1));
      final call = fakePlugin.showCalls.single;
      expect(call.id, 99);
      expect(call.title, 'Oil change due');
      expect(call.body, 'Odometer crossed 15,000 km');
    });

    test('uses service_reminders channel (#584) with DEFAULT priority',
        () async {
      await service.showServiceReminder(id: 1, title: 't', body: 'b');

      final android = fakePlugin.showCalls.single.details?.android;
      expect(android, isNotNull);
      expect(android!.channelId, 'service_reminders');
      expect(android.channelName, 'Service reminders');
      expect(
        android.channelDescription,
        'Reminders when your odometer crosses a scheduled service interval',
      );
      expect(android.importance, Importance.defaultImportance);
      expect(android.priority, Priority.defaultPriority);
    });

    test('does NOT carry a payload (service reminders are not deep-linked)',
        () async {
      await service.showServiceReminder(id: 1, title: 't', body: 'b');

      expect(fakePlugin.showCalls.single.payload, isNull);
    });

    test('uses a distinct channel from price alerts so users can mute '
        'maintenance reminders independently (#584)', () async {
      await service.showPriceAlert(id: 1, title: 'price', body: 'p');
      await service.showServiceReminder(id: 2, title: 'service', body: 's');

      expect(fakePlugin.showCalls, hasLength(2));
      expect(fakePlugin.showCalls[0].details!.android!.channelId,
          'price_alerts');
      expect(fakePlugin.showCalls[1].details!.android!.channelId,
          'service_reminders');
      expect(
        fakePlugin.showCalls[0].details!.android!.channelId,
        isNot(fakePlugin.showCalls[1].details!.android!.channelId),
      );
    });
  });

  group('LocalNotificationService.cancelNotification', () {
    test('delegates to plugin.cancel with the supplied id', () async {
      await service.cancelNotification(42);
      await service.cancelNotification(7);

      expect(fakePlugin.cancelledIds, [42, 7]);
    });

    test('does not call cancelAll', () async {
      await service.cancelNotification(1);

      expect(fakePlugin.cancelAllCalls, 0);
    });
  });

  group('LocalNotificationService.cancelAll', () {
    test('delegates to plugin.cancelAll', () async {
      await service.cancelAll();

      expect(fakePlugin.cancelAllCalls, 1);
    });

    test('does not record any individual cancellations', () async {
      await service.cancelAll();

      expect(fakePlugin.cancelledIds, isEmpty);
    });
  });

  group('LocalNotificationService.initialize', () {
    test('calls plugin.initialize with non-null Android settings', () async {
      await service.initialize();

      expect(fakePlugin.initializeCalled, isTrue);
      expect(fakePlugin.lastInitSettings, isNotNull);
      expect(fakePlugin.lastInitSettings!.android, isNotNull);
    });

    test('registers a non-null onDidReceiveNotificationResponse callback '
        '(#1012 phase 3 — required for warm taps to dispatch)', () async {
      await service.initialize();

      expect(fakePlugin.lastOnDidReceiveResponse, isNotNull);
    });
  });

  group('LocalNotificationService.getColdLaunchPayload', () {
    test('returns null when plugin returns null launch details', () async {
      fakePlugin.launchDetails = null;

      final result = await service.getColdLaunchPayload();

      expect(result, isNull);
    });

    test('returns null when didNotificationLaunchApp is false', () async {
      fakePlugin.launchDetails = const NotificationAppLaunchDetails(
        false,
        notificationResponse: NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'should-be-ignored',
        ),
      );

      final result = await service.getColdLaunchPayload();

      expect(result, isNull);
    });

    test('returns the payload when didNotificationLaunchApp is true', () async {
      fakePlugin.launchDetails = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: 'cold-launch-payload',
        ),
      );

      final result = await service.getColdLaunchPayload();

      expect(result, 'cold-launch-payload');
    });

    test('returns null when launched but notificationResponse is null',
        () async {
      fakePlugin.launchDetails = const NotificationAppLaunchDetails(true);

      final result = await service.getColdLaunchPayload();

      expect(result, isNull);
    });

    test('returns null when launched but payload is null', () async {
      fakePlugin.launchDetails = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
        ),
      );

      final result = await service.getColdLaunchPayload();

      expect(result, isNull);
    });

    test('swallows plugin exceptions and returns null (graceful degradation)',
        () async {
      fakePlugin.launchDetailsThrows = true;

      final result = await service.getColdLaunchPayload();

      expect(result, isNull);
    });
  });

  group('LocalNotificationService construction', () {
    test('default constructor creates a plugin instance when none is supplied',
        () {
      final defaultService = LocalNotificationService();

      // ignore: unnecessary_type_check
      expect(defaultService.plugin, isA<FlutterLocalNotificationsPlugin>());
    });

    test('injected plugin is exposed via the public field', () {
      expect(service.plugin, same(fakePlugin));
    });
  });
}
