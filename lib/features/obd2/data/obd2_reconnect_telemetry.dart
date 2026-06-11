// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'obd2_reconnect_telemetry.freezed.dart';
part 'obd2_reconnect_telemetry.g.dart';

/// Per-attempt + session-state-transition reconnect telemetry (#2905, head
/// of Epic #2904).
///
/// The aggregate `conn:{at,su,fr,dr,sr,vr,…}` block on
/// `Obd2SessionDiagnostic` could not diagnose a field reconnect failure: a
/// real 1024 s trip (adapter DC:0D:…:36:DA) recorded 0 successful
/// reconnects, ran entirely on GPS fallback, and captured no per-attempt
/// detail, no session-state transition, and no fallback marker. This pair
/// of immutable value types adds exactly that — a bounded timeline of
/// individual reconnect ATTEMPTS plus the connected→dropped→reconnecting→
/// reconnected/orphaned STATE transitions — so the next capture is precise.
///
/// Both types follow the diagnostics-value-type contract used across this
/// subsystem: immutable (freezed), structural `==`/`hashCode`, compact-JSON
/// round-trippable via short keys, and bounded by construction (the
/// collector caps the retained list).

/// One in-trip reconnect attempt: when it was tried, why the previous link
/// dropped / why this try failed, the scanner's current backoff, the
/// sighting RSSI (scan path only), the connect latency, the 1-based attempt
/// ordinal this drop episode, and whether it established a working link.
@freezed
abstract class Obd2ReconnectAttempt with _$Obd2ReconnectAttempt {
  const factory Obd2ReconnectAttempt({
    /// Epoch-millisecond wall clock when the attempt was made — the
    /// timeline anchor. 0 only for the const-default sentinel.
    @JsonKey(name: 't') @Default(0) int timestampMs,

    /// Low-cardinality failure reason tag for a FAILED attempt
    /// ([Obd2ReconnectReason] normalised): `'rfcomm-open-fail'` /
    /// `'gatt-133'` / `'device-not-connected'` / `'timeout'` / `'other'`.
    /// Null when [succeeded] is true (a success has no failure reason).
    @JsonKey(name: 'rc') String? reasonCode,

    /// The scanner's backoff (ms) in force for THIS cycle — how long the
    /// scanner waited before this attempt. 0 for the immediate first probe.
    @JsonKey(name: 'bo') @Default(0) int backoffMs,

    /// Sighting RSSI (dBm, negative) when this attempt came from the
    /// scan-fallback path. Null for the direct-connect / passive path,
    /// which never scans and so carries no RSSI.
    @JsonKey(name: 'r') int? rssi,

    /// Wall-clock latency (ms) the connect dance took this attempt
    /// (success or fail). 0 when not measured.
    @JsonKey(name: 'l') @Default(0) int latencyMs,

    /// 1-based attempt ordinal within this drop episode — attempt 1 is the
    /// fast first probe, then 2, 3, … as the backoff escalates.
    @JsonKey(name: 'n') @Default(0) int attemptNumber,

    /// True when this attempt established a working link. The single
    /// `succeeded: true` row per episode marks the recovery; everything
    /// before it failed.
    @JsonKey(name: 's') @Default(false) bool succeeded,

    /// `'direct'` / `'scan'` / `'passive'` — which connect path this
    /// attempt took (#2905). Lets the export distinguish a direct-connect
    /// 133 from a scan-fallback gate miss. Null when not stamped.
    @JsonKey(name: 'p') String? path,
  }) = _Obd2ReconnectAttempt;

  factory Obd2ReconnectAttempt.fromJson(Map<String, dynamic> json) =>
      _$Obd2ReconnectAttemptFromJson(json);
}

/// One session-state-transition marker: the moment the link's recovery
/// state machine moved between [Obd2SessionState]s, plus the
/// `Obd2DisconnectedException` drop marker and the GPS-fallback-activation
/// marker the trajet export previously omitted.
@freezed
abstract class Obd2SessionTransition with _$Obd2SessionTransition {
  const factory Obd2SessionTransition({
    /// Epoch-millisecond wall clock of the transition. 0 only for the
    /// const-default sentinel.
    @JsonKey(name: 't') @Default(0) int timestampMs,

    /// The state entered ([Obd2SessionState] name): `'connected'`,
    /// `'dropped'`, `'reconnecting'`, `'reconnected'`, `'orphaned'`,
    /// `'fallbackActivated'`, or `'disconnectedException'`.
    @JsonKey(name: 's') @Default('') String state,

    /// Optional low-cardinality detail (e.g. the drop reason name
    /// `'transportError'` / `'silentFailure'`, or the fallback kind). Null
    /// when none.
    @JsonKey(name: 'd') String? detail,
  }) = _Obd2SessionTransition;

  factory Obd2SessionTransition.fromJson(Map<String, dynamic> json) =>
      _$Obd2SessionTransitionFromJson(json);
}

/// The session-recovery states a transition marker records (#2905). String
/// names (via [name]) are what land in the compact export, so they are
/// stable, low-cardinality, and human-readable in a mailed JSON.
enum Obd2SessionState {
  /// A working link is established (cold connect or a recovery landed).
  connected,

  /// A mid-session link drop was detected.
  dropped,

  /// The reconnect scanner is actively trying to re-attach.
  reconnecting,

  /// A reconnect attempt established a NEW working link.
  reconnected,

  /// A reconnect connected a new service but the controller never swapped
  /// its service pointer (the #2904 orphaned-reconnect failure mode) — set
  /// by #2907 once it can detect the swap; the marker exists now so the
  /// next capture can carry it.
  orphaned,

  /// GPS-only fallback recording was activated because OBD2 dropped but GPS
  /// is alive.
  fallbackActivated,

  /// An `Obd2DisconnectedException` was raised on the byte stream — the
  /// typed drop marker.
  disconnectedException,
}

/// Normalised, low-cardinality reconnect-PATH failure reasons (#2905).
///
/// The init-path channels already bin connect failures into their own tags
/// (`gatt-error-133`, `gatt-connection-timeout`, `service-not-found`,
/// `rfcomm-open-fail`, `not-bonded`, …). The RECONNECT path needs the
/// compact taxonomy the field report asked for —
/// `rfcomm-open-fail / gatt-133 / device-not-connected / timeout / other` —
/// so [classifyReconnectReason] folds an arbitrary connect error (or a
/// channel reason tag) into one of these.
enum Obd2ReconnectReason {
  rfcommOpenFail('rfcomm-open-fail'),
  gatt133('gatt-133'),
  deviceNotConnected('device-not-connected'),
  timeout('timeout'),
  other('other');

  const Obd2ReconnectReason(this.code);

  /// The stable export tag for this reason.
  final String code;
}

/// Fold an arbitrary reconnect-path connect failure into the compact
/// [Obd2ReconnectReason] taxonomy (#2905). Accepts either a thrown error
/// object or a string (a channel's own reason tag) — both are matched
/// case-insensitively against the known signatures.
String classifyReconnectReason(Object error) {
  final msg = error.toString().toUpperCase();
  if (msg.contains('RFCOMM') ||
      msg.contains('RFCOMM-OPEN-FAIL') ||
      msg.contains('SOCKET')) {
    return Obd2ReconnectReason.rfcommOpenFail.code;
  }
  if (msg.contains('133') || msg.contains('GATT_ERROR')) {
    return Obd2ReconnectReason.gatt133.code;
  }
  if (msg.contains('NOT CONNECTED') ||
      msg.contains('DEVICE-NOT-CONNECTED') ||
      msg.contains('DISCONNECTED') ||
      msg.contains('TRANSPORT CLOSED')) {
    return Obd2ReconnectReason.deviceNotConnected.code;
  }
  if (msg.contains('TIMEOUT') || msg.contains('UNRESPONSIVE')) {
    return Obd2ReconnectReason.timeout.code;
  }
  return Obd2ReconnectReason.other.code;
}
