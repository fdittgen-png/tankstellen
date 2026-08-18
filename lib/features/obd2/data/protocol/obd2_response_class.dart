// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The single source of truth for classifying one raw ELM327 adapter
/// reply into a coarse health bucket (#2464, foundation of Epic #2463).
///
/// Every comm-path layer that observes an adapter reply funnels the raw
/// string through [classifyObd2Response] so the `Obd2CommDiagnostics`
/// collector counts a consistent, single-vocabulary outcome per
/// dispatched PID — rather than each call-site re-implementing its own
/// "is this NO DATA?" string match. That consistency is what lets one
/// exported error-log distinguish a flaky clone (mostly [timeout] /
/// [garbage]) from an unsupported-PID car (mostly [noData]) without the
/// physical adapter.
///
/// Pure + framework-free: no allocation beyond the cleaned string, no
/// platform handles, safe to call from a unit test or a hot poll loop.
enum ResponseClass {
  /// A parseable hex data line — the reply began with (or contained) a
  /// recognisable Mode-01/09/22 positive-response echo (`41`/`49`/`62`)
  /// followed by hex byte tokens. The happy path.
  ok,

  /// The adapter explicitly reported `NO DATA` / `NODATA` — the ECU
  /// answered but had nothing for that PID (commonly: PID unsupported,
  /// or engine off). Distinct from [timeout]: the link is alive.
  noData,

  /// No reply arrived within the caller's deadline. NEVER inferred from
  /// the raw string — a timeout has no text to classify, so the caller
  /// passes this value directly to the collector when its read future
  /// elapses. Exposed here so the comm-path has one vocabulary for all
  /// outcomes.
  timeout,

  /// The adapter answered but the reply was not understood — an ELM
  /// command error (`?`), `UNABLE TO CONNECT` (no ECU on the bus), or
  /// `STOPPED` (interrupted command). The link exists but the request
  /// did not complete.
  unrecognized,

  /// `BUFFER FULL` — the adapter's receive buffer overflowed before the
  /// full frame was read; classic on slow clones at high poll rates.
  bufferFull,

  /// `CAN ERROR` — the adapter reported a CAN-bus framing/arbitration
  /// fault. Points at wiring / protocol-autodetect trouble rather than
  /// an unsupported PID.
  canError,

  /// Non-ASCII bytes or an unframed reply that matched no known shape —
  /// the wire was noisy or the previous frame leaked into this read.
  garbage,
}

/// Classify one raw adapter reply [raw] into a [ResponseClass].
///
/// Order of checks matters — specific ELM error vocab is matched before
/// the generic hex/garbage discrimination:
///
///   1. empty / whitespace-or-prompt-only        → [ResponseClass.garbage]
///   2. non-ASCII bytes present                   → [ResponseClass.garbage]
///   3. `BUFFER FULL`                             → [ResponseClass.bufferFull]
///   4. `CAN ERROR`                               → [ResponseClass.canError]
///   5. `NO DATA` / `NODATA`                      → [ResponseClass.noData]
///   6. `UNABLE TO CONNECT` / `STOPPED` / `?`     → [ResponseClass.unrecognized]
///   7. a positive-response hex line (41/49/62 …) → [ResponseClass.ok]
///   8. anything else                             → [ResponseClass.garbage]
///
/// [ResponseClass.timeout] is never returned — it has no raw string to
/// inspect and is set by the caller when no reply arrives at all.
ResponseClass classifyObd2Response(String raw) {
  // Strip the conversational frame the ELM appends: a trailing '>'
  // prompt, CR/LF line terminators, and surrounding whitespace.
  final stripped = raw
      .replaceAll('>', ' ')
      .replaceAll('\r', ' ')
      .replaceAll('\n', ' ');
  final trimmed = stripped.trim();

  // (1) Nothing but prompt / whitespace — the adapter said nothing
  // meaningful. Treat an empty frame as garbage (a true no-reply is the
  // caller's [ResponseClass.timeout], not this).
  if (trimmed.isEmpty) return ResponseClass.garbage;

  // (2) Any byte outside printable ASCII (0x20–0x7E) means the wire was
  // noisy or a binary frame leaked in — unframed garbage.
  for (final unit in trimmed.codeUnits) {
    if (unit < 0x20 || unit > 0x7E) return ResponseClass.garbage;
  }

  final upper = trimmed.toUpperCase();
  // Collapse internal whitespace so "BUFFER  FULL" / "BUFFER\rFULL" still
  // match the canonical vocab.
  final collapsed = upper.replaceAll(RegExp(r'\s+'), ' ');

  // (3)–(4) Adapter-buffer / CAN faults — matched before NO DATA because
  // a clone can emit "BUFFER FULL" alongside a partial data line.
  if (collapsed.contains('BUFFER FULL')) return ResponseClass.bufferFull;
  if (collapsed.contains('CAN ERROR')) return ResponseClass.canError;

  // (5) NO DATA — both the spaced and the run-together spellings clones
  // emit.
  if (collapsed.contains('NO DATA') || collapsed.contains('NODATA')) {
    return ResponseClass.noData;
  }

  // (6) Command not understood / no ECU / interrupted.
  if (collapsed.contains('UNABLE TO CONNECT') ||
      collapsed.contains('STOPPED') ||
      collapsed.contains('?')) {
    return ResponseClass.unrecognized;
  }

  // (7) A positive-response hex data line: at least one Mode echo token
  // (41/49/62) followed by hex byte tokens. We require the echo so a
  // bare error word like "ERROR" or "SEARCHING..." does not masquerade
  // as data.
  final tokens = collapsed
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  if (_looksLikePositiveHexLine(tokens)) return ResponseClass.ok;

  // (8) Framed ASCII, but matched no known shape — treat as garbage so
  // the collector's garbage bucket captures unknown adapter chatter
  // (e.g. "SEARCHING...", a bare "ERROR" without a known prefix).
  return ResponseClass.garbage;
}

/// True when [tokens] form a positive-response hex line: contains a
/// Mode-response echo (`41`/`49`/`62`) and every token from that echo
/// onward is a valid hex byte. A lone echo with no payload bytes is NOT
/// ok (it carries no data — needs echo + PID + ≥1 data byte).
bool _looksLikePositiveHexLine(List<String> tokens) {
  if (tokens.isEmpty) return false;
  const echoes = {'41', '49', '62'};
  // Locate the first Mode-response echo.
  var echoAt = -1;
  for (var i = 0; i < tokens.length; i++) {
    if (echoes.contains(tokens[i])) {
      echoAt = i;
      break;
    }
  }
  if (echoAt < 0) return false;
  // Need at least echo + PID + one payload byte after the echo.
  final payload = tokens.sublist(echoAt);
  if (payload.length < 3) return false;
  // Every token from the echo onward must be a hex byte.
  for (final token in payload) {
    if (!_isHexByteToken(token)) return false;
  }
  return true;
}

/// True when [token] is a 1–2 character hex byte (e.g. `41`, `0D`, `F`).
bool _isHexByteToken(String token) {
  if (token.isEmpty || token.length > 2) return false;
  for (final unit in token.codeUnits) {
    final isDigit = unit >= 0x30 && unit <= 0x39; // 0-9
    final isHexAlpha = unit >= 0x41 && unit <= 0x46; // A-F (already upper)
    if (!isDigit && !isHexAlpha) return false;
  }
  return true;
}
