import 'package:flutter/foundation.dart';

import '../../../search/domain/entities/fuel_type.dart';

// Pure-function extractors shared by the generic matcher and the
// per-brand layouts. Kept top-level + stateless so they can be unit-
// tested and composed without instantiating `ReceiptParser`.
//
// Brand detection (brand key + station-name lookup) lives next door in
// `brand_detection.dart`.

/// Detect the fuel product code on the receipt. Supports European labels
/// like "SP95-E10", "Super E10", "E10", "Gazole", "Diesel", "E85",
/// "GPL", "GNV/CNG", etc.
///
/// French retailers (TotalEnergies, Intermarché) emit compound codes
/// with no separator — `SP95E5`, `SP95E10`, `SP98E5` — which the old
/// `sp95-e10` / `\be10\b` regexes missed because there was no word
/// boundary between the `5` and the `e10`. The compound forms now
/// have explicit patterns; order still matters (E10 before E5 before
/// E85 so longer codes win).
FuelType? extractFuelType(String text) {
  final lower = text.toLowerCase();
  // E85 first — "e85" contains "e5" as a substring-via-boundary edge
  // case on some OCR outputs where the 8 reads as 3 or falls out.
  if (RegExp(r'\be85\b|sp95\s*-?\s*e?\s*85|bio\s*[eé]thanol')
      .hasMatch(lower)) {
    return FuelType.e85;
  }
  // E10 — match compound (SP95E10, SP95-E10, SP95 E10) and standalone.
  if (RegExp(r'sp95\s*-?\s*e\s*10|sp95e10|\be10\b|super\s*e10')
      .hasMatch(lower)) {
    return FuelType.e10;
  }
  // E5 — SP95 without an E10 suffix, or compound SP95E5.
  if (RegExp(r'sp95\s*-?\s*e\s*5\b|sp95e5\b|\be5\b|sp95(?!\s*-?\s*e\s*10)|super\s*e5')
      .hasMatch(lower)) {
    return FuelType.e5;
  }
  if (RegExp(r'\be98\b|sp98|super\s*98').hasMatch(lower)) {
    return FuelType.e98;
  }
  if (RegExp(r'diesel\s*premium|premium\s*diesel|gazole\s*premium')
      .hasMatch(lower)) {
    return FuelType.dieselPremium;
  }
  if (RegExp(r'\bdiesel\b|\bgazole\b|\bb7\b').hasMatch(lower)) {
    return FuelType.diesel;
  }
  if (RegExp(r'\bgpl\b|\blpg\b').hasMatch(lower)) {
    return FuelType.lpg;
  }
  if (RegExp(r'\bgnv\b|\bcng\b').hasMatch(lower)) {
    return FuelType.cng;
  }
  return null;
}

/// Matches patterns like "42.35 L", "42,35 l", "42.35litres" (no
/// space, happens when OCR eats the separator), "VOLUME 42.35",
/// "Quantité = 5.27".
///
/// Filters pathological matches: the value must be in [0.1, 300] L,
/// the typical fill range for passenger cars (excludes things like
/// "20.00" from "TVA 20.00 %" or year fragments from a date).
double? extractLiters(String text) {
  final patterns = [
    // "42.35 L" / "42,35 l" / "5.24L" / "42.35 litres" / "5.24 ℓ".
    // The U+2113 script `ℓ` symbol is what French thermal printers
    // use for the litre unit — ML Kit OCR passes it through verbatim
    // and Latin-only [lL] silently misses it (user report 2026-04-20
    // on a Super U Pomerols receipt). The \b anchor is dropped for
    // ℓ because Dart regex treats the character as non-word, so the
    // original word boundary never held anyway.
    RegExp(r'(\d{1,3}[.,]\d{1,3})\s*(?:l(?:itres?)?\b|L\b|ℓ)'),
    // "VOLUME : 42.35" / "Volume: 42,35" / "Quantité = 5.27"
    RegExp(
      r'(?:volume|quantit[eé])\s*[:=]?\s*(\d{1,3}[.,]\d{1,3})',
      caseSensitive: false,
    ),
    // "5,00 x SP95E5" / "42,50 X GAZOLE" / "10,00 × SP98" — French
    // line-item format used by TotalEnergies, Intermarché and many
    // independents (user report 2026-04-21, #801). Fuel codes after
    // `x` are the French standard: SP95/SP98/E85/GAZOLE/GPL with
    // compound E5/E10 suffixes.
    RegExp(
      r'(\d{1,3}[.,]\d{1,3})\s*[xX×]\s*'
      r'(?:sp95e?5|sp95e10|sp98e?5|sp95|sp98|e85|gazole|gpl|gplc|b7|diesel|go)\b',
      caseSensitive: false,
    ),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(text)) {
      final value = parseDecimal(match.group(1)!);
      if (value != null && value > 0.1 && value < 300) return value;
    }
  }
  return null;
}

/// Matches patterns like "TOTAL 58.42", "MONTANT 58,42 EUR",
/// "TOT TTC 10.47", "MONTANT REEL : 10.69", "€ 58.42".
///
/// The generic `€ [amount]` fallback is only used when no explicit label
/// matches and the amount is NOT immediately followed by `/L` — otherwise
/// we would pick up the unit price as the total.
double? extractTotalCost(String text) {
  final labelled = matchFirst(text, [
    // TOTAL / TOT TTC / MONTANT[ REEL / TTC] / TTC / German labels.
    // Accept ":" or "=" between label and amount, optional €.
    RegExp(
      r'(?:total|tot\s*ttc|montant(?:\s*(?:ttc|reel|r[eé]el))?|ttc|'
      r'betrag|summe|gesamt)'
      r'\s*[:=]?\s*€?\s*(\d+[.,]\d+)',
      caseSensitive: false,
    ),
  ]);
  if (labelled != null) return labelled;

  // Heuristic fallback: gather every standalone amount attached to
  // €/EUR that isn't a price-per-liter (no "/L" suffix), then pick
  // the LARGEST. Rationale: on a fuel receipt the unit price, tax,
  // and net all live around the total, but the total is almost
  // always the biggest number on the paper. Picking "first" grabs
  // the price-per-liter on column-layout receipts like Super U,
  // where OCR emits "€ 1.999/L ... € 10.47" — or even skips the
  // "/L" suffix, so "first" becomes 1.999.
  final currencyPattern = RegExp(
    r'(?:€\s*(\d+[.,]\d+)|(\d+[.,]\d+)\s*(?:€|EUR))(\s*/\s*[lL])?',
  );
  double? best;
  for (final match in currencyPattern.allMatches(text)) {
    if (match.group(3) != null) continue; // "/L" suffix → unit price
    final raw = match.group(1) ?? match.group(2);
    if (raw == null) continue;
    final value = parseDecimal(raw);
    if (value == null || value <= 0) continue;
    // Filter obvious non-totals: nobody's total is < 1 €, nobody's
    // total is > 10 000 €.
    if (value < 1 || value > 10000) continue;
    // #801 — 3-decimal European amounts like `1,990 €` are fuel
    // price-per-liter, never totals. Without this guard on the
    // TotalEnergies receipt the parser grabbed `1,990 €` as the
    // total and the user saw 1.99 € in the form instead of 9.95 €.
    // Totals are always 2-decimal in EUR.
    if (decimalDigitCount(raw) >= 3 && value < 5) continue;
    if (best == null || value > best) best = value;
  }
  return best;
}

/// Count decimal digits in a European-formatted decimal string
/// (accepts `.` or `,` as separator). Returns 0 when no separator
/// is found. Used to distinguish 3-decimal fuel prices from
/// 2-decimal totals without trusting `double` precision.
int decimalDigitCount(String raw) {
  final sepIndex = raw.lastIndexOf(RegExp(r'[.,]'));
  if (sepIndex < 0) return 0;
  return raw.length - sepIndex - 1;
}

/// Matches price-per-liter: "1.899 €/L", "€ 1,999/L", "PU: 1,899",
/// "PRIX/L 1.899", "Prix unit. = 2,028 EUR", "Literpreis: 1.799".
double? extractPricePerLiter(String text) {
  final labelled = matchFirst(text, [
    // "1.899 €/L" or "1,899 EUR/L" — also "1.999 €/ℓ" (U+2113).
    RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*[lLℓ]'),
    // "€ 1.999/L" or "EUR 1,999/L" / "€ 1.999/ℓ" — currency before number.
    RegExp(r'(?:€|EUR)\s*(\d+[.,]\d{2,3})\s*/\s*[lLℓ]'),
    // Labels: PRIX/L, PU, Preis/L, Literpreis, Prix unit(.), Preis je Liter.
    // Also accepts `ℓ` in place of `l` in the slash-L forms.
    RegExp(
      r'(?:prix\s*/\s*[lℓ]|prix\s*unit\.?|pu|preis\s*/\s*[lℓ]|'
      r'preis\s*je\s*liter|literpreis)'
      r'\s*[:=]?\s*€?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false,
    ),
  ]);
  if (labelled != null) return labelled;

  // #801 — TotalEnergies / independent French receipts often emit
  // the unit price as a bare `1,990 €` (3-decimal digits, no `/L`
  // suffix) on the line below a `QTY x FUELCODE` item line. Without
  // this heuristic the amount was either missed entirely or grabbed
  // as the total. 3 decimal digits + euro suffix + plausible
  // fuel-price range (0.5-3.0 €/L) is a strong enough signal to
  // accept without the explicit `/L` marker.
  // Note on the lookbehind-free check: `\b` after `€` doesn't hold
  // (both `€` and a trailing space are non-word chars in Dart
  // regex, so no boundary sits between them). The negative
  // lookahead for `/L` is the only disambiguator we need — any
  // 3-decimal euro amount NOT followed by `/L` is the unit price.
  final bareFuelPrice =
      RegExp(r'(\d+[.,]\d{3})\s*(?:€|EUR)(?!\s*/\s*[lLℓ])');
  for (final match in bareFuelPrice.allMatches(text)) {
    final raw = match.group(1);
    if (raw == null) continue;
    final value = parseDecimal(raw);
    if (value == null) continue;
    if (value >= 0.5 && value <= 3.0) return value;
  }
  return null;
}

/// Matches common date formats: DD/MM/YYYY, DD.MM.YYYY, DD-MM-YYYY,
/// plus 2-digit-year variants like "19/04/26" (assumed 20xx).
///
/// Iterates all matches (not just the first) because phone numbers
/// like "04.67.77.29.10" look enough like `DD.MM.YY` that the first
/// match is often noise. The first match whose day + month pass the
/// calendar sanity check wins.
DateTime? extractDate(String text) {
  // 4-digit year — preferred when present.
  final fourDigit = RegExp(r'(\d{2})[/.\-](\d{2})[/.\-](\d{4})');
  for (final match in fourDigit.allMatches(text)) {
    final d = buildDate(match.group(1)!, match.group(2)!, match.group(3)!);
    if (d != null) return d;
  }
  // 2-digit year fallback — covers "19/04/26" on Carrefour receipts.
  final twoDigit =
      RegExp(r'(?<!\d)(\d{2})[/.\-](\d{2})[/.\-](\d{2})(?!\d)');
  for (final match in twoDigit.allMatches(text)) {
    final d = buildDate(
      match.group(1)!,
      match.group(2)!,
      '20${match.group(3)!}', // assume post-2000 for receipts
    );
    if (d != null) return d;
  }
  return null;
}

DateTime? buildDate(String dayStr, String monthStr, String yearStr) {
  try {
    final day = int.parse(dayStr);
    final month = int.parse(monthStr);
    final year = int.parse(yearStr);
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  } on FormatException catch (e, st) {
    debugPrint('Receipt date parse failed for "$dayStr/$monthStr/$yearStr": $e\n$st');
    return null;
  }
}

/// Returns the first successful captured group decimal across
/// [patterns], or null if none match.
double? matchFirst(String text, List<RegExp> patterns) {
  for (final pattern in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null && match.group(1) != null) {
      return parseDecimal(match.group(1)!);
    }
  }
  return null;
}

double? parseDecimal(String value) {
  final normalized = value.replaceAll(',', '.');
  return double.tryParse(normalized);
}
