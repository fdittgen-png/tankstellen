// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'notification_plugin_phase.dart';

/// Makes notification taps deterministic while the notification plugin is
/// not yet initialised (#4317).
///
/// ## Why this exists
///
/// `LocalNotificationService.initialize()` used to finish before the real
/// app was launched, so by the time `NotificationLaunchListener` mounted,
/// every tap had one of two well-defined homes. #4317 moved that call past
/// the first frame, which opens an interval in which a tap can arrive with
/// no initialised plugin, and the two platforms handle it differently —
/// read from `flutter_local_notifications` 22.3.0:
///
/// * **iOS** — `didReceiveNotificationResponse` checks the plugin's native
///   `_initialized` flag. Before `initialize()` it does NOT forward the tap;
///   it overwrites the *launch* details that
///   `getNotificationAppLaunchDetails()` returns. The listener probes those
///   exactly once, at mount — so a tap landing between that probe and the
///   deferred `initialize()` would sit there unread: **dropped**.
/// * **Android** — `onNewIntent` forwards the tap over the method channel
///   regardless, AND calls `setIntent`, so the launch details report it
///   too. Before the Dart handler is registered the message waits in the
///   engine's channel buffer, whose default capacity is ONE: a second tap
///   in the interval discards the first.
///
/// ## The contract
///
/// * [markPluginReady] / [markPluginInitFailed] fire once `initialize()` has
///   finished. The listener then re-reads the launch details ONCE — that is
///   the iOS buffer. The ledger owns the resulting [NotificationPluginPhase]
///   (#4162); the listener looks its routing up in [kLaunchTapRouting]
///   through [routeFor].
/// * A payload read from the launch details is routed only if nothing has
///   routed it yet this process ([claimLaunchPayload]). On Android the same
///   tap arrives through the stream AND the intent; without this it would
///   navigate twice. It also stops a remount (the app tree is keyed on the
///   language) from replaying the cold-launch deep link.
/// * [reserveEarlyTapBuffer] widens the Android channel buffer before the
///   engine can deliver anything, so several early taps survive.
///
/// A tap that reaches the stream AFTER [markPluginReady] is a fresh user
/// gesture and is always routed. One that reaches it before is the Android
/// channel buffer draining, and is deduplicated like a probe result.
abstract final class NotificationLaunchLedger {
  /// The method channel `flutter_local_notifications` talks over.
  static const String pluginChannel =
      'dexterous.com/flutter/local_notifications';

  /// Taps the channel may hold before the plugin's handler is registered.
  /// Far above what a person can produce in the deferral interval.
  static const int earlyTapBufferSize = 16;

  static Completer<void> _pluginReady = Completer<void>();

  static NotificationPluginPhase _phase = NotificationPluginPhase.pending;

  /// Every payload that has been routed this process, by either path.
  static final Set<String> _routed = <String>{};

  /// Completes once the notification plugin's `initialize()` has finished,
  /// successfully or not.
  static Future<void> get pluginReady => _pluginReady.future;

  /// Where the plugin is in this isolate — owned here, written only by
  /// [markPluginReady] and [markPluginInitFailed].
  static NotificationPluginPhase get pluginPhase => _phase;

  /// Whether `initialize()` has finished — `pluginPhase != pending`.
  static bool get isPluginReady => _phase != NotificationPluginPhase.pending;

  /// Signals that `initialize()` succeeded. The first finish decides;
  /// idempotent after it.
  static void markPluginReady() => _finish(NotificationPluginPhase.ready);

  /// Signals that `initialize()` threw. Routing treats it like ready: the
  /// launch details stay readable, and no stream tap can arrive.
  static void markPluginInitFailed() =>
      _finish(NotificationPluginPhase.initFailed);

  static void _finish(NotificationPluginPhase to) {
    if (_phase != NotificationPluginPhase.pending) return;
    _phase = to;
    _pluginReady.complete();
  }

  /// The route for a tap with [payload] from [source], per
  /// [kLaunchTapRouting] and the current phase. Decides only — the caller
  /// claims ([claimLaunchPayload]) or records ([recordDelivered]) when it
  /// actually routes.
  static TapRoute routeFor(TapSource source, String? payload) =>
      launchTapRoute(_phase, source,
          payload: payload, alreadyRouted: _routed.contains(payload));

  /// Widens the engine-side buffer of [pluginChannel] so taps sent before
  /// the plugin registers its handler are queued rather than discarded.
  static void reserveEarlyTapBuffer() =>
      ui.channelBuffers.resize(pluginChannel, earlyTapBufferSize);

  /// Records a payload delivered through the tap stream. Always routed by
  /// the caller; recorded so a later launch-details probe that returns the
  /// same tap does not route it a second time.
  static void recordDelivered(String? payload) {
    if (payload != null) _routed.add(payload);
  }

  /// Whether a payload read from the launch details should be routed now.
  /// Claims it when so, so the next probe returning it gets `false`.
  static bool claimLaunchPayload(String? payload) {
    if (payload == null) return false;
    return _routed.add(payload);
  }

  /// Test isolation only.
  @visibleForTesting
  static void resetForTest() {
    _pluginReady = Completer<void>();
    _phase = NotificationPluginPhase.pending;
    _routed.clear();
  }
}
