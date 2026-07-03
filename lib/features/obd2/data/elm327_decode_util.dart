// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Low-level ELM327 decode helpers shared by the Mode 01/09 parsers
/// ([Elm327Parsers]) and the Mode 22 manufacturer parsers
/// ([Elm327Mode22Parsers]) — extracted (#3279) so neither parser file owns
/// the other, and the decomposition leaves a single definition of each.
library;

/// Parse a space-separated hex-byte string ("41 0C 1A F8") into a list of
/// byte values, dropping any token that isn't valid hex.
List<int> parseElmHexBytes(String hex) => hex
    .split(RegExp(r'\s+'))
    .where((s) => s.isNotEmpty)
    .map((s) => int.tryParse(s, radix: 16))
    .whereType<int>()
    .toList();

/// The largest odometer reading treated as real (#3275): no production car
/// reaches 2,000,000 km, so a higher value is a saturated/garbage frame, and 0
/// is a no-data sentinel — both must be rejected before they corrupt the
/// downstream distance/fuel math.
const double maxPlausibleOdometerKm = 2000000.0;

/// Whether [km] is a plausible odometer reading (#3275).
bool isPlausibleOdometerKm(double km) =>
    km.isFinite && km > 0 && km <= maxPlausibleOdometerKm;

/// Clean a raw ELM327 response: strip `>`, CR/LF and surrounding space,
/// reject the NO DATA / UNABLE / ERROR / `?` placeholders, and anchor on the
/// first `41` (the Mode 01 positive-response prefix) to drop the command echo.
///
/// #3279 — moved here from `Elm327Parsers.cleanResponse` (kept as a thin
/// delegating stub for backward compat) so the Mode 01 framing helper
/// [parseModeOneBody] can live next to the other shared decode plumbing
/// instead of forcing the parser sub-files to depend on the parser class.
String? cleanElmResponse(String raw) {
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

  // Remove echo (command echo before response).
  // Response starts with "41" for Mode 01 responses.
  final idx = cleaned.indexOf('41');
  if (idx >= 0) return cleaned.substring(idx).trim();

  return cleaned;
}

/// Shared Mode 01 plumbing: clean the response, verify the `41` echo +
/// expected PID, and return the byte array — or null when the response is
/// missing / malformed. #3279 — moved here from `Elm327Parsers`.
List<int>? parseModeOneBody(
  String raw,
  int expectedPid, {
  required int minBytes,
}) {
  final clean = cleanElmResponse(raw);
  if (clean == null) return null;
  final bytes = parseElmHexBytes(clean);
  if (bytes.length < minBytes) return null;
  if (bytes[0] != 0x41 || bytes[1] != expectedPid) return null;
  return bytes;
}

/// Map an SAE-J1979 PID 0x51 fuel-type byte to the project's
/// `preferredFuelType` enum strings ("petrol", "diesel", …). #3279 — moved
/// here from `Elm327Parsers` (kept as a delegating stub) so the pure mapping
/// lives with the other decode helpers.
///
/// Recognised codes:
///   0x01 → 'petrol'  (Gasoline)
///   0x03 → 'e85'     (Ethanol — flexfuel ECUs report this, #3429)
///   0x04 → 'diesel'  (Diesel)
///   0x05 → 'lpg'     (Liquefied Petroleum Gas)
///   0x06 → 'cng'     (Compressed Natural Gas)
///   0x08 → 'electric'
///   0x09 → 'petrol'  (Hybrid Gasoline — the combustion side is petrol)
///   0x0A → 'petrol'  (Hybrid Ethanol — close enough, default petrol)
///   0x0B → 'diesel'  (Hybrid Diesel)
///   0x0C → 'electric' (Hybrid Electric — predominantly electric)
///   0x0D → 'petrol'  (Hybrid mixed combustion-only)
///
/// Other / reserved / unknown codes return null so the caller falls back to
/// other signals.
String? fuelTypeCodeToProfileKey(int code) {
  switch (code) {
    case 0x01:
    case 0x09: // hybrid gasoline
    case 0x0A: // hybrid ethanol
    case 0x0D: // hybrid mixed
      return 'petrol';
    case 0x03: // ethanol / flexfuel — feeds the #3429 E85 blend constants
      return 'e85';
    case 0x04:
    case 0x0B: // hybrid diesel
      return 'diesel';
    case 0x05:
      return 'lpg';
    case 0x06:
      return 'cng';
    case 0x08:
    case 0x0C: // hybrid electric
      return 'electric';
    default:
      return null;
  }
}
