// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The notification plugin's lifecycle and the tap-routing decision,
/// written down (#4162).
///
/// `NotificationLaunchLedger` held both as a `Completer` and a `Set`, and
/// the routing rule lived in prose in its doc and in two methods of
/// `NotificationLaunchListener` that had to agree with it. The enum and the
/// table below are that prose as data: the ledger owns the phase, and the
/// listener looks every decision up here.
library;

/// Where the notification plugin is in this isolate (#4162).
///
/// * [pending] — `LocalNotificationService.initialize()` has not finished;
///   a tap cannot reach a handler yet (#4317).
/// * [ready] — it finished and registered the tap handler.
/// * [initFailed] — it threw. Treated like [ready] for routing: no handler
///   was registered, so no stream tap arrives, and the launch details are
///   still readable. A hidden sub-state, not a routing input.
///
/// Both [ready] and [initFailed] are terminal for the isolate: the first
/// initialize that finishes decides, and a later one (a foreground-isolate
/// scan initializes again) is not a transition.
enum NotificationPluginPhase { pending, ready, initFailed }

/// Every plugin-phase change the ledger makes (#4162).
const Map<NotificationPluginPhase, Set<NotificationPluginPhase>>
    kNotificationPluginTransitions = {
  NotificationPluginPhase.pending: {
    NotificationPluginPhase.ready,
    NotificationPluginPhase.initFailed,
  },
  NotificationPluginPhase.ready: {},
  NotificationPluginPhase.initFailed: {},
};

/// How a notification tap reached the app.
enum TapSource {
  /// Read from `getNotificationAppLaunchDetails()` — the cold-launch probe,
  /// or its one re-read after the plugin is ready.
  probe,

  /// Delivered through the plugin's tap callback.
  stream,
}

/// What the listener does with a tap.
enum TapRoute {
  /// Route it, and claim the payload so no later probe routes it again.
  routeAndClaim,

  /// Route it, and record the payload as delivered.
  routeAndRecord,

  /// Do nothing: no payload, or a payload already routed.
  drop,
}

/// The routing decision for a non-null payload, keyed by the plugin phase,
/// the tap's source, and whether that payload was already routed this
/// process (#4317, #4162).
///
/// * A probed payload routes once per process — a remount (the app tree is
///   keyed on the language) must not replay a cold-launch deep link.
/// * A stream tap while the plugin is pending is the Android channel buffer
///   draining: the same tap `setIntent` put in the launch details, so it is
///   deduplicated like a probe.
/// * A stream tap once the plugin is ready (or its init failed) is a fresh
///   gesture — the same payload twice routes twice.
const Map<(NotificationPluginPhase, TapSource, bool), TapRoute>
    kLaunchTapRouting = {
  (NotificationPluginPhase.pending, TapSource.probe, false):
      TapRoute.routeAndClaim,
  (NotificationPluginPhase.pending, TapSource.probe, true): TapRoute.drop,
  (NotificationPluginPhase.pending, TapSource.stream, false):
      TapRoute.routeAndClaim,
  (NotificationPluginPhase.pending, TapSource.stream, true): TapRoute.drop,
  (NotificationPluginPhase.ready, TapSource.probe, false):
      TapRoute.routeAndClaim,
  (NotificationPluginPhase.ready, TapSource.probe, true): TapRoute.drop,
  (NotificationPluginPhase.ready, TapSource.stream, false):
      TapRoute.routeAndRecord,
  (NotificationPluginPhase.ready, TapSource.stream, true):
      TapRoute.routeAndRecord,
  (NotificationPluginPhase.initFailed, TapSource.probe, false):
      TapRoute.routeAndClaim,
  (NotificationPluginPhase.initFailed, TapSource.probe, true): TapRoute.drop,
  (NotificationPluginPhase.initFailed, TapSource.stream, false):
      TapRoute.routeAndRecord,
  (NotificationPluginPhase.initFailed, TapSource.stream, true):
      TapRoute.routeAndRecord,
};

/// The route for a tap carrying [payload]; a null payload is always
/// [TapRoute.drop].
TapRoute launchTapRoute(
  NotificationPluginPhase phase,
  TapSource source, {
  required String? payload,
  required bool alreadyRouted,
}) =>
    payload == null
        ? TapRoute.drop
        : kLaunchTapRouting[(phase, source, alreadyRouted)]!;
