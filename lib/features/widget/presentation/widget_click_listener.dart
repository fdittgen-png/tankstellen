import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/router.dart';
import '../../consumption/data/obd2/event_channel_cancel.dart';

part 'widget_click_listener.g.dart';

/// Parse a widget launch URI into the router path it should push.
///
/// URI contract (set natively by `StationWidgetRenderer.buildActivity`):
/// `tankstellenwidget://station?id=<stationId>`. EV stations use the
/// OpenChargeMap `ocm-` prefix; those route to the EV detail screen so
/// the user sees connectors/power rather than the fuel-price UI.
///
/// Returns `null` for any URI that isn't a valid widget launch — the
/// caller must treat that as a no-op.
String? widgetUriToPath(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'tankstellenwidget') return null;
  if (uri.host != 'station') return null;
  final id = uri.queryParameters['id'];
  if (id == null || id.isEmpty) return null;
  return id.startsWith('ocm-') ? '/ev-station/$id' : '/station/$id';
}

/// Pushes the widget-launch destination onto the router.
///
/// Split out from [WidgetClickListener] so the navigation layer is
/// testable without pumping the full widget tree and without relying
/// on `GoRouter.of(context)` — which silently failed when called from
/// `MaterialApp.router`'s `builder:` context, because that context
/// sits **above** the `InheritedGoRouter` the router widget inserts.
/// This is the class that the `homeWidget.widgetClicked` stream and
/// the cold-start launch probe both drive.
class WidgetLaunchHandler {
  final GoRouter _router;

  WidgetLaunchHandler(this._router);

  void handle(Uri? uri) {
    final path = widgetUriToPath(uri);
    // #753 diagnostic — prints every widget launch so the user can
    // diff what Kotlin bound to the row (see StationWidgetRenderer
    // `TankstellenWidget` logcat tag) against what Flutter received.
    debugPrint(
      'WidgetLaunchHandler.handle uri=$uri path=$path '
      'outcome=${path == null ? "rejected" : "pushed"}',
    );
    if (path == null) return;
    try {
      _router.push(path);
    } catch (e, st) {
      debugPrint('WidgetLaunchHandler: push failed for $uri → $path: $e\n$st');
    }
  }
}

@riverpod
WidgetLaunchHandler widgetLaunchHandler(Ref ref) {
  return WidgetLaunchHandler(ref.watch(routerProvider));
}

/// Listens for taps on a home-screen widget row and navigates the app
/// to the matching station detail screen. Two code paths:
///
/// 1. **Cold start** — the app was launched by tapping a widget row.
///    [HomeWidget.initiallyLaunchedFromHomeWidget] returns the URI the
///    PendingIntent carried.
/// 2. **Warm click** — the app is already running when the user taps a
///    row. [HomeWidget.widgetClicked] emits the URI.
///
/// Both paths delegate to [WidgetLaunchHandler] so the routing logic
/// has a single, tested entry point.
class WidgetClickListener extends ConsumerStatefulWidget {
  final Widget child;
  const WidgetClickListener({super.key, required this.child});

  @override
  ConsumerState<WidgetClickListener> createState() =>
      _WidgetClickListenerState();
}

class _WidgetClickListenerState extends ConsumerState<WidgetClickListener> {
  StreamSubscription<Uri?>? _subscription;

  @override
  void initState() {
    super.initState();
    _handleInitialLaunch();
    _subscription = HomeWidget.widgetClicked.listen(_dispatch);
  }

  @override
  void dispose() {
    // #1352 — `HomeWidget.widgetClicked` is backed by the
    // `home_widget/updates` EventChannel; the platform may have
    // already torn the broadcast down (lifecycle race during navigation
    // or process kill), and the resulting benign
    // `PlatformException("No active stream to cancel")` would otherwise
    // bubble through the privacy-dashboard error log.
    unawaited(_subscription?.safeCancel());
    super.dispose();
  }

  Future<void> _handleInitialLaunch() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      // The router may not have attached its Navigator yet on cold
      // start. Defer until after the first frame so `push` lands on a
      // live navigator rather than an empty stack.
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch(uri));
    } catch (e, st) {
      debugPrint('WidgetClickListener: initial launch probe failed: $e\n$st');
    }
  }

  void _dispatch(Uri? uri) {
    if (!mounted) return;
    ref.read(widgetLaunchHandlerProvider).handle(uri);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
