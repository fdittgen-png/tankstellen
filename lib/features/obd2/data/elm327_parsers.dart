// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'elm327_decode_util.dart';
import 'elm327_vin_parser.dart';

/// ELM327 response parsers — pure string→value decoders for Mode 01,
/// Mode 09 and Mode 22 responses.
///
/// Extracted from [Elm327Protocol] so the parser logic lives next to
/// its own unit tests without dragging in the command catalog (#563).
class Elm327Parsers {
  const Elm327Parsers._();

  /// Parse a raw ELM327 response string into usable data.
  ///
  /// Strips whitespace, '>', echo, and extracts the hex payload.
  /// Returns null if the response indicates an error or no data.
  ///
  /// #3279 — delegates to the shared [cleanElmResponse] in
  /// `elm327_decode_util.dart`; kept here as the stable public entry point the
  /// protocol layer + tests call.
  static String? cleanResponse(String raw) => cleanElmResponse(raw);

  /// Parse the ELM327 `ATDPN` (describe-protocol-number) reply into the
  /// bare protocol digit, stripping the leading `A` auto-flag (#2261
  /// concern 3).
  ///
  /// `ATDPN` returns the resolved protocol as a single digit (`1`–`9`,
  /// `A`–`C` for the CAN variants), prefixed with `A` when the protocol
  /// was reached via the ATSP0 auto-search — e.g. `A6` ⇒ auto-found
  /// protocol 6, `6` ⇒ explicitly pinned protocol 6. Both map to the
  /// same pinnable digit `6`. We strip ONLY a leading `A`; the `A`–`C`
  /// CAN protocol digits are themselves preserved.
  ///
  /// Returns null when the response is empty / a NO-DATA / error
  /// placeholder, or carries no recognisable protocol digit — the
  /// caller then keeps the safe ATSP0 fallback.
  static String? parseProtocolNumber(String raw) {
    var s = raw
        .replaceAll('>', '')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .toUpperCase()
        .trim();
    if (s.isEmpty ||
        s.contains('NO DATA') ||
        s.contains('UNABLE') ||
        s.contains('ERROR') ||
        s.contains('?')) {
      return null;
    }
    // Strip a single leading auto-flag `A`, then take the first
    // protocol-digit token (`0`–`9` or `A`–`C`).
    if (s.startsWith('A') && s.length >= 2) {
      s = s.substring(1).trim();
    }
    final match = RegExp(r'^([0-9A-C])').firstMatch(s);
    if (match == null) return null;
    final digit = match.group(1)!;
    // Protocol 0 is "automatic" — not a concrete pinnable protocol, so
    // it is treated as "nothing to cache".
    if (digit == '0') return null;
    return digit;
  }

  /// Parse vehicle speed from Mode 01 PID 0D response.
  /// Response format: "41 0D XX" where XX is speed in km/h.
  static int? parseVehicleSpeed(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = parseElmHexBytes(clean);
    if (bytes.length < 3 || bytes[0] != 0x41 || bytes[1] != 0x0D) return null;

    return bytes[2]; // Speed in km/h (0-255)
  }

  /// Parse engine RPM from Mode 01 PID 0C response.
  /// Response format: "41 0C XX YY" where RPM = ((XX * 256) + YY) / 4.
  static double? parseEngineRpm(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = parseElmHexBytes(clean);
    if (bytes.length < 4 || bytes[0] != 0x41 || bytes[1] != 0x0C) return null;

    return ((bytes[2] * 256) + bytes[3]) / 4.0;
  }

  /// Parse distance since DTC cleared from Mode 01 PID 31 response.
  /// Response format: "41 31 XX YY" where distance = (XX * 256) + YY km.
  static int? parseDistanceSinceDtcCleared(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = parseElmHexBytes(clean);
    if (bytes.length < 4 || bytes[0] != 0x41 || bytes[1] != 0x31) return null;

    return (bytes[2] * 256) + bytes[3];
  }

  /// Parse odometer from Mode 01 PID A6 response.
  /// Response format: "41 A6 XX YY ZZ WW" where odometer = value / 10 km.
  static double? parseOdometer(String raw) {
    final clean = cleanResponse(raw);
    if (clean == null) return null;

    final bytes = parseElmHexBytes(clean);
    if (bytes.length < 6 || bytes[0] != 0x41 || bytes[1] != 0xA6) return null;

    final value = (bytes[2] << 24) | (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];
    final km = value / 10.0; // Odometer in km (1/10 km resolution)
    return isPlausibleOdometerKm(km) ? km : null;
  }

  /// Parse calculated engine load from Mode 01 PID 04 response (#717).
  /// Formula: load% = value × 100 / 255. Response: "41 04 XX".
  static double? parseEngineLoad(String raw) =>
      _parse1BytePercent(raw, 0x04);

  /// Parse absolute throttle position from Mode 01 PID 11 response
  /// (#717). Formula: throttle% = value × 100 / 255. Response:
  /// "41 11 XX".
  static double? parseThrottlePercent(String raw) =>
      _parse1BytePercent(raw, 0x11);

  /// Parse fuel tank level from Mode 01 PID 2F response (#717).
  /// Formula: level% = value × 100 / 255. Response: "41 2F XX".
  static double? parseFuelLevelPercent(String raw) =>
      _parse1BytePercent(raw, 0x2F);

  /// Parse engine fuel rate from Mode 01 PID 5E response (#717).
  /// Formula: L/h = ((A × 256) + B) × 0.05. Response: "41 5E XX YY".
  static double? parseFuelRateLPerHour(String raw) {
    final bytes = parseModeOneBody(raw, 0x5E, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 0.05;
  }

  /// Parse mass air flow from Mode 01 PID 10 response (#717).
  /// Formula: g/s = ((A × 256) + B) × 0.01. Response: "41 10 XX YY".
  static double? parseMafGramsPerSecond(String raw) {
    final bytes = parseModeOneBody(raw, 0x10, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 0.01;
  }

  /// Parse intake manifold absolute pressure from Mode 01 PID 0B
  /// response (#800). Formula: kPa = A (single byte, raw value).
  /// Response: "41 0B XX". Physical range 0–255 kPa — idle around
  /// 30–40 kPa, wide-open throttle approaches atmospheric (~100 kPa)
  /// on NA engines, and up to 200+ kPa on turbocharged engines.
  static double? parseManifoldPressureKpa(String raw) {
    final bytes = parseModeOneBody(raw, 0x0B, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble();
  }

  /// Parse absolute barometric pressure from Mode 01 PID 33 response
  /// (#2456). Formula: kPa = A (single byte, raw value). Response:
  /// "41 33 XX". Sea level is ~101 kPa; pressure drops ~1 kPa per ~100 m
  /// of altitude, so a 1500 m pass reads ~84 kPa. Feeds the speed-density
  /// air-mass term so altitude / weather scale the air charge correctly.
  static double? parseBaroPressureKpa(String raw) {
    final bytes = parseModeOneBody(raw, 0x33, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble();
  }

  /// Parse the commanded fuel–air equivalence ratio φ from a Mode 01
  /// PID 44 response (#2456, convention verified #3426). Formula:
  /// φ = (256·A + B) × 2 / 65536 (= /32768, dimensionless). Response:
  /// "41 44 XX YY". SAE J1979 defines PID 0x44 as the *fuel–air*
  /// equivalence ratio φ = (F/A)/(F/A)stoich: φ ≈ 1.0 at stoichiometry;
  /// **φ < 1 is LEAN** (less fuel per unit air), **φ > 1 is RICH**
  /// (power-enrichment); λ = 1/φ. The effective AFR the engine is
  /// actually targeting is `stoichAFR / φ` (≡ `stoichAFR × λ`) — see
  /// `effectiveAfrForPhi` — which the fuel-rate estimator uses in place
  /// of the assumed-stoich AFR when this PID is available.
  static double? parseCommandedEquivalenceRatio(String raw) {
    final bytes = parseModeOneBody(raw, 0x44, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) / 32768.0;
  }

  /// Parse intake air temperature from Mode 01 PID 0F response (#800).
  /// Formula: °C = A − 40 (single byte). Response: "41 0F XX". Range
  /// −40 °C to 215 °C covers every drivable condition the sensor sees.
  static double? parseIntakeAirTempCelsius(String raw) {
    final bytes = parseModeOneBody(raw, 0x0F, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble() - 40.0;
  }

  /// Parse engine coolant temperature from Mode 01 PID 05 response
  /// (#1262). Formula: °C = A − 40 (single byte) — same encoding as
  /// PID 0F (intake air). Response: "41 05 XX". Range −40 °C to
  /// 215 °C. Used by the cold-start surcharge heuristic to flag trips
  /// whose ECT never reached operating temperature.
  static double? parseCoolantTempCelsius(String raw) {
    final bytes = parseModeOneBody(raw, 0x05, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble() - 40.0;
  }

  /// Parse short-term fuel trim bank 1 from Mode 01 PID 06 response
  /// (#813). Formula: `trim% = (A − 128) × 100 / 128`. Midpoint 128
  /// = 0 % (stoichiometric); <128 means the ECU is leaning the
  /// mixture (adding less fuel than stoich), >128 means it's
  /// enriching. Response: "41 06 XX". Valid range roughly
  /// −100 % … +99 %.
  static double? parseShortTermFuelTrim(String raw) =>
      _parseFuelTrim(raw, 0x06);

  /// Parse long-term fuel trim bank 1 from Mode 01 PID 07 response
  /// (#813). Same formula as STFT — captures persistent mixture
  /// offsets rather than the fast-feedback loop.
  static double? parseLongTermFuelTrim(String raw) =>
      _parseFuelTrim(raw, 0x07);

  /// Parse short-term fuel trim bank 2 from Mode 01 PID 08 response
  /// (#2458). Identical encoding to bank-1 STFT; only V / boxer engines
  /// expose a second bank. Returns null on NO DATA (inline engines).
  static double? parseShortTermFuelTrimBank2(String raw) =>
      _parseFuelTrim(raw, 0x08);

  /// Parse long-term fuel trim bank 2 from Mode 01 PID 09 response
  /// (#2458). Identical encoding to bank-1 LTFT; the slow per-bank
  /// offset on dual-bank engines. Returns null on NO DATA.
  static double? parseLongTermFuelTrimBank2(String raw) =>
      _parseFuelTrim(raw, 0x09);

  /// Shared fuel-trim decoder used by PIDs 06 / 07 / 08 / 09. Returns
  /// null on NO DATA.
  static double? _parseFuelTrim(String raw, int expectedPid) {
    final bytes = parseModeOneBody(raw, expectedPid, minBytes: 3);
    if (bytes == null) return null;
    return (bytes[2] - 128) * 100.0 / 128.0;
  }

  /// Helper for every "1 byte, scaled to percent" PID (04, 11, 2F).
  static double? _parse1BytePercent(String raw, int expectedPid) {
    final bytes = parseModeOneBody(raw, expectedPid, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2] * 100.0 / 255.0;
  }

  /// Parse accelerator-pedal position D from Mode 01 PID 49 response
  /// (#2458). Formula: `% = A × 100 / 255`. The driver-intent signal —
  /// distinct from absolute throttle (PID 11), which the ECU may damp
  /// for traction / cruise. Response: "41 49 XX".
  static double? parseAcceleratorPedalD(String raw) =>
      _parse1BytePercent(raw, 0x49);

  /// Parse accelerator-pedal position E from Mode 01 PID 4A response
  /// (#2458). Same `A × 100 / 255` encoding. Response: "41 4A XX".
  static double? parseAcceleratorPedalE(String raw) =>
      _parse1BytePercent(raw, 0x4A);

  /// Parse accelerator-pedal position F from Mode 01 PID 4B response
  /// (#2458). Same `A × 100 / 255` encoding. Response: "41 4B XX".
  static double? parseAcceleratorPedalF(String raw) =>
      _parse1BytePercent(raw, 0x4B);

  /// Parse absolute load value from Mode 01 PID 43 response (#2458).
  /// Formula: `load% = (256·A + B) × 100 / 255`. Normalised against a
  /// naturally-aspirated reference, so it **exceeds 100 %** on boosted
  /// engines under positive manifold pressure (a clean high-load proxy).
  /// Two-byte response: "41 43 XX YY".
  static double? parseAbsoluteLoad(String raw) {
    final bytes = parseModeOneBody(raw, 0x43, minBytes: 4);
    if (bytes == null) return null;
    return ((bytes[2] * 256) + bytes[3]) * 100.0 / 255.0;
  }

  /// Parse engine oil temperature from Mode 01 PID 5C response (#2459).
  /// Formula: °C = A − 40 (single byte) — same encoding as coolant / IAT.
  /// Response: "41 5C XX".
  static double? parseEngineOilTempCelsius(String raw) {
    final bytes = parseModeOneBody(raw, 0x5C, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble() - 40.0;
  }

  /// Parse ambient air temperature from Mode 01 PID 46 response (#2459).
  /// Formula: °C = A − 40 (single byte). Response: "41 46 XX".
  static double? parseAmbientAirTempCelsius(String raw) {
    final bytes = parseModeOneBody(raw, 0x46, minBytes: 3);
    if (bytes == null) return null;
    return bytes[2].toDouble() - 40.0;
  }

  /// Parse a supported-PIDs bitmap response (#811).
  ///
  /// For a `01 XX` request where `XX ∈ {00, 20, 40, 60, 80, A0, C0}`,
  /// the response is `41 XX AA BB CC DD` with AA–DD a 32-bit
  /// big-endian bitmap. Bit-N of the bitmap (MSB = bit 31) set means
  /// PID `(XX + 1 + (31 − N))` is supported. Equivalently: PID
  /// `(groupBase + 1 + bitIndexFromLeft)`.
  ///
  /// Returns the concrete set of supported PID integers, or null on
  /// NO DATA / malformed response. Each bitmap covers PIDs
  /// `groupBase+1` through `groupBase+32` inclusive.
  ///
  /// The last bit of each bitmap is conventionally "are PIDs in the
  /// next range also supported?"; callers use that to decide whether
  /// to query the next `01 {next_group}` command.
  static Set<int>? parseSupportedPidsBitmap(String raw, int groupBase) {
    final bytes = parseModeOneBody(raw, groupBase, minBytes: 6);
    if (bytes == null) return null;
    final supported = <int>{};
    // Iterate the four payload bytes, most-significant bit first.
    for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
      final payload = bytes[2 + byteIndex];
      for (var bit = 0; bit < 8; bit++) {
        final mask = 1 << (7 - bit);
        if ((payload & mask) != 0) {
          // First bit of the first byte → PID groupBase+1, etc.
          supported.add(groupBase + 1 + (byteIndex * 8) + bit);
        }
      }
    }
    return supported;
  }

  /// Parse fuel type from Mode 01 PID 51 response (#1399).
  ///
  /// Single-byte response per SAE-J1979 Table 6 — maps to the project's
  /// `preferredFuelType` enum strings via the shared [fuelTypeCodeToProfileKey]
  /// (`elm327_decode_util.dart`). The ECU truth wins over offline WMI / online
  /// vPIC during the VIN-driven adapter-pair auto-population flow because PID
  /// 0x51 reports what the ECU is actually configured for at runtime, not what
  /// a reference table thinks the model ships with.
  static String? parseFuelType(String raw) {
    final bytes = parseModeOneBody(raw, 0x51, minBytes: 3);
    if (bytes == null) return null;
    return fuelTypeCodeToProfileKey(bytes[2]);
  }

  /// Parse the ASCII VIN from a Mode 09 PID 02 response.
  ///
  /// #3278/#3279 — delegates to the framing-aware [Elm327VinParser], which
  /// correctly handles the real multi-frame `49 02 NN` framing (the old "last
  /// 17 chars" heuristic returned a wrong-but-plausible VIN on multiline
  /// replies). Returns null on NO DATA or fewer than 17 VIN characters.
  static String? parseVin(String raw) => Elm327VinParser.parse(raw);
}
