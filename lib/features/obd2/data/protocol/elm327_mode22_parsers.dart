// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'elm327_decode_util.dart';

/// Mode 22 manufacturer-specific odometer parsers (#719), extracted from
/// [Elm327Parsers] (#3279) so the OBD-mode decoders live in focused files.
///
/// Standard Mode 01 PID A6 odometer support is rare; most OEMs expose the
/// odometer behind a brand-specific Mode 22 PID (`22 PH PL` → `62 PH PL …`).
/// Each parser validates the `62` echo + the expected PID bytes and applies
/// the shared [isPlausibleOdometerKm] gate so a saturated/garbage frame never
/// becomes a reading.
class Elm327Mode22Parsers {
  const Elm327Mode22Parsers._();

  /// Parse a 3-byte (big-endian, km) manufacturer odometer — used by
  /// VW group (22 22 03), BMW (22 30 16), Renault (22 21 02), etc.
  /// Expected response: `62 PH PL A B C` → km = (A*65536)+(B*256)+C.
  /// Returns null on NO DATA, a PID-echo mismatch, or an implausible value.
  static double? parseMfgOdometer3Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 6);
    if (bytes == null) return null;
    final km = ((bytes[3] << 16) | (bytes[4] << 8) | bytes[5]).toDouble();
    return isPlausibleOdometerKm(km) ? km : null; // #3275
  }

  /// Parse a 2-byte (big-endian, km) manufacturer odometer — used by
  /// Mercedes (22 F1 5B), PSA (22 D1 01). Expected response:
  /// `62 PH PL A B` → km = (A*256)+B. (#719)
  static double? parseMfgOdometer2Byte(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 5);
    if (bytes == null) return null;
    final km = ((bytes[3] << 8) | bytes[4]).toDouble();
    return isPlausibleOdometerKm(km) ? km : null; // #3275
  }

  /// Parse a Ford-style 2-byte miles-times-10 odometer (22 40 4D).
  /// Response: `62 40 4D A B` → miles_x10 = (A*256)+B. The raw value
  /// is miles × 10, so divide by 10 before converting to km. (#719)
  static double? parseMfgOdometerMilesTimes10(
    String raw, {
    required int expectedPidHi,
    required int expectedPidLo,
  }) {
    final bytes = _parseMode22Body(raw, expectedPidHi, expectedPidLo,
        minBytes: 5);
    if (bytes == null) return null;
    final milesTimes10 = (bytes[3] << 8) | bytes[4];
    final km = (milesTimes10 / 10.0) * 1.609344;
    return isPlausibleOdometerKm(km) ? km : null; // #3275
  }

  static List<int>? _parseMode22Body(
    String raw,
    int expectedPidHi,
    int expectedPidLo, {
    required int minBytes,
  }) {
    final clean = cleanResponse22(raw);
    if (clean == null) return null;
    final bytes = parseElmHexBytes(clean);
    if (bytes.length < minBytes) return null;
    if (bytes[0] != 0x62 ||
        bytes[1] != expectedPidHi ||
        bytes[2] != expectedPidLo) {
      return null;
    }
    return bytes;
  }

  /// Mode 22 response cleaner. Same as `Elm327Parsers.cleanResponse` but
  /// anchors on the "62" Mode 22 echo instead of "41".
  static String? cleanResponse22(String raw) {
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
    final idx = cleaned.indexOf('62');
    if (idx >= 0) return cleaned.substring(idx).trim();
    return cleaned;
  }
}
