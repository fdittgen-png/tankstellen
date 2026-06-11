// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../../core/domain/fuel_type.dart';
import '../ocr/pump_ocr_config.dart';
import 'receipt_currency_profile.dart';

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
  if (RegExp(r'diesel\s*premium|premium\s*diesel|gazole\s*premium|'
          r'gasolio\s*premium|hi\s*-?\s*q\s*diesel|excellium\s*diesel|'
          r'v[- ]?power\s*diesel')
      .hasMatch(lower)) {
    return FuelType.dieselPremium;
  }
  // #2838 — Italian e-receipts label diesel "Gasolio" (compound forms like
  // "Gasolio Auto", "Diesel+", "Blu Diesel" common on Eni/IP receipts).
  if (RegExp(r'\bdiesel\b|\bgazole\b|\bb7\b|\bgasolio\b').hasMatch(lower)) {
    return FuelType.diesel;
  }
  if (RegExp(r'\bgpl\b|\blpg\b').hasMatch(lower)) {
    return FuelType.lpg;
  }
  if (RegExp(r'\bgnv\b|\bcng\b|\bmetano\b').hasMatch(lower)) {
    return FuelType.cng;
  }
  // #2838 — Italian petrol is "Benzina" (E10 wasn't rolled out in IT for a
  // long time, so an unqualified "Benzina" is E5). A qualified "Benzina E10"
  // already matched the \be10\b branch above, so this only catches the bare
  // petrol label — kept LAST so the specific E5/E10/E85/E98 codes win first.
  if (RegExp(r'\bbenzina\b').hasMatch(lower)) {
    return FuelType.e5;
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
    // French thermal-print POS receipts (#1308): the italic lowercase
    // `l` (litre) glyph after the volume number is so faintly printed
    // that ML Kit OCR transcribes it as `?`, `|`, `i`, `t`, `j`, `P`,
    // or `1` — sometimes drops it entirely. Observed across multiple
    // brands (Super U Pomerols 2026-04-19, enilive Pezenas 2026-04-23)
    // so this is the French POS template, not brand-specific. The new
    // pattern fires AFTER the strict l/L/ℓ pattern so anything we can
    // read confidently is still preferred.
    //
    // Constraint: the number must have 2-3 decimals (fuel quantities
    // aren't printed with 0 or 1 decimal on these receipts). The
    // `(?!\d)` lookahead pins the decimals so `5.241` doesn't backtrack
    // to capture `5.24` and consume the trailing `1` as the unit char.
    // The `(?![A-Za-z0-9.,])` lookahead after the unit char ensures
    // we didn't grab the `t` from `thanks`, the `i` from `inclus`, or
    // the leading `1` of an adjacent decimal like `8,29  1,66` from
    // a Total H.T./TVA column block (real false-positive observed on
    // the TotalEnergies #801 fixture). The 0.1-300 L range guard at
    // the bottom of this function prunes the remaining false positives
    // (TVA percentages stay outside range).
    RegExp(r'(\d{1,3}[.,]\d{2,3})(?!\d)\s*[?|itjP1](?![A-Za-z0-9.,])'),
    // "VOLUME : 42.35" / "Volume: 42,35" / "Quantité = 5.27" / "Litri 38,42"
    // (#2838 — Italian e-receipts label the volume "Litri" / "Quantità").
    RegExp(
      r'(?:volume|quantit[eéà]|litri)\s*[:=]?\s*(\d{1,3}[.,]\d{1,3})',
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
/// #2273 — the currency is config-driven: an optional [profile] (the
/// active country's [OcrLocaleProfile], threaded from [PumpOcrConfig])
/// selects the major-unit symbols to match (`£`/`GBP`, `kr`/`DKK`,
/// `$`/`USD`, …). With no [profile] it defaults to EUR/€, so existing
/// French/German receipts parse exactly as before.
///
/// The labelled-amount fallback is only used when no explicit label
/// matches and the amount is NOT immediately followed by a per-litre
/// `/L` suffix — otherwise we would pick up the unit price as the total.
double? extractTotalCost(String text, {OcrLocaleProfile? profile}) {
  final currency = ReceiptCurrencyProfile.fromLocale(profile);
  final sym = currency.majorUnitPattern;

  final labelled = matchFirst(text, [
    // TOTAL / TOT TTC / MONTANT[ REEL / TTC] / TTC / German + Italian labels.
    // Accept ":" or "=" between label and amount, optional currency sym.
    // #2838 — Italian e-receipts label the charged amount "Importo" or
    // "Totale" (matched by the leading `total` alt). "Importo" is the
    // line-item value, "Totale"/"Totale documento" the document total.
    RegExp(
      r'(?:totale(?:\s*documento)?|total|tot\s*ttc|'
      r'montant(?:\s*(?:ttc|reel|r[eé]el))?|ttc|'
      r'betrag|summe|gesamt|importo)'
      '\\s*[:=]?\\s*(?:$sym)?\\s*(\\d+[.,]\\d+)',
      caseSensitive: false,
    ),
  ]);
  if (labelled != null) return labelled;

  // Heuristic fallback: gather every standalone amount attached to the
  // currency symbol that isn't a price-per-liter (no "/L" suffix), then
  // pick the LARGEST. Rationale: on a fuel receipt the unit price, tax,
  // and net all live around the total, but the total is almost always
  // the biggest number on the paper. Picking "first" grabs the
  // price-per-liter on column-layout receipts like Super U, where OCR
  // emits "€ 1.999/L ... € 10.47" — or even skips the "/L" suffix.
  final currencyPattern = RegExp(
    '(?:(?:$sym)\\s*(\\d+[.,]\\d+)|(\\d+[.,]\\d+)\\s*(?:$sym))'
    r'(\s*/\s*[lL])?',
    caseSensitive: false,
  );
  double? best;
  for (final match in currencyPattern.allMatches(text)) {
    if (match.group(3) != null) continue; // "/L" suffix → unit price
    final raw = match.group(1) ?? match.group(2);
    if (raw == null) continue;
    final value = parseDecimal(raw);
    if (value == null || value <= 0) continue;
    // Filter obvious non-totals: nobody's total is < 1, nobody's total
    // is > 10 000 (major units).
    if (value < 1 || value > 10000) continue;
    // #801 — a 3-decimal amount below the price ceiling (e.g. `1,990 €`,
    // `1.429 £`) is the fuel price-per-liter, never the total. Totals
    // are always 2-decimal. Use the currency's own price band so this
    // holds for GBP/kr/$ too, not just EUR.
    if (decimalDigitCount(raw) >= 3 && value <= currency.priceMax) continue;
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
///
/// #2273 — config-driven currency. An optional [profile] selects the
/// major-unit symbols AND the subunit convention, so a UK pence-per-litre
/// quote like `142.9p/L` or a US `c/L` cent quote is read and folded back
/// into the major unit (£1.429/L, $…/L). With no [profile] it defaults to
/// EUR/€, unchanged from before.
double? extractPricePerLiter(String text, {OcrLocaleProfile? profile}) {
  final currency = ReceiptCurrencyProfile.fromLocale(profile);
  final sym = currency.majorUnitPattern;

  // Subunit (pence/cents) per-litre takes priority — its explicit unit
  // marker (`p/L`, `c/L`) is the strongest signal and unambiguous.
  if (currency.hasMinorUnit) {
    final minorPrice = _extractMinorUnitPrice(text, currency);
    if (minorPrice != null) return minorPrice;
  }

  final labelled = matchFirst(text, [
    // "1.899 €/L" or "1,899 EUR/L" — also "1.999 €/ℓ" (U+2113).
    RegExp('(\\d+[.,]\\d{2,3})\\s*(?:$sym)\\s*/\\s*[lLℓ]', caseSensitive: false),
    // "€ 1.999/L" / "£ 1.429/L" — currency symbol before the number.
    RegExp('(?:$sym)\\s*(\\d+[.,]\\d{2,3})\\s*/\\s*[lLℓ]', caseSensitive: false),
    // Labels: PRIX/L, PU, Preis/L, Literpreis, Prix unit(.), Preis je
    // Liter, plus generic English "Unit price" / "Price/L". #2838 — Italian
    // e-receipts label the per-litre price "Prezzo unitario", "Prezzo/Litro"
    // or "Prezzo al litro". Also accepts `ℓ` in place of `l` in the
    // slash-L forms.
    RegExp(
      r'(?:prix\s*/\s*[lℓ]|prix\s*unit\.?|pu|preis\s*/\s*[lℓ]|'
      r'preis\s*je\s*liter|literpreis|unit\s*price|price\s*/\s*[lℓ]|'
      r'prezzo\s*(?:unitario|/\s*litro|al\s*litro))'
      '\\s*[:=]?\\s*(?:$sym)?\\s*(\\d+[.,]\\d{2,3})',
      caseSensitive: false,
    ),
  ]);
  if (labelled != null) return labelled;

  // #801 — TotalEnergies / independent French receipts often emit the
  // unit price as a bare `1,990 €` (3-decimal, no `/L` suffix) on the
  // line below a `QTY x FUELCODE` item line. 3 decimals + currency
  // symbol + a plausible per-litre range is a strong enough signal to
  // accept without the explicit `/L` marker. The negative lookahead for
  // `/L` keeps it from re-matching the labelled forms above. Range comes
  // from the currency profile so this holds for GBP/kr/$ too.
  final bareFuelPrice = RegExp(
    '(\\d+[.,]\\d{3})\\s*(?:$sym)(?!\\s*/\\s*[lLℓ])',
    caseSensitive: false,
  );
  for (final match in bareFuelPrice.allMatches(text)) {
    final raw = match.group(1);
    if (raw == null) continue;
    final value = parseDecimal(raw);
    if (value == null) continue;
    if (currency.priceInRange(value)) return value;
  }
  return null;
}

/// Reads a per-litre price quoted in the currency's SUBUNIT (UK pence
/// `142.9p/L`, US cents `c/L`) and folds it into the major unit by
/// dividing by [ReceiptCurrencyProfile.minorUnitDivisor]. Returns the
/// major-unit value (e.g. `142.9p/L` → `1.429`) when it falls in the
/// currency's plausible per-litre band, else null (#2273).
double? _extractMinorUnitPrice(String text, ReceiptCurrencyProfile currency) {
  final minor = currency.minorUnitPattern;
  // "142.9p/L", "142,9 p / L", "139.9 c/L" — subunit marker then /L.
  final pattern = RegExp(
    '(\\d+(?:[.,]\\d+)?)\\s*(?:$minor)\\s*/\\s*[lLℓ]',
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(text)) {
    final raw = match.group(1);
    if (raw == null) continue;
    final subunit = parseDecimal(raw);
    if (subunit == null || subunit <= 0) continue;
    final major = subunit / currency.minorUnitDivisor;
    if (currency.priceInRange(major)) return major;
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
