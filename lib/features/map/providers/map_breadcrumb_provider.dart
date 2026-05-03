import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/map_breadcrumb_collector.dart';

part 'map_breadcrumb_provider.g.dart';

/// Riverpod-backed wrapper around [MapBreadcrumbCollector] so widgets
/// (the in-app debug overlay, tests) can subscribe to breadcrumb
/// updates without poking the collector directly (#1316 phase 2).
///
/// `keepAlive: true` because the breadcrumbs are most useful on cold
/// start, BEFORE any consumer mounts — auto-disposing on listener-zero
/// would throw away the very first frame's trace.
@Riverpod(keepAlive: true)
class MapBreadcrumbsNotifier extends _$MapBreadcrumbsNotifier {
  late final MapBreadcrumbCollector _collector;

  @override
  List<MapBreadcrumb> build() {
    _collector = MapBreadcrumbCollector();
    return const [];
  }

  /// Pushes a `[tag] message` breadcrumb into the underlying ring
  /// buffer and republishes the (immutable) entries list so listeners
  /// rebuild.
  void record(String tag, String message) {
    _collector.record(tag, message);
    state = _collector.entries;
  }

  /// Drops every recorded breadcrumb. Called from the overlay's
  /// "Clear" button.
  void clear() {
    _collector.clear();
    state = const [];
  }
}
