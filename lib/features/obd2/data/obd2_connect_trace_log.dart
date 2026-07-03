// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show debugPrint;

import 'obd2_comm_diagnostics.dart' show redactObd2Mac;
import 'obd2_connect_classifier.dart';
import 'obd2_connect_trace.dart';

// #3014 — the mutable per-attempt builder lives in a `part` so this file stays
// under the #1680/#2351 400-line cap (the obd2_connect_by_mac.dart precedent),
// while keeping cross-class private-member access (`handle._isChild`,
// `handle._snapshot`, etc.).
part 'obd2_connect_trace_handle.dart';

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

  /// #3184 — persistence hook fired with each FINALISED trace.
  /// `Obd2ConnectTracePersistence.init()` registers it at startup so the
  /// ring survives an app kill (the in-memory-only ring lost every trace
  /// the moment the user relaunched to report the failure). Best-effort +
  /// never throws; null until the persistence layer initialises.
  static void Function(Obd2ConnectTrace trace)? onTracePersist;

  /// #3185 — one-shot supervisor-admission note, set by
  /// [Obd2ConnectSupervisor] when a connect requester had to WAIT for the
  /// single-flight slot (or preempted a passive holder), consumed by the
  /// next ROOT [beginTrace] into a `supervisor-admission` step. Admission
  /// necessarily happens BEFORE the attempt opens its trace (a trace opened
  /// while the holder's is live would merge into it as a child), so the
  /// hand-over is this one-shot note rather than a direct addStep.
  static String? pendingAdmissionNote;

  /// #3184(d) — adapter-radio-state probe, registered by the plugin-wiring
  /// layer (`obd2Connection` provider: `FlutterBluePlus.adapterStateNow`).
  /// When set, every ROOT trace opens with an `adapter-state` step 0 — the
  /// single most common "why did nothing happen" answer (radio off /
  /// still `unknown` on a cold iOS launch, #3182). Kept as a seam so this
  /// file stays platform-free and tests inject a fake.
  static String Function()? adapterStateProbe;

  /// #3184 — hydrate the in-memory ring from persisted traces at startup
  /// (oldest-first; trimmed to [maxTraces]). Called once by
  /// `Obd2ConnectTracePersistence.init()` before any live connect runs.
  static void hydrateFromPersisted(List<Obd2ConnectTrace> traces) {
    if (traces.isEmpty) return;
    final sorted = [...traces]
      ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));
    _ring.addAll(sorted);
    while (_ring.length > maxTraces) {
      _ring.removeAt(0);
    }
  }

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
    String? adapterName,
    Obd2ConnectTransport requestedTransport = Obd2ConnectTransport.unknown,
  }) {
    final existing = _active;
    if (existing != null) {
      if (existing.origin == Obd2ConnectOrigin.pickerScan) {
        // #3184(f) — a live PICKER-SCAN trace never absorbs what follows:
        // the user picking a candidate (or any entry point starting while
        // the ambient scan stream is still open) deserves its OWN root
        // trace. The scan is finalised HERE — as success when nothing
        // failed earlier (the user picked FROM its results) — because the
        // picker's stream cancel is fire-and-forget and the scan
        // generator's own `finally` may only run after this new attempt
        // has already begun. Success only when the scan actually surfaced
        // candidates; #3247 — a superseded EMPTY scan finalises as
        // `scanEmpty` (it used to land outcome-less in the persisted ring).
        if (!existing.hasOutcome) {
          existing.setOutcome(existing.hasScannedDevices
              ? Obd2ConnectOutcome.success
              : Obd2ConnectOutcome.scanEmpty);
        }
        endTrace(existing);
      } else if (existing.isSuperseded) {
        // #3244 — the live trace belongs to a PREEMPTED passive attempt
        // (markSuperseded already stamped its step + outcome): finalise it
        // so THIS attempt opens its own ROOT. Child-joining the zombie left
        // the active requester with no persisted root at all.
        endTrace(existing);
      } else {
        // A nested connect (e.g. connectByMacDirect → scan fallback →
        // connect) records into the already-open trace so the whole
        // attempt is ONE trace. #3014 — a child can still carry the NAME
        // up to the root when the outer begin had none (the by-MAC
        // chokepoint knows the paired name; the inner scan fallback
        // re-enters with the same name), so the headline is filled.
        if (adapterName != null && adapterName.isNotEmpty) {
          existing.setAdapterName(adapterName);
        }
        return Obd2ConnectTraceHandle._child(existing);
      }
    }
    final handle = Obd2ConnectTraceHandle._(
      attemptId: 't${_seq++}-${_now().microsecondsSinceEpoch}',
      // A scoped override (the self-test / live reconnect) wins over the
      // service's default origin, since the service can't know its caller.
      origin: _originOverride ?? origin,
      mac: mac,
      adapterName: adapterName,
      requestedTransport: requestedTransport,
      startedAt: _now(),
    );
    if (_decisionReasonOverride != null) {
      handle.setTransportDecisionReason(_decisionReasonOverride!);
    }
    _active = handle;
    // #3185 — surface the supervisor-admission wait (if any) as an early
    // step of the attempt it delayed, so a field export explains the gap.
    final admissionNote = pendingAdmissionNote;
    pendingAdmissionNote = null;
    if (admissionNote != null) {
      handle.addStep(
        label: 'supervisor-admission',
        status: Obd2ConnectStepStatus.ok,
        detail: admissionNote,
      );
    }
    // #3184(d) — step 0 of every ROOT trace: the adapter radio state at
    // the moment the scan/connect began. Best-effort; a throwing probe
    // must never derail the connect that follows (#1103).
    final probe = adapterStateProbe;
    if (probe != null) {
      try {
        handle.addStep(
          label: 'adapter-state',
          status: Obd2ConnectStepStatus.ok,
          detail: probe(),
        );
      } catch (e, st) {
        debugPrint(
            'Obd2ConnectTraceLog: adapterStateProbe threw (ignored): $e\n$st');
      }
    }
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
      // #3184 — persist the finalised trace (best-effort, fire-and-forget;
      // the persistence layer owns its own error handling). UNGATED by
      // debugMode, like the ring itself: a real field failure must survive
      // the app kill that precedes "let me export the error log".
      try {
        onTracePersist?.call(finished);
      } catch (e, st) {
        debugPrint('Obd2ConnectTraceLog: onTracePersist hook threw '
            '(ignored): $e\n$st');
      }
      // Notify the dev health screen (best-effort; a throwing listener must
      // never derail a connect's finally block).
      try {
        onTraceAdded?.call();
      } catch (e, st) {
        debugPrint('Obd2ConnectTraceLog: onTraceAdded listener threw '
            '(ignored): $e\n$st');
      }
    } catch (e, st) {
      // Never let trace bookkeeping derail a connect's finally block (#1103).
      if (identical(_active, handle)) _active = null;
      debugPrint('Obd2ConnectTraceLog.endTrace failed (ignored): $e\n$st');
    }
  }

  /// The trace currently being built, or null between attempts. Lets a caller
  /// that does NOT own the begin/end lifecycle (the self-test, which runs over
  /// the service's already-opened trace) stamp the origin via
  /// [Obd2ConnectTraceHandle.setOrigin] (#2969 correction 1 — runObd2SelfTest
  /// just stamps `origin:selfTest` on the trace the service already opened).
  static Obd2ConnectTraceHandle? get active => _active;

  /// Stamp a channel-open failure (#2969) onto the active trace as ONE step +
  /// the FIRST-wins terminal outcome, carrying [detail]. The shared one-liner
  /// the BLE + Classic channel-open catches call where the REAL error is in
  /// hand (Obd2Service.connect swallows it into a generic false return). A
  /// no-op when no trace is active.
  static void stampOpenFailure(Obd2ConnectOutcome outcome, String detail) {
    active
      ?..addStep(
        label: 'channel-open',
        status: Obd2ConnectStepStatus.fail,
        detail: detail,
      )
      ..setOutcome(outcome, failureDetail: detail);
  }

  /// Read-only snapshot, newest-first, for the health screen.
  static List<Obd2ConnectTrace> snapshot() =>
      List.unmodifiable(_ring.reversed.toList());

  /// Test reset — drops every trace + the active handle + the seq counter
  /// + the #3184 probe/persist hooks. Leaves [onTraceAdded] registered
  /// (the provider owns its lifecycle); tests that need it cleared null it
  /// explicitly.
  static void clear() {
    _ring.clear();
    _active = null;
    _originOverride = null;
    _seq = 0;
    adapterStateProbe = null;
    onTracePersist = null;
    pendingAdmissionNote = null;
  }

  /// Test seam — inject a deterministic clock. Pass null to restore
  /// [DateTime.now].
  static void debugSetClock(DateTime Function()? clock) => _clock = clock;
}
