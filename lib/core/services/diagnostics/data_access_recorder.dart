// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import '../service_result.dart';
import 'data_access_event.dart';
import 'data_access_trace.dart';

/// In-memory side-channel that accumulates every price/station data-layer
/// access (#2824) — the same spirit as `Obd2DebugSessionRecorder` and
/// `OcrTraceRecorder`.
///
/// Production threads `null` through the data layer (see
/// `dataAccessRecorderProvider`), so the chain is BYTE-FOR-BYTE unchanged and
/// costs nothing — the [recordDataAccess] free function null-guards before any
/// work. A dev session passes a real recorder; the instrumented chain feeds it
/// at each cache/network/stale outcome, and Developer tools reads back a
/// [build]-ed [DataAccessTrace] (then `formatDataAccessTraceJson`).
///
/// PURE Dart, no I/O — it only collects into a bounded ring buffer.
class DataAccessRecorder {
  /// Ring-buffer cap. Old events are evicted oldest-first past this so a long
  /// session can't grow the buffer without bound; 2000 covers a heavy session
  /// (a few hundred searches + favorites refreshes + a live trip) while
  /// staying tiny in memory.
  static const int maxEvents = 2000;

  final ListQueue<DataAccessEvent> _events = ListQueue<DataAccessEvent>();

  /// Monotonic clock — immune to wall-clock jumps (NTP/DST) so consecutive
  /// network-event intervals are always non-negative. Started at construction.
  final Stopwatch _clock = Stopwatch()..start();

  /// Configured min inter-request interval (seconds) per ISO country code,
  /// fed by [notePolicy] when each country's service is built.
  final Map<String, double> configuredMinIntervalSec = {};

  /// Current monotonic reading in microseconds, stamped onto each event.
  int get monotonicMicros => _clock.elapsedMicroseconds;

  /// The events recorded so far, oldest-first (unmodifiable view).
  List<DataAccessEvent> get events => List.unmodifiable(_events);

  /// Append [event], evicting the oldest once past [maxEvents].
  void add(DataAccessEvent event) {
    _events.addLast(event);
    while (_events.length > maxEvents) {
      _events.removeFirst();
    }
  }

  /// Record the configured rate-limit budget for [country]. A null
  /// [minInterval] (no policy) is ignored — the aggregate then reports
  /// `compliant: null` for that country.
  void notePolicy(String country, Duration? minInterval) {
    if (minInterval == null) return;
    configuredMinIntervalSec[country] = minInterval.inMicroseconds / 1e6;
  }

  /// Drop every recorded event + noted policy (e.g. when developer mode is
  /// turned off, or before capturing a fresh scenario).
  void clear() {
    _events.clear();
    configuredMinIntervalSec.clear();
  }

  /// Snapshot everything recorded so far into a serialise-ready trace.
  DataAccessTrace build({String? comment}) => DataAccessTrace(
        capturedAt: DateTime.now().toUtc(),
        events: List.unmodifiable(_events),
        configuredMinIntervalSec: Map.unmodifiable(configuredMinIntervalSec),
        comment: comment ?? kDataAccessCommentPrompt,
      );
}

/// Hot-path sink: appends one [DataAccessEvent] to [recorder], null-guarded so
/// the instrumented chain stays lean (in production `recorder` is null → an
/// early return, the chain's only added cost).
///
/// Keeping the construction here — not inline at each chain call site — means
/// the chain file only ever holds a single-line call per outcome, so the tap
/// doesn't push `station_service_chain.dart` toward the file-length cap.
void recordDataAccess(
  DataAccessRecorder? recorder,
  String country,
  DataAccessEndpoint endpoint,
  DataAccessHit hit,
  ServiceSource source, {
  int? count,
  int? latencyMicros,
  bool isStale = false,
}) {
  if (recorder == null) return;
  recorder.add(DataAccessEvent(
    at: DateTime.now(),
    monotonicMicros: recorder.monotonicMicros,
    country: country,
    source: source.name,
    endpoint: endpoint,
    hit: hit,
    resultCount: count,
    latencyMicros: latencyMicros,
    isStale: isStale,
  ));
}

/// `data.length` when [data] is a list (the row count to stamp on an event),
/// otherwise null. A free function so chain call sites read
/// `count: dataAccessResultCount(data)` without a local cast.
int? dataAccessResultCount(Object? data) => data is List ? data.length : null;
