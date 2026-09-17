// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router.dart';
import 'local_notification_service.dart';
import 'notification_launch_ledger.dart';
import 'notification_plugin_phase.dart';
import 'notification_payload.dart';
import 'notification_tap_dispatcher.dart';
import '../../core/logging/error_logger.dart';

part 'notification_launch_listener.g.dart';

/// Routes a decoded notification payload onto the live [GoRouter].
///
/// Split out from [NotificationLaunchListener] so the routing layer is
/// testable without pumping the full widget tree and without leaning
/// on `GoRouter.of(context)` from above the `InheritedGoRouter` —
/// same pattern (and same debugging history) as the home-widget
/// equivalent in `lib/features/widget/presentation/widget_click_listener.dart`.
class NotificationLaunchHandler {
  final GoRouter _router;

  NotificationLaunchHandler(this._router);

  /// Resolve [rawPayload] to a router path and push it. No-op for
  /// payloads that fail to decode or that don't have a registered
  /// route — payload schema can grow ahead of routing without
  /// crashing the user back to the launcher.
  void handle(String? rawPayload) {
    final payload = NotificationPayload.tryDecode(rawPayload);
    final path = payload?.toRouterPath();
    debugPrint(
      'NotificationLaunchHandler.handle payload=$rawPayload path=$path '
      'outcome=${path == null ? "rejected" : "pushed"}',
    );
    if (path == null) return;
    try {
      unawaited(_router.push(path));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {'where': 'NotificationLaunchHandler: push failed for $rawPayload → $path'}));
    }
  }
}

@riverpod
NotificationLaunchHandler notificationLaunchHandler(Ref ref) {
  return NotificationLaunchHandler(ref.watch(routerProvider));
}

/// Listens for notification taps and navigates the app to the
/// matching detail screen (#1012 phase 3).
///
/// Two code paths:
///
/// 1. **Cold start** — the user tapped a notification while the app
///    was killed. [LocalNotificationService.getColdLaunchPayload]
///    surfaces the payload from `getNotificationAppLaunchDetails()`.
/// 2. **Warm tap** — the app is already running. The plugin's
///    `onDidReceiveNotificationResponse` callback (registered in
///    [LocalNotificationService.initialize]) pumps payloads through
///    [NotificationTapDispatcher].
///
/// Both paths funnel through [NotificationLaunchHandler] so the
/// routing logic has a single, tested entry point.
///
/// #4317 — `initialize()` now runs after the first frame, so the cold probe
/// can run BEFORE the plugin is ready. The listener re-reads the launch
/// details once [NotificationLaunchLedger.pluginReady] completes, and the
/// ledger decides whether a probed payload is new — see it for the
/// per-platform reasons.
class NotificationLaunchListener extends ConsumerStatefulWidget {
  final Widget child;

  /// Test seam — supplies a service to read the cold-launch payload
  /// from. Production passes `null` and the listener constructs a
  /// throwaway [LocalNotificationService] (fine because cold-launch
  /// only reads from the plugin's static side).
  final LocalNotificationService? coldLaunchService;

  const NotificationLaunchListener({
    super.key,
    required this.child,
    this.coldLaunchService,
  });

  @override
  ConsumerState<NotificationLaunchListener> createState() =>
      _NotificationLaunchListenerState();
}

class _NotificationLaunchListenerState
    extends ConsumerState<NotificationLaunchListener> {
  StreamSubscription<String?>? _subscription;

  @override
  void initState() {
    super.initState();
    unawaited(_handleColdLaunch());
    _subscription =
        // #4070 — only the payloads addressed to this handler.
        NotificationTapDispatcher.instance.launchPayloads.listen(_onTap);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _handleColdLaunch() async {
    try {
      final service = widget.coldLaunchService ?? LocalNotificationService();
      final wasReady = NotificationLaunchLedger.isPluginReady;
      final payload = await service.getColdLaunchPayload();
      // The router may not have attached its Navigator yet on cold
      // start. Defer to after the first frame so `push` lands on a
      // live navigator rather than an empty stack.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _routeProbed(payload));
      if (wasReady) return;
      // #4317 — a tap that arrived before the deferred initialize() is
      // only visible in the launch details on iOS; read them once more.
      await NotificationLaunchLedger.pluginReady;
      if (!mounted) return;
      _routeProbed(await service.getColdLaunchPayload());
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'NotificationLaunchListener: cold-launch probe failed'}));
    }
  }

  void _routeProbed(String? payload) => _route(TapSource.probe, payload);

  // Before the plugin is ready a stream tap is the channel buffer draining —
  // on Android the same tap the launch probe may already have routed
  // through `setIntent`. Only a tap after that is a fresh gesture. The rule
  // is [kLaunchTapRouting]'s (#4162).
  void _onTap(String? payload) => _route(TapSource.stream, payload);

  void _route(TapSource source, String? payload) {
    switch (NotificationLaunchLedger.routeFor(source, payload)) {
      case TapRoute.drop:
        return;
      case TapRoute.routeAndClaim:
        // Claimed only when actually routed, so an unmounted listener
        // leaves it for its remounted successor.
        if (!mounted) return;
        NotificationLaunchLedger.claimLaunchPayload(payload);
        _dispatch(payload);
      case TapRoute.routeAndRecord:
        NotificationLaunchLedger.recordDelivered(payload);
        _dispatch(payload);
    }
  }

  void _dispatch(String? payload) {
    if (!mounted) return;
    if (payload == null) return;
    ref.read(notificationLaunchHandlerProvider).handle(payload);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
