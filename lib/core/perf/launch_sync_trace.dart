// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../sync/sync_run_trace.dart';
import 'startup_timer.dart';

/// #3445 — span recorder for the post-first-frame launch-sync phase.
///
/// `StartupTimer.finish()` fires at first frame, so the deferred TankSync
/// init + server→local merges were invisible to the #3383 startup trace.
/// When armed, this records [StartupSpan]s onto the SAME [StartupTimer]
/// (they ride the existing [StartupTraceExport] document, dev-tools panel
/// data and error-log export section — no parallel system), using the
/// timer's wall-clock epoch so recording keeps working after `finish()`.
///
/// Arming is the caller's decision — the app layer gates on the
/// `Feature.startupTrace` devtool flag (core must not import
/// feature_management). A `null` trace is the disabled path: every call
/// site goes through [spanned], which runs the body directly, so the
/// flag-off cost is a single null check. When sync is disabled the
/// launch-sync phase returns before any span begins, so nothing is
/// recorded there either.
///
/// While armed, the recorder also taps [SyncRunTrace.tableSink]: the
/// #3126 per-table counts reported by `EntitySync.merge` during an open
/// span land in that span's attributes as `pushed` / `pulled` rows.
/// #3450 made the launch pulls PARALLEL, so tapped counts can
/// misattribute across overlapping spans — every launch span therefore
/// passes explicit `attributes` (table + pulled), which override the
/// tapped values on key collision; the tap remains as best-effort colour.
/// [finish] restores the previous sink and closes the phase with a
/// `sync_phase_done` span covering the whole launch-sync window.
class LaunchSyncTrace {
  LaunchSyncTrace._(this._timer) : _phaseStartMs = _timer.elapsedMsNow() {
    _previousSink = SyncRunTrace.tableSink;
    SyncRunTrace.tableSink = _onTableCounts;
  }

  final StartupTimer _timer;
  final int _phaseStartMs;

  /// Attribute sink of the currently open [span], `null` between spans.
  Map<String, Object?>? _openSpanCounts;

  void Function(String, int, int, int)? _previousSink;

  /// Arm a recorder when [enabled], `null` otherwise (the zero-overhead
  /// disabled path). [timer] defaults to the app-wide singleton and is
  /// injectable for tests.
  static LaunchSyncTrace? maybeArm({
    required bool enabled,
    StartupTimer? timer,
  }) =>
      enabled ? LaunchSyncTrace._(timer ?? StartupTimer.instance) : null;

  /// Run [body] inside a span named [name] on [trace] — or run it
  /// directly when [trace] is `null` (disabled). This is the ONE call
  /// shape every launch-sync site uses, so the disabled path stays a
  /// single null check.
  static Future<T> spanned<T>(
    LaunchSyncTrace? trace,
    String name,
    Future<T> Function() body, {
    Map<String, Object?> Function()? attributes,
  }) =>
      trace == null ? body() : trace.span(name, body, attributes: attributes);

  /// Record [body] as a span named [name]. [attributes] is evaluated
  /// AFTER the body (so it can close over counters the body fills); its
  /// entries override any [SyncRunTrace]-tapped counts on key collision.
  /// The span is recorded even when the body throws — the launch-sync
  /// phase itself never lets exceptions escape, but the trace must not
  /// depend on that.
  Future<T> span<T>(
    String name,
    Future<T> Function() body, {
    Map<String, Object?> Function()? attributes,
  }) async {
    final startMs = _timer.elapsedMsNow();
    final counts = <String, Object?>{};
    _openSpanCounts = counts;
    try {
      return await body();
    } finally {
      _openSpanCounts = null;
      _timer.addSpan(
        name,
        startMs: startMs,
        endMs: _timer.elapsedMsNow(),
        attributes: {...counts, ...?attributes?.call()},
      );
    }
  }

  /// Close the phase: restore the previous [SyncRunTrace.tableSink] and
  /// record the `sync_phase_done` span spanning the entire launch-sync
  /// window (arm → finish). Idempotent enough for the single-shot launch
  /// flow; call exactly once per armed recorder.
  void finish() {
    SyncRunTrace.tableSink = _previousSink;
    _timer.addSpan(
      'sync_phase_done',
      startMs: _phaseStartMs,
      endMs: _timer.elapsedMsNow(),
    );
  }

  void _onTableCounts(String table, int uploaded, int downloaded, int tomb) {
    final c = _openSpanCounts;
    if (c == null) return;
    c['table'] = table;
    c['pushed'] = uploaded;
    c['pulled'] = downloaded;
  }
}
