import 'package:flutter/material.dart';
import '../collectors/app_state_collector.dart';
import '../collectors/breadcrumb_collector.dart';

class NavigationTraceObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _track(previousRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name ?? 'unknown';
    AppStateCollector.updateRoute(name);
    BreadcrumbCollector.add('navigate:$name');
  }
}
