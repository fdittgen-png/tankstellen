/// In-memory ring buffer that captures every `[map-...]` breadcrumb
/// emitted by [MapScreen] during cold-start convergence (#1316 phase 2).
///
/// Phase 1 added [debugPrint] calls at every cold-start convergence
/// path (initState, lifecycle resume, branch listener, layout gate,
/// incarnation bump). Those prints only surface in `adb logcat`, which
/// the user has not been able to capture across the prior repros — so
/// the diagnostic loop never closes. Phase 2 routes the same messages
/// through this collector, which an in-app overlay can render so the
/// user can see the convergence trace on-device the moment a repro
/// happens.
///
/// The buffer is in-memory only — not persisted across launches —
/// because the only useful data is the trace from the current launch
/// (the previous launch's bug is already over). A 100-entry cap is
/// enough to capture every breadcrumb the screen produces during a
/// cold-start cycle (~10 messages typical) plus a few minutes of
/// follow-up tab flips and resumes; older entries drop on overflow.
library;

/// One breadcrumb entry — a [tag] (e.g. `map-cold-start`) plus the
/// human-readable [message] that followed it in the original
/// [debugPrint] call, with [at] capturing when it was recorded.
class MapBreadcrumb {
  /// When the breadcrumb was recorded.
  final DateTime at;

  /// The tag part of the original `[map-tag]` prefix, without the
  /// brackets — e.g. `map-cold-start`, `map-layout`, `map-incarn`,
  /// `map-lifecycle`, `map-branch`.
  final String tag;

  /// Free-text payload after the tag in the original [debugPrint] call.
  final String message;

  const MapBreadcrumb({
    required this.at,
    required this.tag,
    required this.message,
  });
}

/// Ring buffer of recent map breadcrumbs. Capped at [maxEntries]
/// entries; oldest drop on overflow. Pure in-memory — not persisted
/// across launches (#1316 phase 2).
class MapBreadcrumbCollector {
  /// Maximum number of breadcrumbs retained. The map screen produces
  /// ~10 breadcrumbs during a typical cold-start cycle, so 100 covers
  /// 10× headroom for follow-up tab flips and resume cycles before
  /// older entries are evicted.
  static const int maxEntries = 100;

  final List<MapBreadcrumb> _entries = [];

  /// Read-only view of the current buffer, oldest-first.
  List<MapBreadcrumb> get entries => List.unmodifiable(_entries);

  /// Records a breadcrumb. When the buffer is full (length ==
  /// [maxEntries]) the oldest entry is dropped before appending the
  /// new one.
  void record(String tag, String message) {
    if (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(MapBreadcrumb(
      at: DateTime.now(),
      tag: tag,
      message: message,
    ));
  }

  /// Empties the buffer.
  void clear() {
    _entries.clear();
  }
}
