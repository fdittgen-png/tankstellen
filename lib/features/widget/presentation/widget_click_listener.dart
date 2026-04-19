import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

/// Listens for taps on a home-screen widget row and navigates the app to
/// the matching station detail screen (#713). Two code paths:
///
/// 1. **Cold start** — the app was launched by tapping a widget row.
///    [HomeWidget.initiallyLaunchedFromHomeWidget] returns the URI that
///    the PendingIntent carried; we route to it once the Navigator is
///    ready.
/// 2. **Warm click** — the app is already running when the user taps a
///    row. [HomeWidget.widgetClicked] emits the URI; we route
///    immediately.
///
/// URI contract (set by `StationWidgetRenderer.buildActivity`):
/// `tankstellenwidget://station?id=<stationId>`
class WidgetClickListener extends StatefulWidget {
  final Widget child;
  const WidgetClickListener({super.key, required this.child});

  @override
  State<WidgetClickListener> createState() => _WidgetClickListenerState();
}

class _WidgetClickListenerState extends State<WidgetClickListener> {
  StreamSubscription<Uri?>? _subscription;

  @override
  void initState() {
    super.initState();
    _handleInitialLaunch();
    _subscription = HomeWidget.widgetClicked.listen(_handleUri);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialLaunch() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      // Let the router settle after cold start before pushing a route —
      // otherwise GoRouter may not have attached the navigator yet.
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(uri));
    } catch (e) {
      debugPrint('WidgetClickListener: initial launch probe failed: $e');
    }
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != 'tankstellenwidget') return;
    if (uri.host != 'station') return;
    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return;
    if (!mounted) return;
    try {
      GoRouter.of(context).push('/station/$id');
    } catch (e) {
      debugPrint('WidgetClickListener: navigation failed for $uri: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
