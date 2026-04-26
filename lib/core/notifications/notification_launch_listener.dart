import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router.dart';
import 'local_notification_service.dart';
import 'notification_payload.dart';
import 'notification_tap_dispatcher.dart';

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
      _router.push(path);
    } catch (e, st) {
      debugPrint('NotificationLaunchHandler: push failed for $rawPayload → $path: $e\n$st');
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
    _handleColdLaunch();
    _subscription =
        NotificationTapDispatcher.instance.stream.listen(_dispatch);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleColdLaunch() async {
    try {
      final service = widget.coldLaunchService ?? LocalNotificationService();
      final payload = await service.getColdLaunchPayload();
      // The router may not have attached its Navigator yet on cold
      // start. Defer to after the first frame so `push` lands on a
      // live navigator rather than an empty stack.
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch(payload));
    } catch (e, st) {
      debugPrint('NotificationLaunchListener: cold-launch probe failed: $e\n$st');
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
