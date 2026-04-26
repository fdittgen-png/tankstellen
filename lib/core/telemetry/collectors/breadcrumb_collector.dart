import 'dart:collection';
import '../models/error_trace.dart';

class BreadcrumbCollector {
  static const int maxBreadcrumbs = 25;
  static final _ring = Queue<Breadcrumb>();

  static void add(String action, {String? detail}) {
    _ring.addLast(Breadcrumb(
      timestamp: DateTime.now(),
      action: action,
      detail: detail,
    ));
    while (_ring.length > maxBreadcrumbs) {
      _ring.removeFirst();
    }
  }

  static List<Breadcrumb> snapshot() => List.unmodifiable(_ring);
  static void clear() => _ring.clear();
}
