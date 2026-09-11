// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

  /// #4070 — the trip tile's action payloads share this channel with the
  /// alert deep-link payloads. Every listener used to receive both and
  /// filter by shape; the launch handler `jsonDecode`d `trip_action:*`
  /// and logged a fabricated error per Stop tap (#4054), and the shape
  /// guard added there in turn hid a truncated alert payload. Namespace
  /// here instead: each listener sees only its own.
  static const String actionPrefix = 'trip_action:';

  /// Payloads addressed to the notification LAUNCH handler (alert
  /// deep-links): everything that is not a trip-tile action.
  Stream<String?> get launchPayloads =>
      stream.where((p) => p == null || !p.startsWith(actionPrefix));

  /// Payloads addressed to the trip tile (`trip_action:<id>`).
  Stream<String> get actionPayloads => stream
      .where((p) => p != null && p.startsWith(actionPrefix))
      .cast<String>();

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
