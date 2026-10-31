// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4550 / #4549 (Epic #4547) — decoder for the OBD-II trouble-code
/// replies (Mode 03 stored, Mode 07 pending, Mode 0A permanent, and the
/// Mode 02 PID 02 freeze-frame DTC).
///
/// Pure Dart, no Flutter: the full-diagnostic recording decodes every
/// DTC reply into readable `P0300`-style codes next to the raw bytes in
/// its trace, so a reader never has to hand-decode the bit layout.
library;

/// The trouble codes in one ELM327 reply to [command] (`03`, `07`, `0A`
/// or `020200`). Returns an empty list for `NO DATA`, a zero-code reply
/// (`43 00`) or anything that is not a positive response; never throws.
///
/// Handles the three shapes an ELM327 produces with headers off:
///
/// * legacy K-line / J1850: `43 01 33 02 44 00 00` (three code slots
///   per line, `0000` padding, no count byte);
/// * single-frame CAN: `43 02 01 33 02 44` (a count byte after the echo);
/// * multi-frame CAN (ISO-TP): a byte-count line, then `0: 43 05 …`,
///   `1: …` continuation lines that are concatenated first.
///
/// Several ECUs answering (engine + gearbox) produce several response
/// echoes; each is decoded and the union is returned, de-duplicated, in
/// reply order.
List<String> decodeDtcReply(String command, String reply) {
  final mode = _modeOf(command);
  if (mode == null) return const [];
  final echo = mode + 0x40;
  final out = <String>[];
  void add(int a, int b) {
    final code = formatDtc(a, b);
    if (code != null && !out.contains(code)) out.add(code);
  }

  for (final message in _messages(reply)) {
    final bytes = message.bytes;
    if (bytes.isEmpty || bytes.first != echo) continue;
    if (mode == 0x02) {
      // Freeze-frame DTC: `42 02 <frame> <A> <B>`.
      if (bytes.length >= 5 && bytes[1] == 0x02) add(bytes[3], bytes[4]);
      continue;
    }
    var payload = bytes.sublist(1);
    final counted = payload.isNotEmpty &&
        (message.multiFrame
            ? payload.first * 2 + 1 <= payload.length
            : payload.length.isOdd && payload.first * 2 == payload.length - 1);
    if (counted) {
      // CAN: a count byte, then exactly 2×count bytes (ISO-TP may pad).
      payload = payload.sublist(1, 1 + payload.first * 2);
    }
    for (var i = 0; i + 1 < payload.length; i += 2) {
      add(payload[i], payload[i + 1]);
    }
  }
  return out;
}

/// Format one two-byte DTC: the top two bits of [a] select the system
/// letter (P powertrain, C chassis, B body, U network), the next two the
/// first digit, and the remaining 12 bits the three hex digits. A
/// `0000` slot is padding and returns null.
String? formatDtc(int a, int b) {
  if (a == 0 && b == 0) return null;
  const letters = ['P', 'C', 'B', 'U'];
  final letter = letters[(a >> 6) & 0x03];
  final first = (a >> 4) & 0x03;
  final rest = (((a & 0x0F) << 8) | b)
      .toRadixString(16)
      .toUpperCase()
      .padLeft(3, '0');
  return '$letter$first$rest';
}

int? _modeOf(String command) {
  final c = command.replaceAll(' ', '');
  if (c.length < 2) return null;
  return int.tryParse(c.substring(0, 2), radix: 16);
}

/// One response message: a single reply line, or an ISO-TP multi-frame
/// response whose `0:` / `1:` … continuation lines were concatenated.
typedef _Message = ({List<int> bytes, bool multiFrame});

/// Split [reply] into response messages, with the multi-frame byte-count
/// line (`00A`) and ELM chatter (`SEARCHING...`, `NO DATA`) removed.
List<_Message> _messages(String reply) {
  final out = <_Message>[];
  List<int>? frame; // the multi-frame message being assembled
  void closeFrame() {
    if (frame != null) out.add((bytes: frame!, multiFrame: true));
    frame = null;
  }

  final lines = reply
      .toUpperCase()
      .replaceAll('>', '\n')
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty);
  for (final line in lines) {
    if (RegExp(r'^[0-9A-F]{3}$').hasMatch(line)) continue; // byte count
    final indexed = RegExp(r'^([0-9A-F]):\s*(.*)$').firstMatch(line);
    final body = (indexed?.group(2) ?? line).replaceAll(' ', '');
    if (!RegExp(r'^[0-9A-F]+$').hasMatch(body) || body.length.isOdd) continue;
    final bytes = [
      for (var i = 0; i < body.length; i += 2)
        int.parse(body.substring(i, i + 2), radix: 16),
    ];
    if (indexed == null) {
      closeFrame();
      out.add((bytes: bytes, multiFrame: false));
    } else if (indexed.group(1) == '0') {
      closeFrame();
      frame = bytes;
    } else {
      (frame ??= <int>[]).addAll(bytes);
    }
  }
  closeFrame();
  return out;
}
