// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

part 'obd2_connect_trace.freezed.dart';
part 'obd2_connect_trace.g.dart';

/// Where a connect ATTEMPT originated (#2969). Stamped on the trace so the
/// health screen can tell a self-test probe from a live first-connect or an
/// in-trip reconnect — the difference between "I pressed Run" and "the app
/// silently failed to reconnect mid-drive".
enum Obd2ConnectOrigin {
  /// The developer-tools "Run adapter test" button (`runObd2SelfTest`).
  selfTest,

  /// An in-trip reconnect after a mid-session drop (`ReconnectConnector`).
  liveReconnect,

  /// The very first connect of a recording / on app resume
  /// (recording-start coordinator / auto-record orchestrator).
  firstConnect,

  /// Any other auto-record-driven connect not covered above.
  autoRecord,
}

/// The transport a connect step requested / resolved (#2969). `unknown` is the
/// honest state when no transport hint could be inferred (a paired adapter
/// whose stored name matches no registry profile) — the trace then records the
/// BLE default decision EXPLICITLY rather than silently.
enum Obd2ConnectTransport { ble, classic, unknown }

/// The terminal outcome of a connect attempt (#2969).
///
/// FIRST-TERMINAL-WINS: once [Obd2ConnectTraceLog.setOutcome] stamps a non-null
/// outcome, later fallback steps append as [Obd2ConnectStep]s but never
/// overwrite the primary outcome. This is load-bearing — `_connectByMacDirect`
/// swallows the BLE 4 s timeout and silently re-runs `scan()`, so without
/// first-wins the wrong-transport [gattTimeout] would be overwritten by the
/// fallback's [scanEmpty].
enum Obd2ConnectOutcome {
  /// Connect + ELM init completed; the session is live.
  success,

  /// The scan window elapsed with no known adapter in range, or
  /// `connectBest()` had no ranked candidate cached (`Obd2ScanTimeout` /
  /// empty `_lastRanked`).
  scanEmpty,

  /// The runtime BLUETOOTH_SCAN/CONNECT (or legacy location) grant is missing
  /// (`Obd2PermissionDenied`). Needs a settings deep-link.
  permissionDenied,

  /// The OS Bluetooth radio is off (`Obd2BluetoothOff`).
  bluetoothOff,

  /// A bounded BLE GATT connect timed out — most often the wrong-transport
  /// case (a BLE direct connect against a Classic-SPP adapter can only
  /// 4 s-timeout) or an out-of-range adapter.
  gattTimeout,

  /// Android GATT_ERROR 133 — a stale GATT client or a flaky BLE stack.
  gatt133,

  /// The BLE link opened but the device exposed no ELM327 service / write /
  /// notify characteristic (a non-OBD2 BLE device, or a clone with a garbage
  /// GATT table).
  serviceNotFound,

  /// A Classic-SPP RFCOMM socket open failed (the Kotlin plugin returned
  /// `ok:false`, or threw an IOException across all three strategies).
  rfcommOpenFail,

  /// The channel opened but the ELM327 init handshake (ATZ → ATE0 → … )
  /// timed out (`Obd2AdapterUnresponsive` from an init timeout / a raw
  /// `TimeoutException` on the init path).
  initTimeout,

  /// ATZ returned something unrecognisable — usually a counterfeit ELM327
  /// clone whose firmware lies (`Obd2ProtocolInitFailed`). Actionable:
  /// "the adapter is fake".
  protocolInitFailed,

  /// The channel + init succeeded but the ECU never answered the first
  /// PID/protocol probe — NO DATA / silent bus (`Obd2AdapterUnresponsive`
  /// from a post-init probe). The #1 real field condition: a parked car
  /// with the ignition off.
  ignitionOff,

  /// BLE pairing/bonding was required but did not complete (#3181): the
  /// connect/setNotify failed with an authentication / encryption /
  /// pairing / bond error, or the setNotify timed out on a FIRST-connect
  /// deviceId (the OBDLink CX initiates pairing via the first CCCD
  /// subscribe and only accepts new bonds ~5 min after power-on).
  /// Actionable: power-cycle the adapter and retry within 5 minutes.
  pairingRequired,

  /// An unclassified failure. The [Obd2ConnectTrace.failureDetail] carries
  /// the raw `toString()` so a maintainer can still triage it.
  unknown,
}

/// Per-step status inside a connect trace (#2969).
enum Obd2ConnectStepStatus { ok, timeout, fail, skipped }

/// One device seen during the scan phase of a connect attempt (#2969). The MAC
/// is redacted (PII) the same way the comm-health session redacts it.
@freezed
abstract class Obd2ScannedDevice with _$Obd2ScannedDevice {
  const factory Obd2ScannedDevice({
    @JsonKey(name: 'mac') String? redactedMac,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'rssi') int? rssi,
    @JsonKey(name: 'tx') required Obd2ConnectTransport transport,
    @JsonKey(name: 'pid') String? matchedProfileId,
  }) = _Obd2ScannedDevice;

  factory Obd2ScannedDevice.fromJson(Map<String, dynamic> json) =>
      _$Obd2ScannedDeviceFromJson(json);
}

/// One step of a connect attempt (#2969): a labelled, timed phase of the
/// connect path. Labels mirror the real sequence — scan / rank /
/// transport-select / channel-open / gatt-discover / set-notify, then each AT
/// line (ATZ/ATE0/ATL0/ATH0/ATS0/ATSP0/ATI/ATRV…) and finally first-pid
/// (0100).
@freezed
abstract class Obd2ConnectStep with _$Obd2ConnectStep {
  const factory Obd2ConnectStep({
    @JsonKey(name: 'l') required String label,
    @JsonKey(name: 's') required Obd2ConnectStepStatus status,
    @JsonKey(name: 'sm') int? startMs,
    @JsonKey(name: 'em') int? endMs,
    @JsonKey(name: 'd') String? detail,
  }) = _Obd2ConnectStep;

  factory Obd2ConnectStep.fromJson(Map<String, dynamic> json) =>
      _$Obd2ConnectStepFromJson(json);
}

/// One connect attempt's complete, session-INDEPENDENT trace (#2969).
///
/// This is the artefact the user's #1 OBD2 complaint was about: a FAILED
/// connect — even with developer mode OFF — must leave a complete, downloadable
/// record of *why* it failed. It sits ABOVE the comm-health session
/// (`Obd2SessionDiagnostic`), which only ever begins AFTER the channel opens
/// and so captures nothing when the connect dies in scan / transport-select /
/// channel-open.
@freezed
abstract class Obd2ConnectTrace with _$Obd2ConnectTrace {
  const factory Obd2ConnectTrace({
    @JsonKey(name: 'id') required String attemptId,
    @JsonKey(name: 'st') required int startedAtMs,
    @JsonKey(name: 'et') int? endedAtMs,
    @JsonKey(name: 'tm') int? totalMs,
    @JsonKey(name: 'or') required Obd2ConnectOrigin origin,
    @JsonKey(name: 'mac') String? requestedMac,
    // #3014 (Epic #3013, Phase 1) — the human adapter NAME (e.g. `SmartOBD`,
    // `vLinker FS 1234`). The maintainer's #1 complaint about the trace tool:
    // a by-MAC / self-test attempt showed only the redacted MAC (`···F:31`),
    // so there was no way to tell WHICH adapter failed. The name IS known at
    // every connect entry (the paired-adapter name, or the resolved scan
    // candidate's advertised name) — it was simply dropped before the trace.
    // Null when no name could be resolved (a cold scan with an anonymous
    // advertiser); the card then falls back to the redacted MAC.
    @JsonKey(name: 'nm') String? adapterName,
    @JsonKey(name: 'rtx') required Obd2ConnectTransport requestedTransport,
    @JsonKey(name: 'ztx') Obd2ConnectTransport? resolvedTransport,
    @JsonKey(name: 'tdr') String? transportDecisionReason,
    @JsonKey(name: 'oc') Obd2ConnectOutcome? outcome,
    @JsonKey(name: 'fd') String? failureDetail,
    @JsonKey(name: 'steps')
    @Default(<Obd2ConnectStep>[]) List<Obd2ConnectStep> steps,
    @JsonKey(name: 'scan')
    @Default(<Obd2ScannedDevice>[]) List<Obd2ScannedDevice> scanned,
  }) = _Obd2ConnectTrace;

  factory Obd2ConnectTrace.fromJson(Map<String, dynamic> json) =>
      _$Obd2ConnectTraceFromJson(json);
}
