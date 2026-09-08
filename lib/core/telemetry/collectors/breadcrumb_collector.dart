// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';
import '../../logging/run_scope.dart';
import '../models/error_trace.dart';

class BreadcrumbCollector {
  static const int maxBreadcrumbs = 25;
  static final _ring = Queue<Breadcrumb>();

  /// #3580 — notified after every [add] so `BreadcrumbPersistence` can
  /// mirror the ring to disk (crash-surviving context). Null until the
  /// persistence layer initialises; the callback must never throw.
  static void Function()? onAdd;

  /// Records a milestone. Every crumb carries an [area], a [level] and —
  /// inside a [RunScope] — the run's id (#3980), so the 25-slot ring can
  /// be filtered by subsystem or grouped by run in the export instead of
  /// only being read newest-first.
  ///
  /// [area] defaults to the action's leading token, lower-cased
  /// (`'OBD2 link drop'` → `obd2`, `'bt.teardown_fail'` → `bt`,
  /// `'sync'` → `sync`); pass it explicitly where that would mislead.
  static void add(
    String action, {
    String? detail,
    String? area,
    String level = 'info',
  }) {
    _ring.addLast(Breadcrumb(
      timestamp: DateTime.now(),
      action: action,
      detail: detail,
      area: area ?? areaOf(action),
      level: level,
      runId: RunScope.currentId,
    ));
    while (_ring.length > maxBreadcrumbs) {
      _ring.removeFirst();
    }
    onAdd?.call();
  }

  /// The leading token of [action], lower-cased: split on the first
  /// space, `.`, `:` or `-`. `'trip tile action'` → `trip`.
  static String areaOf(String action) {
    final m = RegExp(r'^[A-Za-z0-9_]+').firstMatch(action.trim());
    return (m?.group(0) ?? action).toLowerCase();
  }

  static List<Breadcrumb> snapshot() => List.unmodifiable(_ring);
  static void clear() => _ring.clear();
}
