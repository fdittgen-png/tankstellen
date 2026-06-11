// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runtime capability tier of the connected ELM327-compatible adapter
/// (#1401 phase 1).
///
/// Orthogonal to [Obd2AdapterCompatibility] in `adapter_registry.dart`,
/// which classifies hardware MODELS we've verified work end-to-end.
/// This enum captures what the *current* connected adapter session can
/// actually do at runtime — derived from the firmware-version string
/// the adapter returns to `ATI`. Two units of the same physical model
/// can land on different capability tiers (e.g. a real OBDLink MX+
/// vs. a counterfeit clone selling under the same name).
///
/// Order matters. The comparator semantics are
///   passiveCanCapable >= oemPidsCapable >= standardOnly
/// — phases 2-7 of the epic gate behaviour with `>=` checks against
/// these values, so reordering would silently flip those gates.
enum Obd2AdapterCapability {
  /// OBD-II standard mode 01-09 PIDs only. Cheap clones, ELM327 v1.x.
  standardOnly,

  /// Manufacturer-specific PIDs reachable via header switching + raw
  /// commands. Genuine ELM327 v2.x and equivalent clones.
  oemPidsCapable,

  /// Listen-mode CAN bus access (passive sniffing of broadcast frames).
  /// STN-chip family — OBDLink MX+/LX/CX/EX (STN1110 / STN2120).
  passiveCanCapable,
}

/// Pure parser: classify an `ATI` firmware-version response string into
/// a runtime capability tier.
///
/// Matching rules (case-insensitive, leading/trailing whitespace
/// trimmed before matching):
///   * Starts with `STN1110` or `STN2120` (any version) →
///     [Obd2AdapterCapability.passiveCanCapable].
///   * `ELM327 v2.2`, `v2.3`, ..., `v3.x`, ... (genuine v2.2+) →
///     [Obd2AdapterCapability.oemPidsCapable].
///   * Anything else, including `ELM327 v2.0`, `ELM327 v2.1`,
///     `ELM327 v1.x`, empty, null, garbage →
///     [Obd2AdapterCapability.standardOnly].
///
/// Phase 1 trusts the version string. The well-known
/// "v2.1 clone claiming v2.2" trap is explicitly out of scope here —
/// a runtime feature-probe that downgrades lying clones is filed in
/// the epic (#1401) caveats and lands in a later phase.
Obd2AdapterCapability detectCapabilityFromFirmwareString(String? ati) {
  if (ati == null) return Obd2AdapterCapability.standardOnly;
  final normalized = ati.trim().toUpperCase();
  if (normalized.isEmpty) return Obd2AdapterCapability.standardOnly;

  // STN-chip family — passive CAN listen-mode capable.
  if (normalized.startsWith('STN1110') || normalized.startsWith('STN2120')) {
    return Obd2AdapterCapability.passiveCanCapable;
  }

  // Genuine ELM327 v2.2+ — OEM-PID capable.
  // Pattern: `ELM327 v(2.[2-9]|[3-9](\.\d+)?)` — accepts v2.2, v2.3,
  // ..., v2.9, v3, v3.x, v4, ... but NOT v2.0 / v2.1 / v1.x.
  final match =
      RegExp(r'^ELM327\s+V(\d+)(?:\.(\d+))?').firstMatch(normalized);
  if (match != null) {
    final major = int.parse(match.group(1)!);
    final minor = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (major >= 3) return Obd2AdapterCapability.oemPidsCapable;
    if (major == 2 && minor >= 2) return Obd2AdapterCapability.oemPidsCapable;
  }

  return Obd2AdapterCapability.standardOnly;
}

/// Outcome of the runtime multi-frame ISO 15765 capability probe
/// (#1614). The probe is the safety net for the well-known
/// "v2.1 clone reporting v2.2" trap that
/// [detectCapabilityFromFirmwareString] cannot catch — it trusts the
/// firmware string.
enum CapabilityProbeResult {
  /// The adapter demonstrably routed and reassembled a multi-frame
  /// ISO 15765 request — its claimed tier is trustworthy.
  multiFramePassed,

  /// The adapter returned an error / malformed response: it cannot
  /// route multi-frame requests despite what its firmware string
  /// claims. A lying clone lands here.
  multiFrameFailed,

  /// The probe did not complete within the timeout — treated the same
  /// as a failure for downgrade purposes (a genuine OEM-capable
  /// adapter answers `0902` well within the window).
  timedOut,
}

/// The ELM327 command used as the multi-frame probe — Mode 09 PID 02
/// (vehicle VIN). The VIN reply is the canonical multi-frame ISO-TP
/// exchange: a genuine v2.2+/STN adapter reassembles it across CAN
/// frames; a v2.1-class clone that merely *reports* v2.2 returns an
/// error token or a malformed single frame.
const String multiFrameProbeCommand = '0902';

/// Hard error tokens an ELM327-compatible adapter emits when it cannot
/// route a request. Their presence is a positive "the adapter failed"
/// signal — distinct from `NO DATA`, which only means the *vehicle*
/// did not answer (e.g. a pre-2005 car with no Mode 09 support).
const List<String> _probeErrorTokens = [
  'BUFFER FULL',
  'CAN ERROR',
  'BUS ERROR',
  'BUS INIT: ERROR',
  'BUS INIT: ...ERROR',
  'BUS BUSY',
  'DATA ERROR',
  'FB ERROR',
  '<DATA ERROR',
  'STOPPED',
  'UNABLE TO CONNECT',
  // Mode 09 negative-response service id (`7F 09 xx`).
  '7F 09',
  '7F09',
  // ELM327 emits `?` for a command it could not understand.
  '?',
];

/// Classify the raw adapter response to [multiFrameProbeCommand].
///
/// - Contains the positive-response service id `49 02` (Mode 09 + 0x40,
///   PID 02) → the adapter reassembled the multi-frame reply → passed.
/// - Contains a hard error token, or is empty → failed.
/// - `NO DATA` or anything else inconclusive → passed: the car may
///   simply not implement Mode 09. The probe must not punish a genuine
///   adapter for an old vehicle — only a positive failure signal
///   downgrades.
@visibleForTesting
CapabilityProbeResult classifyMultiFrameProbeResponse(String raw) {
  final r = raw.trim().toUpperCase();
  if (r.contains('49 02') || r.contains('4902')) {
    return CapabilityProbeResult.multiFramePassed;
  }
  if (r.isEmpty) return CapabilityProbeResult.multiFrameFailed;
  for (final token in _probeErrorTokens) {
    if (r.contains(token)) return CapabilityProbeResult.multiFrameFailed;
  }
  return CapabilityProbeResult.multiFramePassed;
}

/// Run the runtime multi-frame ISO 15765 probe (#1614).
///
/// Sends [multiFrameProbeCommand] through [sendCommand] and classifies
/// the response. A send that throws is treated as
/// [CapabilityProbeResult.multiFrameFailed]; a send that does not
/// answer within [timeout] is [CapabilityProbeResult.timedOut]. The
/// probe never throws — the connect flow stays resilient.
Future<CapabilityProbeResult> probeMultiFrameCapability(
  Future<String> Function(String command) sendCommand, {
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  try {
    final raw = await sendCommand(multiFrameProbeCommand).timeout(timeout);
    return classifyMultiFrameProbeResponse(raw);
  } on TimeoutException {
    return CapabilityProbeResult.timedOut;
  } catch (e, st) {
    debugPrint(
        'Obd2 capability probe: send failed, treating as multi-frame '
        'failure: $e\n$st');
    return CapabilityProbeResult.multiFrameFailed;
  }
}

/// Reconcile a firmware-string-derived capability tier with the runtime
/// probe outcome (#1614).
///
/// The probe can only ever *lower* a tier — it is a safety net against
/// lying clones, never a promotion path. A failed or timed-out probe
/// means the adapter cannot route even a multi-frame ISO 15765 request,
/// so it collapses straight to [Obd2AdapterCapability.standardOnly]
/// regardless of what tier the firmware string claimed (an adapter that
/// fails multi-frame certainly cannot do passive-CAN listen mode).
Obd2AdapterCapability reconcileCapabilityWithProbe(
  Obd2AdapterCapability claimed,
  CapabilityProbeResult probe,
) {
  switch (probe) {
    case CapabilityProbeResult.multiFramePassed:
      return claimed;
    case CapabilityProbeResult.multiFrameFailed:
    case CapabilityProbeResult.timedOut:
      return Obd2AdapterCapability.standardOnly;
  }
}
