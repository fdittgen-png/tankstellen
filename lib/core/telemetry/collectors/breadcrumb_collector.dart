// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';
import '../models/error_trace.dart';

class BreadcrumbCollector {
  static const int maxBreadcrumbs = 25;
  static final _ring = Queue<Breadcrumb>();

  /// #3580 — notified after every [add] so `BreadcrumbPersistence` can
  /// mirror the ring to disk (crash-surviving context). Null until the
  /// persistence layer initialises; the callback must never throw.
  static void Function()? onAdd;

  static void add(String action, {String? detail}) {
    _ring.addLast(Breadcrumb(
      timestamp: DateTime.now(),
      action: action,
      detail: detail,
    ));
    while (_ring.length > maxBreadcrumbs) {
      _ring.removeFirst();
    }
    onAdd?.call();
  }

  static List<Breadcrumb> snapshot() => List.unmodifiable(_ring);
  static void clear() => _ring.clear();
}
