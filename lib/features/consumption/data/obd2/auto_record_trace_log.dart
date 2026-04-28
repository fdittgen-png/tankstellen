import 'package:flutter/foundation.dart';

import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';

/// Kinds of state transitions the auto-record flow goes through. Used
/// by [AutoRecordTraceLog] so the user (and a future debug screen) can
/// answer "did anything happen at all?" — a question that
/// `errorLogger.log` cannot answer because no exception was thrown on
/// the silent-failure path. See #1004 phase 2a-trace.
enum AutoRecordEventKind {
  /// Coordinator's [start] entered — bridge armed, waiting for the
  /// adapter to come into range.
  coordinatorStarted,

  /// Coordinator's [stop] entered — every subscription torn down.
  coordinatorStopped,

  /// `AdapterConnected` event observed for the configured MAC.
  adapterConnected,

  /// `AdapterConnected` event observed for a foreign MAC; the
  /// coordinator dropped it because of the MAC filter (multi-vehicle
  /// case).
  adapterConnectIgnoredOtherMac,

  /// `AdapterDisconnected` event observed for the configured MAC.
  adapterDisconnected,

  /// `AdapterDisconnected` event for a foreign MAC; dropped.
  adapterDisconnectIgnoredOtherMac,

  /// A speed sample crossed above the movement threshold; the
  /// consecutive-window counter just incremented.
  speedSampleSupraThreshold,

  /// A speed sample landed at or below the movement threshold; the
  /// counter was reset.
  speedSampleSubThreshold,

  /// The Nth consecutive supra-threshold sample arrived (N =
  /// `consecutiveSamplesWindow`) — `startTrip()` is about to be
  /// called.
  thresholdCrossed,

  /// `startTrip()` returned a successful outcome and a trip is now
  /// active.
  tripStarted,

  /// `startTrip()` returned an outcome other than `started` (e.g.
  /// `alreadyActive`, `noActiveProfile`). Detail carries the outcome.
  tripStartFailed,

  /// Disconnect debounce timer was scheduled — waiting for either
  /// reconnect (cancel) or fire (save).
  disconnectTimerStarted,

  /// Reconnect within the debounce window cancelled the pending save
  /// timer; the trip carries on.
  disconnectTimerCancelled,

  /// Disconnect debounce timer fired — about to call
  /// `stopAndSaveAutomatic`.
  disconnectTimerFired,

  /// `stopAndSaveAutomatic()` completed; the trip is in history.
  tripSavedAuto,

  /// `stopAndSaveAutomatic()` threw. Detail carries the exception
  /// message.
  tripSaveFailed,

  /// `Obd2SessionOpener` returned null or threw on `AdapterConnected`
  /// (#1004 phase 2b-3). The coordinator stays idle for this connect
  /// cycle and waits for the next event.
  sessionOpenFailed,

  /// On threshold-cross, the coordinator passed ownership of its open
  /// [Obd2Service] to `TripRecording.start(service)` (#1004 phase
  /// 2b-3). After this entry the recorder owns the OBD2 session and
  /// the coordinator no longer polls speed for the active trip.
  sessionHandedOff,

  /// `Obd2Service.readSpeedKmh()` returned null repeatedly while the
  /// OBD2 speed stream was polling (#1004 phase 2b-3). Logged once per
  /// N consecutive failures so the user can tell a flaky link from
  /// "engine off" silence. Detail carries the consecutive-failure
  /// count.
  obd2SpeedReadFailed,

  /// Generic catch — detail carries a free-form message. Used
  /// sparingly so the enum stays the contract.
  error,
}

/// One entry in the auto-record event ring. Immutable so a snapshot
/// can be safely handed to debug UI / log export without risking
/// concurrent mutation.
@immutable
class AutoRecordEvent {
  /// Wall-clock instant the event was recorded. Defaults to
  /// `DateTime.now()` in production; tests inject a fixed clock via
  /// [AutoRecordTraceLog.add]'s `clock` parameter.
  final DateTime timestamp;

  /// Which transition this entry captures.
  final AutoRecordEventKind kind;

  /// MAC of the adapter the transition refers to, when relevant
  /// (connect / disconnect events; the coordinator-lifecycle events
  /// leave it null).
  final String? mac;

  /// Free-form context — e.g. "speed=12.3 kmh, count=2/3" for a
  /// supra-threshold sample, "delaySec=60" for a timer start. Kept as
  /// a string so the ring stays cheap to format and serialise.
  final String? detail;

  const AutoRecordEvent({
    required this.timestamp,
    required this.kind,
    this.mac,
    this.detail,
  });
}

/// In-memory ring buffer of auto-record state transitions, so the
/// user can answer "did anything happen at all?" without an error
/// to attach to. Mirrors every entry to [BreadcrumbCollector] so
/// the error-trace pipeline still sees the last 25 events when
/// something does crash.
///
/// **Persistence:** in-memory only for phase 2a-trace. A future phase
/// can add Hive backing (note that `hive_boxes.dart` is hot-file —
/// don't touch it casually).
///
/// **Capacity:** 100 events. Older entries drop off the front when
/// the ring fills. The user's typical debugging window is "one
/// driving session," well under 100 transitions.
///
/// **Thread-safety:** the ring is a static `List`. The auto-record
/// flow is single-isolate (Dart side of the foreground service +
/// main isolate), so no synchronisation is needed; if a future phase
/// promotes this to a cross-isolate data structure it should switch
/// to `IsolateNameServer`-mediated access (same pattern as
/// `IsolateErrorSpool`).
class AutoRecordTraceLog {
  /// Maximum number of events kept in the ring. Older entries fall
  /// off the front when this is exceeded.
  static const int maxEvents = 100;

  static final List<AutoRecordEvent> _ring = <AutoRecordEvent>[];

  /// Records [kind] with optional [mac] and [detail] context. Mirrors
  /// to `BreadcrumbCollector.add(...)` so the error-trace pipeline
  /// also captures the event when something later crashes.
  ///
  /// Test seam: pass a [clock] to control the timestamp; production
  /// code leaves it null and the wall clock is used.
  static void add(
    AutoRecordEventKind kind, {
    String? mac,
    String? detail,
    DateTime Function()? clock,
  }) {
    final DateTime ts = clock != null ? clock() : DateTime.now();
    _ring.add(AutoRecordEvent(
      timestamp: ts,
      kind: kind,
      mac: mac,
      detail: detail,
    ));
    while (_ring.length > maxEvents) {
      _ring.removeAt(0);
    }
    final List<String> parts = <String>[
      if (mac != null) 'mac=$mac',
      ?detail,
    ];
    BreadcrumbCollector.add(
      'auto_record:${kind.name}',
      detail: parts.isEmpty ? null : parts.join(' '),
    );
  }

  /// Read-only snapshot for debug screens / future log export.
  static List<AutoRecordEvent> snapshot() => List.unmodifiable(_ring);

  /// Test reset — drops every entry. Production callers should not
  /// invoke this; the ring is meant to survive across tear-downs so
  /// post-mortem inspection is possible after the user stops the
  /// flow.
  @visibleForTesting
  static void clear() => _ring.clear();
}
