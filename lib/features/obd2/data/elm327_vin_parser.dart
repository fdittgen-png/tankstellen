// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Framing-aware decoder for the Mode 09 PID 02 (`0902`) VIN response (#3278).
///
/// Extracted from `Elm327Parsers` (#3279) so the VIN framing — which is genuinely
/// different from the single-line Mode 01 decoders — lives in one focused,
/// testable place, and so its VIN-safe cleaner does not share `Elm327Parsers`'
/// `cleanResponse` (that one anchors the string on the first `41`, which would
/// corrupt a VIN whose second character is `A` = 0x41, e.g. an Audi `WA1…`).
///
/// ## Why a framing-aware parse
///
/// A real ELM327 VIN reply is multi-frame, e.g. a captured Peugeot 308:
///
/// ```
/// 014
/// 0: 49 02 01 56 46 33
/// 1: 4C 43 42 4D 42 32 43
/// 2: 53 32 36 31 38 39 32
/// 3: 33 39 00 00 00 00 00
/// ```
///
/// The first line is the ISO-TP length, each line carries an `N:` index prefix
/// (unparseable as hex → dropped), the `49 02 01` is the mode/PID echo + item
/// count, then the **17 VIN bytes**, then padding. A naive "take the last 17
/// printable chars" heuristic returns the WRONG 17 here (it slides past the
/// genuine VIN into the trailing `39` + padding), yielding a plausible but
/// incorrect VIN that mis-selects the OEM PID table.
///
/// This parser instead anchors on the `49 02` echo, then takes the FIRST 17
/// VIN-charset bytes that follow (skipping the item-count byte, any padding and
/// the per-frame echoes), which is the real VIN. With no echo present it falls
/// back to the first 17 VIN-charset bytes from the start.
class Elm327VinParser {
  const Elm327VinParser._();

  /// Decode the VIN, or null on NO DATA / fewer than 17 VIN characters.
  static String? parse(String raw) {
    final cleaned = _clean(raw);
    if (cleaned == null) return null;

    final bytes = <int>[];
    for (final token in cleaned.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final b = int.tryParse(token, radix: 16);
      // Keep only real single bytes; an `N:` line prefix / stray token parses
      // to null and is dropped, as is anything outside 0x00–0xFF.
      if (b != null && b >= 0 && b <= 0xFF) bytes.add(b);
    }

    // Anchor past the `49 02` (Mode 09 / PID 02) echo when present, so the
    // item-count byte + any pre-VIN framing are skipped; otherwise scan from 0.
    var start = 0;
    for (var i = 0; i + 1 < bytes.length; i++) {
      if (bytes[i] == 0x49 && bytes[i + 1] == 0x02) {
        start = i + 2;
        break;
      }
    }

    // Take the FIRST 17 VIN-charset bytes from the anchor — the count byte,
    // padding zeros and per-frame echoes are not VIN chars, so they're skipped.
    final chars = <int>[];
    for (var i = start; i < bytes.length && chars.length < 17; i++) {
      if (_isVinChar(bytes[i])) chars.add(bytes[i]);
    }
    if (chars.length < 17) return null;
    return String.fromCharCodes(chars);
  }

  /// VIN-safe cleaner: strips the prompt + CR/LF and rejects the error / no-data
  /// sentinels, WITHOUT the `41`-anchoring [Elm327Parsers.cleanResponse] does
  /// (Mode 09 responses begin `49`, and a VIN byte can legitimately be `0x41`).
  static String? _clean(String raw) {
    final cleaned = raw
        .replaceAll('>', '')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .trim();
    if (cleaned.isEmpty ||
        cleaned.contains('NO DATA') ||
        cleaned.contains('UNABLE TO CONNECT') ||
        cleaned.contains('ERROR') ||
        cleaned.contains('?')) {
      return null;
    }
    return cleaned;
  }

  /// A VIN character: digit 0-9 or A-Z excluding I/O/Q (reserved by VIN rules
  /// to avoid confusion with 1/0; `49`='I' is also the Mode 09 echo byte).
  static bool _isVinChar(int b) {
    if (b >= 0x30 && b <= 0x39) return true; // 0-9
    return b >= 0x41 &&
        b <= 0x5A &&
        b != 0x49 && // I
        b != 0x4F && // O
        b != 0x51; // Q
  }
}
