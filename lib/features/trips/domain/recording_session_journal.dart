// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entities/recording_session_event.dart';

/// The ONE correlated lifecycle timeline of a recording session
/// (#3797, Epic #3794).
///
/// ## Why this exists
///
/// Diagnosing the 2026-08-25 field failures needed four separate
/// exports plus the source code, because every fact lived somewhere
/// else: dial outcomes in the connect traces, ELM stats in the
/// comm-diagnostics session (overwritten on the next connect), drop
/// reasons in an in-memory auto-record ring with no export at all, and
/// the trip's own outcome in the driving analysis — with nothing joining
/// them. This journal is the join: one bounded, ordered, trip-scoped
/// list that answers the three questions a field report actually raises.
///
///   * **OBD2 never delivered** — the timeline shows whether the link
///     ever reached `ready`, whether a protocol was established, and
///     what the verdict was.
///   * **OBD2 delivered then stopped** — the drop, its reason, and every
///     recovery attempt that followed, in order.
///   * **The session quit or crashed** — the terminal `ended` event
///     names the [TripTerminationReason]; its absence is itself the
///     signal that the process died mid-recording (#3796 then labels it
///     from the OS exit record).
///
/// ## Always on, by design
///
/// Unlike `Obd2CommDiagnostics` (gated on `Feature.debugMode`, and reset
/// the moment the flag is turned off), this journal is ungated — the
/// same rationale `Obd2ConnectTraceLog` documents: a diagnostic that is
/// switched off when the failure happens is worthless, and the field
/// reports we get are from ordinary testers who never enabled debug
/// mode. The cost is bounded by construction: at most [maxEvents]
/// entries of three small fields, recorded only on state TRANSITIONS
/// (never per PID tick or per sample), so a healthy hour-long drive
/// writes a handful of rows.
class RecordingSessionJournal {
  /// Ring capacity. Sized for a pathological drive — the 2026-08-25
  /// dial-storm trip would have produced ~45 entries in 6 minutes — while
  /// staying negligible in the persisted trip row. When it overflows the
  /// OLDEST entries are dropped but the count keeps rising, and
  /// [droppedEvents] reports the loss so a truncated timeline is never
  /// mistaken for a quiet one.
  static const int maxEvents = 60;

  RecordingSessionJournal({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<RecordingSessionEvent> _events = <RecordingSessionEvent>[];

  DateTime? _startedAt;
  int _dropped = 0;

  /// The recorded timeline, oldest first.
  List<RecordingSessionEvent> get events =>
      List<RecordingSessionEvent>.unmodifiable(_events);

  /// How many events the ring evicted (0 in the normal case).
  int get droppedEvents => _dropped;

  /// True once [start] has anchored the timeline.
  bool get isStarted => _startedAt != null;

  /// Anchor t = 0 and record the opening event. Idempotent: a second
  /// call is ignored so a re-entrant start can't reset the clock.
  void start({DateTime? at, String? detail}) {
    if (_startedAt != null) return;
    _startedAt = at ?? _now();
    _append(RecordingSessionEventKind.started, detail);
  }

  /// Record [kind] at the current offset. A no-op before [start] — an
  /// event with no anchor has no meaning, and silently dropping it beats
  /// stamping a misleading t=0.
  void add(RecordingSessionEventKind kind, {String? detail}) {
    if (_startedAt == null) return;
    _append(kind, detail);
  }

  /// Collapse a repeat: record [kind] only when it differs from the last
  /// recorded event's kind+detail. Used by the link-state bridge, where
  /// the supervisor can republish the same state repeatedly and would
  /// otherwise flood the ring and evict the interesting history.
  void addDistinct(RecordingSessionEventKind kind, {String? detail}) {
    if (_startedAt == null) return;
    if (_events.isNotEmpty) {
      final last = _events.last;
      if (last.kind == kind && last.detail == detail) return;
    }
    _append(kind, detail);
  }

  void _append(RecordingSessionEventKind kind, String? detail) {
    final started = _startedAt;
    if (started == null) return;
    final delta = _now().difference(started).inMilliseconds;
    _events.add(RecordingSessionEvent(
      kind: kind,
      tMs: delta < 0 ? 0 : delta,
      detail: detail,
    ));
    while (_events.length > maxEvents) {
      _events.removeAt(0);
      _dropped++;
    }
  }

  /// Compact JSON for the trip row + the exports. `ev` is the timeline,
  /// `dr` the eviction count (omitted when nothing was dropped).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ev': _events.map((e) => e.toJson()).toList(growable: false),
        if (_dropped > 0) 'dr': _dropped,
      };

  /// Rehydrate a persisted timeline (read-only use: the clock anchor is
  /// not restored, so a decoded journal must not be appended to).
  static RecordingSessionJournal fromJson(Map<String, dynamic> json) {
    final j = RecordingSessionJournal();
    final raw = json['ev'] as List?;
    if (raw != null) {
      for (final e in raw) {
        j._events.add(
          RecordingSessionEvent.fromJson((e as Map).cast<String, dynamic>()),
        );
      }
    }
    j._dropped = (json['dr'] as num?)?.toInt() ?? 0;
    return j;
  }
}
