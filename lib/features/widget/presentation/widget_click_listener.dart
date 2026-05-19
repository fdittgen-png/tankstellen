import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/router.dart';
import '../../consumption/data/obd2/event_channel_cancel.dart';
import '../providers/nearest_widget_refresh_provider.dart';
import 'widget_uri_parser.dart';

export 'widget_uri_parser.dart' show isWidgetRefreshUri, widgetUriToPath;

part 'widget_click_listener.g.dart';

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

  /// Invoked when the launch URI is the [isWidgetRefreshUri] marker —
  /// rebuilds the home-screen widget instead of navigating (#1961).
  final VoidCallback _onRefresh;

  WidgetLaunchHandler(this._router, this._onRefresh);

  void handle(Uri? uri) {
    // #1961 — the refresh button launches the app with a `refresh`
    // marker URI rather than a station route. Rebuild the widget and
    // stay on whatever screen the user is on; never navigate.
    if (isWidgetRefreshUri(uri)) {
      debugPrint('WidgetLaunchHandler.handle uri=$uri outcome=refresh');
      _onRefresh();
      return;
    }
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
  return WidgetLaunchHandler(
    ref.watch(routerProvider),
    // Lazily triggered — only a refresh-marker tap reads (and so starts)
    // the keep-alive refresh provider; an ordinary row tap never does.
    () => ref.read(nearestWidgetRefreshProvider.notifier).refresh(),
  );
}

/// Listens for taps on a home-screen widget row and navigates the app
/// to the matching station detail screen.
///
/// **Warm click only**: the app is already running and the user taps a
/// row in the home-screen widget. [HomeWidget.widgetClicked] emits the
/// URI and we push the matching route on top of the current navigation
/// stack.
///
/// **Cold start** is handled one layer up by the router's redirect
/// chain, which consumes the URI stashed by
/// `AppInitializer._stashWidgetLaunchUri` before the first frame paints
/// (#widget-deeplink). Reading the URI synchronously at app boot —
/// rather than racing a post-frame callback against the redirect — is
/// what stops the landing-screen flash and the (intermittent) lost
/// deep link.
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

  void _dispatch(Uri? uri) {
    if (!mounted) return;
    ref.read(widgetLaunchHandlerProvider).handle(uri);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
