// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';
import 'notification_tap_dispatcher.dart';
import '../../core/logging/error_logger.dart';

/// Default [NotificationService] implementation backed by
/// `flutter_local_notifications`.
///
/// Uses the Android `price_alerts` channel for high-priority price drop
/// notifications. On iOS the same plugin handles the UNUserNotificationCenter
/// setup (not yet active — iOS build is disabled).
class LocalNotificationService implements NotificationService {
  /// Visible for testing — allows injecting a fake plugin.
  final FlutterLocalNotificationsPlugin plugin;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'price_alerts';
  static const _channelName = 'Price Alerts';
  static const _channelDescription =
      'Notifications when fuel prices drop below your target';

  /// #584 — separate channel for service reminders so the user can
  /// independently mute maintenance reminders without muting price
  /// drops (and vice versa). Default importance is lower than price
  /// alerts — a missed oil change is less time-sensitive than a
  /// short-lived price dip.
  static const _serviceChannelId = 'service_reminders';
  static const _serviceChannelName = 'Service reminders';
  static const _serviceChannelDescription =
      'Reminders when your odometer crosses a scheduled service interval';

  @override
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    // #1012 phase 3 — register the tap callback so the launch listener
    // (wired in lib/app/app.dart) can resolve payloads to deep-link
    // targets. The static dispatcher fans out so any number of warm
    // listeners can subscribe; cold-launch reads `getNotificationApp
    // LaunchDetails()` separately and doesn't depend on this hook
    // having been wired in time.
    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    // #2209 — create the channels explicitly at init so they exist
    // before the first fire (v21 would lazily create on first show(),
    // but explicit lets the user pre-configure them).
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    ));
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _serviceChannelId,
      _serviceChannelName,
      description: _serviceChannelDescription,
    ));
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // #2209 — Android 13+ requires the runtime POST_NOTIFICATIONS
        // grant; the manifest declaration alone is insufficient and
        // show() silently no-ops until this is granted.
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st,
          context: const {'where': 'NotificationService.requestPermission'}));
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'NotificationService.areNotificationsEnabled',
      }));
      return true;
    }
  }

  /// Static entry point so flutter_local_notifications keeps a stable
  /// reference even when the [LocalNotificationService] instance is
  /// rebuilt (Riverpod overrides, hot reload, etc.). Pumps every
  /// notification tap into the global dispatcher.
  static void _onDidReceiveNotificationResponse(
      NotificationResponse response) {
    NotificationTapDispatcher.instance.dispatch(response.payload);
  }

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _serviceChannelId,
        _serviceChannelName,
        channelDescription: _serviceChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await plugin.show(
        id: id, title: title, body: body, notificationDetails: details);
  }

  @override
  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  /// Probes whether a notification tap launched the app from a cold
  /// start and, if so, returns the payload it carried. Returns `null`
  /// when the launch was not from a notification (or the plugin
  /// reported no payload). Surfaces errors as `null` rather than
  /// throwing so the launch listener can degrade gracefully.
  Future<String?> getColdLaunchPayload() async {
    try {
      final details = await plugin.getNotificationAppLaunchDetails();
      if (details == null) return null;
      if (!details.didNotificationLaunchApp) return null;
      return details.notificationResponse?.payload;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'LocalNotificationService.getColdLaunchPayload failed'}));
      return null;
    }
  }
}
