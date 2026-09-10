// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The two pieces of ELM327 AT-command grammar the connect handshake
// needs — pure string work over the wire protocol, with no service state
// behind them. #4035 (epic #4032): they were `static` members of a `part`
// mixin on Obd2Service, which gave them access to the whole service's
// private scope for no reason and made them unreachable from a test that
// does not build a service. A library of their own instead.

/// AT command that asks the ELM327 to identify itself. The reply is a
/// version string like `ELM327 v1.5` / `ELM327 v2.2` / `STN1110 v4.0.4`
/// (#1401 phase 1).
const String kObd2AtiCommand = 'ATI\r';

/// Strip the trailing ELM prompt (`>`) plus any CR/LF noise from a raw
/// `ATI` response. Returns null when the response was a NO-DATA-style
/// placeholder.
String? parseElmFirmwareString(String raw) {
  var s = raw.replaceAll('\r', ' ').replaceAll('\n', ' ');
  s = s.replaceAll('>', '').trim();
  // Collapse runs of whitespace introduced by stripping CR/LF.
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) return null;
  if (s.toUpperCase().contains('NO DATA')) return null;
  return s;
}

/// Whether [command] is a reset / wake command that needs a settle delay
/// after it (#2261 concern 5) — ATZ (full reset) or ATWS (warm start).
/// Every other AT echo / OBD request is serialised by the transport's
/// prompt-wait and needs no extra sleep.
bool isElmResetCommand(String command) {
  final c = command.trim().toUpperCase();
  return c == 'ATZ' || c == 'ATWS';
}
