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
