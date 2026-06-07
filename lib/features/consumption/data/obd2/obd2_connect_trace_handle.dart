// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connect_trace_log.dart';

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
    required String? adapterName,
    required this.requestedTransport,
    required this.startedAt,
  })  : _parent = null,
        requestedMac = redactObd2Mac(mac),
        _adapterName = adapterName;

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

  /// #3014 — the human adapter NAME for the trace headline. Mutable so the
  /// chokepoint (which knows the paired name) can stamp it onto a trace the
  /// service opened first, and a scan resolution can fill it in for a cold
  /// connect. Not on the child (a child forwards to [_root]).
  String? _adapterName;

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

  /// #3014 — stamp the human adapter NAME (the trace headline). Only fills an
  /// EMPTY slot so the authoritative name set at the chokepoint (the paired
  /// adapter name) is never clobbered by a later, weaker source (a cold scan's
  /// advertised name). A no-op for an empty value.
  void setAdapterName(String? name) {
    if (name == null || name.isEmpty) return;
    final root = _root;
    if (root._adapterName != null && root._adapterName!.isNotEmpty) return;
    root._adapterName = name;
  }

  /// The current adapter name on the root, for a caller that wants to render or
  /// log it before the trace finalises.
  String? get adapterName => _root._adapterName;

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
        adapterName: _adapterName,
        requestedTransport: requestedTransport,
        resolvedTransport: _resolvedTransport,
        transportDecisionReason: _transportDecisionReason,
        outcome: _outcome,
        failureDetail: _failureDetail,
        steps: List.unmodifiable(_steps),
        scanned: List.unmodifiable(_scanned),
      );
}
