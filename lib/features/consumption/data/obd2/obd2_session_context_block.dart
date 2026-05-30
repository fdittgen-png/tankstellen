// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_comm_diagnostics.dart';
import 'obd2_session_completeness.dart';
import 'obd2_session_diagnostic.dart';

/// Builds the compact `obd2Session` block that OBD2-related
/// `errorLogger.log(...)` callsites stamp into their `context` map so the
/// session diagnostics ride INSIDE the existing `TraceStorage`
/// `exportAsJson()` envelope — with no key/shape change to the envelope
/// itself (#2472, TAIL of Epic #2463). The maintainer's actual debug
/// channel is the mailed JSON export, so this is where the comm-health
/// data reaches them.
///
/// Returns `null` when the diagnostics collector is disabled (developer
/// mode off) or no session has been recorded — so a production export is
/// NEVER null-polluted with an empty block. Callers spread the result into
/// their `context` only when it is non-null.
///
/// PII-safe by construction: the collector already stores the MAC in its
/// redacted (`redactObd2Mac`) form, and this builder re-scrubs it with the
/// shared [_redactMac] helper as a defensive belt-and-braces guard before
/// it reaches the exported JSON. No VIN / GPS data is in the snapshot.
///
/// The block is intentionally compact — it reuses the model's short JSON
/// keys (`session.toJson()` carries `pid`/`conn`/`sch`/`cm`/...) plus a
/// small derived completeness header — so it stays small inside an
/// already-bounded error-trace ring.
Map<String, Object?>? buildObd2SessionContextBlock({
  Obd2CommDiagnostics? collector,
}) {
  final diag = collector ?? Obd2CommDiagnostics.instance;
  if (!diag.enabled) return null;
  final raw = diag.snapshot();
  // An empty const-default snapshot (no session yet) has nothing worth
  // stamping — keep the export clean.
  if (!_hasSignal(raw)) return null;

  // Ensure the completeness rollup is filled even for a live (not-yet-
  // settled) session, so the header reflects what we have so far.
  final session = raw.completeness.overallPercent > 0 || raw.pidStats.isEmpty
      ? raw
      : summariseObd2Completeness(raw);

  return <String, Object?>{
    'obd2Session': _compact(session),
  };
}

/// The full `context` map for the OBD2 disconnect-on-stop trace (#2472):
/// the `where` tag plus the [buildObd2SessionContextBlock] enrichment when
/// it is present. In production (collector disarmed / no session) the block
/// is null and the map is exactly the legacy `{'where': ...}` — so the
/// exported error log is byte-unchanged.
Map<String, Object?> obd2DisconnectTraceContext({
  Obd2CommDiagnostics? collector,
}) {
  final block = buildObd2SessionContextBlock(collector: collector);
  return <String, Object?>{
    'where': 'Obd2RecordingPipeline.stop: service disconnect failed',
    if (block != null) ...block,
  };
}

/// True when the snapshot carries at least one signal worth exporting.
bool _hasSignal(Obd2SessionDiagnostic s) =>
    s.pidStats.isNotEmpty ||
    s.connection.attempts > 0 ||
    s.redactedMac != null ||
    s.elmVersion != null ||
    s.initTranscript.isNotEmpty;

/// Compact JSON map for the session, re-scrubbing the MAC defensively.
Map<String, Object?> _compact(Obd2SessionDiagnostic session) {
  final json = session.toJson();
  // Defensive belt-and-braces: re-scrub the MAC even though the collector
  // already redacts it. `mac` is the model's short JSON key for redactedMac.
  final mac = json['mac'];
  if (mac is String) json['mac'] = _redactMac(mac);
  return json;
}

/// Redact a BLE MAC / remote-id to its last four characters — a full MAC
/// is a stable hardware identifier (PII). Mirrors the `_redactMac` helper
/// in `obd2_diagnostic_report.dart`; a string already in the middle-dot
/// redacted form passes through unchanged (its last four chars are kept).
String _redactMac(String mac) {
  if (mac.length <= 4) return mac;
  final visible = mac.substring(mac.length - 4);
  return '${'·' * (mac.length - 4)}$visible';
}
