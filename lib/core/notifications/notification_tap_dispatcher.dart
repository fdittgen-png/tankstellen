import 'dart:async';

import 'package:flutter/foundation.dart';

/// Singleton broadcast hub for notification taps (#1012 phase 3).
///
/// `flutter_local_notifications` exposes a single
/// `onDidReceiveNotificationResponse` callback per `initialize()` call.
/// We bridge that into a broadcast stream so any widget in the app
/// (most importantly the `NotificationLaunchListener` mounted from
/// `lib/app/app.dart`) can subscribe without having to be the one
/// instance that called `initialize()`.
///
/// The dispatcher is static-by-design because the plugin keeps a
/// stable reference to the callback for the lifetime of the process —
/// dropping it on widget disposal would mean a tap during a hot reload
/// or a riverpod-rebuilt service silently disappears.
class NotificationTapDispatcher {
  NotificationTapDispatcher._internal();

  static final NotificationTapDispatcher instance =
      NotificationTapDispatcher._internal();

  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  /// Stream of raw payload strings emitted by every warm
  /// notification tap. Subscribers must decode the payload via
  /// `NotificationPayload.tryDecode` — the dispatcher deliberately
  /// stays schema-free so legacy or non-radius notifications can pass
  /// through without crashing the listener.
  Stream<String?> get stream => _controller.stream;

  /// Pump a payload onto the stream. Called from the static plugin
  /// callback in `LocalNotificationService`. Visible for tests so a
  /// fake tap can be injected without going through the plugin.
  void dispatch(String? payload) {
    if (_controller.isClosed) return;
    _controller.add(payload);
  }

  /// Tear-down hook for tests. Production code never closes the
  /// controller — the singleton stays alive for the process lifetime.
  @visibleForTesting
  Future<void> debugClose() async {
    if (_controller.isClosed) return;
    await _controller.close();
  }
}
