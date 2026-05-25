// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'auto_record_trace_log.dart';

/// Formats a list of [AutoRecordEvent]s into a plain-text OBD2
/// connection/recording diagnostic report (#1920).
///
/// The report is meant to be handed to the OS share sheet so a user
/// can send the trace of a failed recording session to a developer.
/// It is deliberately:
///
///  * **plain text** — readable in any mail / chat client, no parsing
///    tooling required;
///  * **PII-safe** — the BLE MAC address is redacted to its last four
///    characters (a full MAC is a stable hardware identifier). No VIN,
///    no GPS coordinates are ever in the trace ring, so nothing else
///    needs scrubbing here.
///
/// Output shape:
///
/// ```text
/// OBD2 diagnostic log — generated 2024-01-15 09:30:00
/// [09:30:01.123] connectStarted  ··········EE:FF
/// [09:30:03.456] connectSucceeded  ··········EE:FF  ELM327 v1.5
/// ```
///
/// One header line (the generated-at timestamp) followed by one line
/// per event: `[HH:mm:ss.SSS] <kind>  <mac?>  <detail?>`. An empty
/// event list produces a clear "no events recorded" line so the
/// recipient can tell an empty trace apart from a truncated paste.
String formatObd2DiagnosticReport(
  List<AutoRecordEvent> events, {
  DateTime? generatedAt,
}) {
  final DateTime stamp = generatedAt ?? DateTime.now();
  final StringBuffer buffer = StringBuffer()
    ..writeln('OBD2 diagnostic log — generated ${_formatStamp(stamp)}');

  if (events.isEmpty) {
    buffer.writeln('(no events recorded)');
    return buffer.toString();
  }

  for (final AutoRecordEvent event in events) {
    final List<String> parts = <String>[
      '[${_formatEventTime(event.timestamp)}]',
      event.kind.name,
      if (event.mac != null) _redactMac(event.mac!),
      if (event.detail != null) event.detail!,
    ];
    buffer.writeln(parts.join('  '));
  }
  return buffer.toString();
}

/// `YYYY-MM-DD HH:mm:ss` header timestamp.
String _formatStamp(DateTime ts) {
  final String y = ts.year.toString().padLeft(4, '0');
  final String mo = ts.month.toString().padLeft(2, '0');
  final String d = ts.day.toString().padLeft(2, '0');
  return '$y-$mo-$d ${_formatClock(ts)}';
}

/// `HH:mm:ss.SSS` per-event timestamp.
String _formatEventTime(DateTime ts) {
  final String ms = ts.millisecond.toString().padLeft(3, '0');
  return '${_formatClock(ts)}.$ms';
}

/// `HH:mm:ss` clock fragment shared by both formats.
String _formatClock(DateTime ts) {
  final String h = ts.hour.toString().padLeft(2, '0');
  final String m = ts.minute.toString().padLeft(2, '0');
  final String s = ts.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Redact a BLE MAC / remote-id to its last four characters — a full
/// MAC is a stable hardware identifier (PII). Everything before the
/// final four characters is replaced with the middle-dot `·` so the
/// length is still visible without leaking the address.
///
/// `AA:BB:CC:DD:EE:FF` → `···············E:FF`. A string of four
/// characters or fewer is returned unchanged (there is nothing to
/// hide).
String _redactMac(String mac) {
  if (mac.length <= 4) return mac;
  final String visible = mac.substring(mac.length - 4);
  return '${'·' * (mac.length - 4)}$visible';
}
