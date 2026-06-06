// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'obd2_comm_diagnostics.dart' show redactObd2Mac;
import 'obd2_connect_trace.dart';
import 'obd2_connection_errors.dart';

/// In-memory ring of the last [maxTraces] connect ATTEMPTS (#2969).
///
/// This is the fix for the user's #1 OBD2 complaint: a FAILED connect must
/// leave a complete, downloadable trace. The comm-health session
/// ([Obd2CommDiagnostics]) only ever begins AFTER the channel opens, so a
/// scan-empty / wrong-transport / permission / BT-off / ignition-off failure
/// never reached it and `finishedSessions` stayed empty. This log sits ABOVE
/// the session: it is opened at the [Obd2ConnectionService] public-connect
/// entry points (the single virtual-dispatch chokepoint every live caller
/// funnels through), so a failure at ANY phase — including the phases before a
/// session could exist — is captured.
///
/// **WRITE ungated by debugMode (deliberate, #2969):** unlike the per-AT
/// transcript (which stays gated on `Obd2CommDiagnostics.enabled` for the
/// #2466 cost model), this ring is written even when developer mode is OFF, so
/// a real field failure is captured the first time it happens — the user does
/// NOT have to reproduce it with the flag on. The cost is bounded by
/// construction: a [maxTraces]-entry ring of small immutable records, no
/// network, no Hive (`hive_boxes.dart` is untouched). It is SURFACED only on
/// the `Feature.debugMode`-gated health screen.
///
/// **Single-isolate** like the rest of the OBD2 stack, so no synchronisation.
class Obd2ConnectTraceLog {
  Obd2ConnectTraceLog._();

  /// Hard cap on the retained connect-attempt ring. Older traces fall off the
  /// front when this is exceeded — the most recent attempts are the diagnostic
  /// value (a user debugging "it won't connect" cares about the last few
  /// tries).
  static const int maxTraces = 10;

  /// Hard cap on steps recorded per trace — bounds a pathological
  /// retry/fallback storm. Mirrors the #2969 design ("~64 steps").
  static const int maxStepsPerTrace = 64;

  /// Hard cap on scanned devices recorded per trace.
  static const int maxScannedPerTrace = 32;

  static final List<Obd2ConnectTrace> _ring = <Obd2ConnectTrace>[];

  /// Notify hook fired AFTER a trace is finalised into the ring (#2969). The
  /// `Obd2ConnectTraceRevision` provider registers it so the dev health screen
  /// rebuilds when a trace lands while it is open — including a LIVE reconnect
  /// failure the user never triggered from the screen. Null in production until
  /// the screen's provider registers it; best-effort + never throws.
  static void Function()? onTraceAdded;

  /// The trace currently being built, exposed so [Obd2CommDiagnostics] can tee
  /// each AT handshake line into it (#2969 correction 4 — the AT-transcript tee
  /// at the chokepoint) without instrumenting `obd2_service` directly. Null
  /// between attempts.
  static Obd2ConnectTraceHandle? _active;

  /// Injectable wall clock for deterministic tests. Production uses
  /// [DateTime.now]. Set via [debugSetClock]; reset to null restores it.
  static DateTime Function()? _clock;
  static DateTime _now() => (_clock ?? DateTime.now)();

  static int _seq = 0;

  /// A scoped origin override (#2969 correction 1). The self-test / a live
  /// reconnect runs its connect through the SAME public service methods as a
  /// first-connect, so the service cannot know who called it — it opens every
  /// trace with a default origin. A caller scopes the true origin around its
  /// connect with [runWithOrigin]; `beginTrace` consumes this override for the
  /// trace it opens.
  static Obd2ConnectOrigin? _originOverride;
  static String? _decisionReasonOverride;

  /// Run [body] with every trace opened inside it stamped [origin] (and, when
  /// given, [transportDecisionReason]). Restores the prior overrides in
  /// `finally` (nesting-safe). Used by the self-test so the health screen reads
  /// "self-test" instead of "first connect", and records WHY it chose a
  /// transport (`name-matched-classic` / `no-hint-defaulted-ble`) — visible,
  /// not silent.
  static Future<T> runWithOrigin<T>(
    Obd2ConnectOrigin origin,
    Future<T> Function() body, {
    String? transportDecisionReason,
  }) async {
    final priorOrigin = _originOverride;
    final priorReason = _decisionReasonOverride;
    _originOverride = origin;
    _decisionReasonOverride = transportDecisionReason;
    try {
      return await body();
    } finally {
      _originOverride = priorOrigin;
      _decisionReasonOverride = priorReason;
    }
  }

  /// Open a new connect-attempt trace. The returned handle is the mutable
  /// builder the connect path threads its steps/scan/outcome through; it
  /// becomes the [_active] trace so the handshake tee finds it. Re-entrant
  /// safe: a nested begin (a fallback re-entering a public connect method)
  /// returns a CHILD handle that records into the SAME live trace, so the AT
  /// transcript of a scan-fallback still lands in the one trace the user reads.
  static Obd2ConnectTraceHandle beginTrace({
    required Obd2ConnectOrigin origin,
    String? mac,
    Obd2ConnectTransport requestedTransport = Obd2ConnectTransport.unknown,
  }) {
    final existing = _active;
    if (existing != null) {
      // A nested connect (e.g. connectByMacDirect → scan fallback → connect)
      // records into the already-open trace so the whole attempt is ONE trace.
      return Obd2ConnectTraceHandle._child(existing);
    }
    final handle = Obd2ConnectTraceHandle._(
      attemptId: 't${_seq++}-${_now().microsecondsSinceEpoch}',
      // A scoped override (the self-test / live reconnect) wins over the
      // service's default origin, since the service can't know its caller.
      origin: _originOverride ?? origin,
      mac: mac,
      requestedTransport: requestedTransport,
      startedAt: _now(),
    );
    if (_decisionReasonOverride != null) {
      handle.setTransportDecisionReason(_decisionReasonOverride!);
    }
    _active = handle;
    return handle;
  }

  /// Tee one ELM init/handshake line into the active trace as a step (#2969
  /// correction 4). Called from [Obd2CommDiagnostics.recordHandshakeLine] so
  /// EVERY caller of that (including the failing init in `obd2_service`) tees
  /// without extra instrumentation. A no-op when no trace is active. This is
  /// the ONE write path that stays meaningful only while a connect is in
  /// flight, so the partial AT transcript of a failed init is preserved.
  static void teeHandshakeLine(String cmd, String rawResponse, int latencyMs) {
    final handle = _active;
    if (handle == null) return;
    handle.addStep(
      label: cmd.trim(),
      status: _statusForResponse(rawResponse),
      detail: rawResponse.trim(),
      latencyMs: latencyMs,
    );
  }

  static Obd2ConnectStepStatus _statusForResponse(String raw) {
    final u = raw.toUpperCase();
    if (u.contains('TIMEOUT')) return Obd2ConnectStepStatus.timeout;
    if (u.contains('NO DATA') ||
        u.contains('UNABLE') ||
        u.contains('STOPPED') ||
        u.contains('?')) {
      return Obd2ConnectStepStatus.fail;
    }
    return Obd2ConnectStepStatus.ok;
  }

  /// Finalise [handle] into the ring (stamping `endedAt`/`totalMs`) and clear
  /// the active pointer. A child handle is a no-op (the parent owns the
  /// lifecycle). Idempotent. Never throws — it is called from connect `finally`
  /// blocks on the critical path (#1103).
  static void endTrace(Obd2ConnectTraceHandle handle) {
    try {
      if (handle._isChild || handle._ended) return;
      handle._ended = true;
      final end = _now();
      final finished = handle._snapshot(end);
      _ring.add(finished);
      while (_ring.length > maxTraces) {
        _ring.removeAt(0);
      }
      if (identical(_active, handle)) _active = null;
      // Notify the dev health screen (best-effort; a throwing listener must
      // never derail a connect's finally block).
      try {
        onTraceAdded?.call();
      } catch (_) {}
    } catch (_) {
      // Never let trace bookkeeping derail a connect's finally block.
      if (identical(_active, handle)) _active = null;
    }
  }

  /// The trace currently being built, or null between attempts. Lets a caller
  /// that does NOT own the begin/end lifecycle (the self-test, which runs over
  /// the service's already-opened trace) stamp the origin via
  /// [Obd2ConnectTraceHandle.setOrigin] (#2969 correction 1 — runObd2SelfTest
  /// just stamps `origin:selfTest` on the trace the service already opened).
  static Obd2ConnectTraceHandle? get active => _active;

  /// Read-only snapshot, newest-first, for the health screen.
  static List<Obd2ConnectTrace> snapshot() =>
      List.unmodifiable(_ring.reversed.toList());

  /// Test reset — drops every trace + the active handle + the seq counter.
  /// Leaves [onTraceAdded] registered (the provider owns its lifecycle); tests
  /// that need it cleared null it explicitly.
  static void clear() {
    _ring.clear();
    _active = null;
    _originOverride = null;
    _seq = 0;
  }

  /// Test seam — inject a deterministic clock. Pass null to restore
  /// [DateTime.now].
  static void debugSetClock(DateTime Function()? clock) => _clock = clock;
}

/// Mutable builder for one in-flight [Obd2ConnectTrace] (#2969). Handed back by
/// [Obd2ConnectTraceLog.beginTrace]; the connect path records steps / scanned
/// devices / the terminal outcome onto it, then [Obd2ConnectTraceLog.endTrace]
/// finalises it into the ring.
///
/// A CHILD handle (from a nested begin) forwards every record onto its parent
/// so a fallback's steps land in the one trace, but its own end is a no-op.
class Obd2ConnectTraceHandle {
  Obd2ConnectTraceHandle._({
    required this.attemptId,
    required this.origin,
    required String? mac,
    required this.requestedTransport,
    required this.startedAt,
  })  : _parent = null,
        requestedMac = redactObd2Mac(mac);

  Obd2ConnectTraceHandle._child(Obd2ConnectTraceHandle parent)
      : _parent = parent,
        attemptId = parent.attemptId,
        origin = parent.origin,
        requestedMac = parent.requestedMac,
        requestedTransport = parent.requestedTransport,
        startedAt = parent.startedAt;

  final Obd2ConnectTraceHandle? _parent;
  bool get _isChild => _parent != null;

  final String attemptId;
  Obd2ConnectOrigin origin;
  final String? requestedMac;
  final Obd2ConnectTransport requestedTransport;
  final DateTime startedAt;

  Obd2ConnectTransport? _resolvedTransport;
  String? _transportDecisionReason;
  Obd2ConnectOutcome? _outcome;
  String? _failureDetail;
  bool _ended = false;

  final List<Obd2ConnectStep> _steps = <Obd2ConnectStep>[];
  final List<Obd2ScannedDevice> _scanned = <Obd2ScannedDevice>[];

  Obd2ConnectTraceHandle get _root => _parent?._root ?? this;

  /// Append one step. [latencyMs] is folded into startMs/endMs relative to the
  /// trace start. Capped at [Obd2ConnectTraceLog.maxStepsPerTrace].
  void addStep({
    required String label,
    required Obd2ConnectStepStatus status,
    String? detail,
    int? latencyMs,
  }) {
    final root = _root;
    if (root._steps.length >= Obd2ConnectTraceLog.maxStepsPerTrace) return;
    final endMs = DateTime.now().difference(root.startedAt).inMilliseconds;
    final startMs = latencyMs != null ? (endMs - latencyMs) : null;
    root._steps.add(Obd2ConnectStep(
      label: label,
      status: status,
      startMs: startMs != null && startMs >= 0 ? startMs : null,
      endMs: endMs >= 0 ? endMs : null,
      detail: detail,
    ));
  }

  /// Record one scanned device. Capped at
  /// [Obd2ConnectTraceLog.maxScannedPerTrace]. The MAC is redacted.
  void recordScan({
    String? mac,
    String? name,
    int? rssi,
    required Obd2ConnectTransport transport,
    String? matchedProfileId,
  }) {
    final root = _root;
    if (root._scanned.length >= Obd2ConnectTraceLog.maxScannedPerTrace) return;
    root._scanned.add(Obd2ScannedDevice(
      redactedMac: redactObd2Mac(mac),
      name: name,
      rssi: rssi,
      transport: transport,
      matchedProfileId: matchedProfileId,
    ));
  }

  /// Re-stamp the origin (#2969 correction 1). The service opens every trace
  /// with a default origin (it cannot know the caller); the self-test / a live
  /// reconnect overrides it via the [Obd2ConnectTraceLog.active] handle so the
  /// health screen reads "self-test" vs "live reconnect" correctly.
  void setOrigin(Obd2ConnectOrigin value) => _root.origin = value;

  /// Stamp which transport was actually used. Last write wins (the final
  /// dispatched transport is what matters).
  void setResolvedTransport(Obd2ConnectTransport transport) =>
      _root._resolvedTransport = transport;

  /// Stamp WHY a transport was chosen — visible, not silent. E.g.
  /// `'name-matched-classic'` / `'no-hint-defaulted-ble'`.
  void setTransportDecisionReason(String reason) =>
      _root._transportDecisionReason = reason;

  /// Stamp the terminal [outcome] — FIRST-TERMINAL-WINS (#2969 correction 3).
  /// A second call (a fallback's own outcome) is IGNORED for the primary
  /// outcome; record fallback progress via [addStep] instead. This is
  /// load-bearing: `_connectByMacDirect` swallows the BLE 4 s timeout and
  /// silently re-runs `scan()`, so without first-wins the real wrong-transport
  /// `gattTimeout` would be overwritten by the fallback's `scanEmpty`.
  void setOutcome(Obd2ConnectOutcome outcome, {String? failureDetail}) {
    final root = _root;
    if (root._outcome != null) return;
    root._outcome = outcome;
    root._failureDetail = failureDetail;
  }

  /// Convenience: classify [error] via [classifyObd2ConnectError] and stamp it
  /// (first-wins), carrying the raw `toString()` as the failure detail.
  void setOutcomeFromError(Object error) => setOutcome(
        classifyObd2ConnectError(error),
        failureDetail: error.toString(),
      );

  /// Whether a terminal outcome has been stamped (success or any failure).
  bool get hasOutcome => _root._outcome != null;

  /// Classify an INIT failure (the channel opened, the ELM handshake failed)
  /// from the AT steps teed so far (#2969 correction 4): distinguish a
  /// counterfeit clone (ATZ returned garbage/`?`) from an init timeout (any AT
  /// step timed out) from a silent ECU / ignition-off (the init structurally
  /// ran but the first PID probe found NO DATA). Used by `_openAndInit` where
  /// `Obd2Service.connect` already swallowed the real error into a generic
  /// `false`, so the teed transcript is the only signal left.
  Obd2ConnectOutcome classifyInitFailureOutcome() {
    final steps = _root._steps;
    for (final s in steps) {
      final label = s.label.toUpperCase();
      // ATZ garbage / unrecognised → a lying clone (protocol init failed).
      if (label == 'ATZ' && s.status == Obd2ConnectStepStatus.fail) {
        final d = (s.detail ?? '').toUpperCase();
        if (d.contains('?') || (d.isNotEmpty && !d.contains('ELM'))) {
          return Obd2ConnectOutcome.protocolInitFailed;
        }
      }
    }
    if (steps.any((s) => s.status == Obd2ConnectStepStatus.timeout)) {
      return Obd2ConnectOutcome.initTimeout;
    }
    // The init ran but the first PID/probe was silent → ignition off / parked.
    return Obd2ConnectOutcome.ignitionOff;
  }

  Obd2ConnectTrace _snapshot(DateTime end) => Obd2ConnectTrace(
        attemptId: attemptId,
        startedAtMs: startedAt.millisecondsSinceEpoch,
        endedAtMs: end.millisecondsSinceEpoch,
        totalMs: end.difference(startedAt).inMilliseconds,
        origin: origin,
        requestedMac: requestedMac,
        requestedTransport: requestedTransport,
        resolvedTransport: _resolvedTransport,
        transportDecisionReason: _transportDecisionReason,
        outcome: _outcome,
        failureDetail: _failureDetail,
        steps: List.unmodifiable(_steps),
        scanned: List.unmodifiable(_scanned),
      );
}

/// Central classifier (#2969 correction 2) mapping any thrown connect error
/// onto an [Obd2ConnectOutcome]. Covers the sealed [Obd2ConnectionError] set +
/// a raw [TimeoutException]; everything else degrades to
/// [Obd2ConnectOutcome.unknown] (the raw `toString()` is kept as failureDetail
/// for triage).
///
/// CALLED in every self-test driver catch arm AND `connectBest()`'s catch, so
/// the permission / BT-off / scan-timeout family — which throw BEFORE
/// `registry.rank()` runs, so `recordScan` never sees them — still produce the
/// right outcome.
Obd2ConnectOutcome classifyObd2ConnectError(Object error) {
  if (error is Obd2PermissionDenied) return Obd2ConnectOutcome.permissionDenied;
  if (error is Obd2BluetoothOff) return Obd2ConnectOutcome.bluetoothOff;
  if (error is Obd2ScanTimeout) return Obd2ConnectOutcome.scanEmpty;
  if (error is Obd2ProtocolInitFailed) {
    return Obd2ConnectOutcome.protocolInitFailed;
  }
  // Obd2AdapterUnresponsive covers BOTH a Classic rfcomm-open `false` (the
  // channel never opened) and a post-open silent-bus probe. The channel layers
  // raise it for the rfcomm-open-fail case with a distinct message; default it
  // to ignitionOff (the #1 real condition — a parked car) so the actionable
  // "turn the ignition on" guidance is the headline, and let a more specific
  // step/outcome stamped earlier (first-wins) override when the channel-open
  // classifier already ran.
  if (error is Obd2AdapterUnresponsive) {
    final msg = error.message.toUpperCase();
    if (msg.contains('CLASSIC') || msg.contains('RFCOMM')) {
      return Obd2ConnectOutcome.rfcommOpenFail;
    }
    return Obd2ConnectOutcome.ignitionOff;
  }
  if (error is Obd2DisconnectedException) return Obd2ConnectOutcome.unknown;
  if (error is TimeoutException) return Obd2ConnectOutcome.initTimeout;
  return Obd2ConnectOutcome.unknown;
}

/// Classify a BLE `channel.open()` failure (#2969 correction 3) onto an
/// [Obd2ConnectOutcome]. Distinct from [classifyObd2ConnectError] because a
/// raw BLE open failure is NOT an [Obd2ConnectionError] — it is an FBP
/// exception / StateError. Recorded INSIDE the channel-open catch BEFORE the
/// scan fallback re-runs, so the real wrong-transport timeout wins (first-wins)
/// over the fallback's scanEmpty.
Obd2ConnectOutcome classifyBleOpenOutcome(Object error) {
  final msg = error.toString().toUpperCase();
  if (msg.contains('133') || msg.contains('GATT_ERROR')) {
    return Obd2ConnectOutcome.gatt133;
  }
  if (msg.contains('TIMED OUT') ||
      msg.contains('TIMEOUT') ||
      error is TimeoutException) {
    return Obd2ConnectOutcome.gattTimeout;
  }
  if (error is StateError &&
      (msg.contains('ELM327 SERVICE') ||
          msg.contains('WRITE CHARACTERISTIC') ||
          msg.contains('NOTIFY CHARACTERISTIC'))) {
    return Obd2ConnectOutcome.serviceNotFound;
  }
  return Obd2ConnectOutcome.unknown;
}
