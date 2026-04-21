import 'package:flutter/foundation.dart';

import '../../search/domain/entities/fuel_type.dart';

/// Structured fields extracted from a fuel receipt by [ReceiptParser].
///
/// All fields are nullable because OCR is best-effort: any combination
/// may be missing depending on the receipt layout. Use [hasData] to check
/// whether the parser found anything actionable.
class ReceiptParseResult {
  /// Volume dispensed in litres, or `null` if no volume could be parsed.
  final double? liters;

  /// Total amount charged (currency is implicit — typically EUR).
  final double? totalCost;

  /// Unit price per litre as printed on the receipt.
  final double? pricePerLiter;

  /// Receipt date if a recognised format was found.
  final DateTime? date;

  /// Detected station brand (matched against a small built-in list).
  final String? stationName;

  /// Detected fuel type from the receipt, e.g. "SP95-E10" → [FuelType.e10].
  /// Null when the receipt doesn't name a recognisable product.
  final FuelType? fuelType;

  /// Brand layout the parser used — "super_u", "carrefour", or "generic".
  /// Exposed so tests and telemetry can verify dispatch went to the
  /// specialised branch when a well-known receipt layout is scanned.
  final String brandLayout;

  const ReceiptParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.date,
    this.stationName,
    this.fuelType,
    this.brandLayout = 'generic',
  });

  /// `true` when the parser extracted at least volume or total cost.
  bool get hasData => liters != null || totalCost != null;
}

/// Parses raw OCR text from a fuel station receipt into a
/// [ReceiptParseResult].
///
/// Dispatches to brand-aware rules when the first lines match a known
/// retailer (Super U, Carrefour today — more as we collect samples) and
/// falls back to a best-effort generic matcher otherwise. The generic
/// matcher covers common French / German layouts (TOTAL / MONTANT /
/// BETRAG + Volume / Quantité + Prix/L / Literpreis).
class ReceiptParser {
  const ReceiptParser();

  /// Parse OCR [text] from a fuel receipt and return the extracted fields.
  ///
  /// The result is always non-null; check [ReceiptParseResult.hasData] to
  /// know whether the parser recognised anything useful.
  ReceiptParseResult parse(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final fullText = lines.join(' ');

    final brand = _detectBrand(lines, fullText);
    final initial = switch (brand) {
      'super_u' => _parseSuperU(fullText, lines),
      'carrefour' => _parseCarrefour(fullText, lines),
      _ => _parseGeneric(fullText, lines),
    };
    return _reconcile(initial);
  }

  // ---------------------------------------------------------------------------
  // Cross-field reconciliation
  // ---------------------------------------------------------------------------

  /// Enforce the `liters × pricePerLiter ≈ totalCost` invariant. OCR
  /// routinely loses one of the three, and sometimes grabs the unit
  /// price as the total (the "2 €" vs "10.47 €" bug on a column-layout
  /// Super U receipt). Post-process so:
  ///
  /// - any two known values derive the third;
  /// - when all three are known but the product check disagrees by
  ///   more than 15 %, trust the PAIR that agrees (the two biggest
  ///   hints: total + pricePerLiter are most often correct from the
  ///   label regex, so liters gets recomputed);
  /// - nothing is overwritten when only one field is known.
  ReceiptParseResult _reconcile(ReceiptParseResult r) {
    final liters = r.liters;
    final total = r.totalCost;
    final ppl = r.pricePerLiter;

    // Fill in any single missing field from the other two.
    if (liters == null && total != null && ppl != null && ppl > 0) {
      return _copyWith(r, liters: _round(total / ppl, 2));
    }
    if (total == null && liters != null && ppl != null) {
      return _copyWith(r, totalCost: _round(liters * ppl, 2));
    }
    if (ppl == null && liters != null && total != null && liters > 0) {
      return _copyWith(r, pricePerLiter: _round(total / liters, 3));
    }

    // All three known: sanity-check their product. OCR's most common
    // mistake is grabbing the unit price as the total (€ 1.999 instead
    // of € 10.47), which blows this check by an order of magnitude.
    if (liters != null && total != null && ppl != null) {
      final expected = liters * ppl;
      if (expected > 0 && (total - expected).abs() / expected > 0.15) {
        // Trust the larger-signal pair. pricePerLiter comes from a
        // label with a "/L" marker — very reliable. liters comes from
        // an "X L" suffix — reliable too. Recompute the total.
        return _copyWith(r, totalCost: _round(expected, 2));
      }
    }
    return r;
  }

  ReceiptParseResult _copyWith(
    ReceiptParseResult r, {
    double? liters,
    double? totalCost,
    double? pricePerLiter,
  }) {
    return ReceiptParseResult(
      liters: liters ?? r.liters,
      totalCost: totalCost ?? r.totalCost,
      pricePerLiter: pricePerLiter ?? r.pricePerLiter,
      date: r.date,
      stationName: r.stationName,
      fuelType: r.fuelType,
      brandLayout: r.brandLayout,
    );
  }

  double _round(double value, int digits) {
    const pow10 = [1, 10, 100, 1000];
    final p = pow10[digits.clamp(0, pow10.length - 1)];
    return (value * p).round() / p;
  }

  // ---------------------------------------------------------------------------
  // Brand detection
  // ---------------------------------------------------------------------------

  /// Returns a coarse brand key — `super_u`, `carrefour`, `total`, …, or
  /// `null` when no known retailer is recognised in the first few lines
  /// or anywhere in the receipt. The key is used to dispatch to
  /// brand-specific extractors.
  String? _detectBrand(List<String> lines, String fullText) {
    final haystack = fullText.toLowerCase();
    if (haystack.contains('super u') || haystack.contains('système u') ||
        haystack.contains('systeme u')) {
      return 'super_u';
    }
    if (haystack.contains('carrefour')) return 'carrefour';
    if (haystack.contains('totalenergies') || haystack.contains('total ')) {
      return 'total';
    }
    if (haystack.contains('intermarché') || haystack.contains('intermarche')) {
      return 'intermarche';
    }
    if (haystack.contains('leclerc')) return 'leclerc';
    if (haystack.contains('shell')) return 'shell';
    if (haystack.contains('esso')) return 'esso';
    if (haystack.contains('aral')) return 'aral';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Brand-specific parsers
  // ---------------------------------------------------------------------------

  /// Super U / Système U layout. Labels observed on real receipts:
  ///   Volume   5.24 L
  ///   Prix     € 1.999/L
  ///   TOT TTC  € 10.47
  ReceiptParseResult _parseSuperU(String text, List<String> lines) {
    return ReceiptParseResult(
      liters: _extractLiters(text),
      totalCost: _matchFirst(text, [
        RegExp(r'tot\s*ttc\s*:?\s*€?\s*(\d+[.,]\d+)', caseSensitive: false),
        RegExp(r'total\s*ttc\s*:?\s*€?\s*(\d+[.,]\d+)',
            caseSensitive: false),
      ]) ?? _extractTotalCost(text),
      pricePerLiter: _extractPricePerLiter(text),
      date: _extractDate(text),
      stationName: _extractStationName(lines),
      fuelType: _extractFuelType(text),
      brandLayout: 'super_u',
    );
  }

  /// Carrefour / Carrefour Market / Carrefour Express layout. Observed:
  ///   No pompe    = 6
  ///   Carburant   = SP95
  ///   Quantite    = 5.27 L
  ///   Prix unit.  = 2,028 EUR
  ///   MONTANT REEL : 10.69 EUR
  ReceiptParseResult _parseCarrefour(String text, List<String> lines) {
    return ReceiptParseResult(
      liters: _matchFirst(text, [
        RegExp(r'quantit[eé]\s*[:=]\s*(\d+[.,]\d+)', caseSensitive: false),
      ]) ?? _extractLiters(text),
      totalCost: _matchFirst(text, [
        RegExp(r'montant\s*(?:reel|r[eé]el|ttc)?\s*[:=]?\s*€?\s*(\d+[.,]\d+)',
            caseSensitive: false),
      ]) ?? _extractTotalCost(text),
      pricePerLiter: _matchFirst(text, [
        RegExp(r'prix\s*unit\.?\s*[:=]?\s*€?\s*(\d+[.,]\d{2,3})',
            caseSensitive: false),
      ]) ?? _extractPricePerLiter(text),
      date: _extractDate(text),
      stationName: _extractStationName(lines),
      fuelType: _extractFuelType(text),
      brandLayout: 'carrefour',
    );
  }

  /// Generic fallback — everything that isn't a known retailer.
  ReceiptParseResult _parseGeneric(String text, List<String> lines) {
    return ReceiptParseResult(
      liters: _extractLiters(text),
      totalCost: _extractTotalCost(text),
      pricePerLiter: _extractPricePerLiter(text),
      date: _extractDate(text),
      stationName: _extractStationName(lines),
      fuelType: _extractFuelType(text),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared extractors
  // ---------------------------------------------------------------------------

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
  FuelType? _extractFuelType(String text) {
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
  double? _extractLiters(String text) {
    final patterns = [
      // "42.35 L" / "42,35 l" / "5.24L" / "42.35 litres" / "5.24 ℓ".
      // The U+2113 script `ℓ` symbol is what French thermal printers
      // use for the litre unit — ML Kit OCR passes it through verbatim
      // and Latin-only [lL] silently misses it (user report 2026-04-20
      // on a Super U Pomerols receipt). The \b anchor is dropped for
      // ℓ because Dart regex treats the character as non-word, so the
      // original word boundary never held anyway.
      RegExp(r'(\d{1,3}[.,]\d{1,3})\s*(?:l(?:itres?)?\b|L\b|\u2113)'),
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
        final value = _parseDecimal(match.group(1)!);
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
  double? _extractTotalCost(String text) {
    final labelled = _matchFirst(text, [
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
      final value = _parseDecimal(raw);
      if (value == null || value <= 0) continue;
      // Filter obvious non-totals: nobody's total is < 1 €, nobody's
      // total is > 10 000 €.
      if (value < 1 || value > 10000) continue;
      // #801 — 3-decimal European amounts like `1,990 €` are fuel
      // price-per-liter, never totals. Without this guard on the
      // TotalEnergies receipt the parser grabbed `1,990 €` as the
      // total and the user saw 1.99 € in the form instead of 9.95 €.
      // Totals are always 2-decimal in EUR.
      if (_decimalDigitCount(raw) >= 3 && value < 5) continue;
      if (best == null || value > best) best = value;
    }
    return best;
  }

  /// Count decimal digits in a European-formatted decimal string
  /// (accepts `.` or `,` as separator). Returns 0 when no separator
  /// is found. Used to distinguish 3-decimal fuel prices from
  /// 2-decimal totals without trusting `double` precision.
  int _decimalDigitCount(String raw) {
    final sepIndex = raw.lastIndexOf(RegExp(r'[.,]'));
    if (sepIndex < 0) return 0;
    return raw.length - sepIndex - 1;
  }

  /// Matches price-per-liter: "1.899 €/L", "€ 1,999/L", "PU: 1,899",
  /// "PRIX/L 1.899", "Prix unit. = 2,028 EUR", "Literpreis: 1.799".
  double? _extractPricePerLiter(String text) {
    final labelled = _matchFirst(text, [
      // "1.899 €/L" or "1,899 EUR/L" — also "1.999 €/ℓ" (U+2113).
      RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*[lL\u2113]'),
      // "€ 1.999/L" or "EUR 1,999/L" / "€ 1.999/ℓ" — currency before number.
      RegExp(r'(?:€|EUR)\s*(\d+[.,]\d{2,3})\s*/\s*[lL\u2113]'),
      // Labels: PRIX/L, PU, Preis/L, Literpreis, Prix unit(.), Preis je Liter.
      // Also accepts `ℓ` in place of `l` in the slash-L forms.
      RegExp(
        r'(?:prix\s*/\s*[l\u2113]|prix\s*unit\.?|pu|preis\s*/\s*[l\u2113]|'
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
      final value = _parseDecimal(raw);
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
  DateTime? _extractDate(String text) {
    // 4-digit year — preferred when present.
    final fourDigit = RegExp(r'(\d{2})[/.\-](\d{2})[/.\-](\d{4})');
    for (final match in fourDigit.allMatches(text)) {
      final d = _buildDate(match.group(1)!, match.group(2)!, match.group(3)!);
      if (d != null) return d;
    }
    // 2-digit year fallback — covers "19/04/26" on Carrefour receipts.
    final twoDigit =
        RegExp(r'(?<!\d)(\d{2})[/.\-](\d{2})[/.\-](\d{2})(?!\d)');
    for (final match in twoDigit.allMatches(text)) {
      final d = _buildDate(
        match.group(1)!,
        match.group(2)!,
        '20${match.group(3)!}', // assume post-2000 for receipts
      );
      if (d != null) return d;
    }
    return null;
  }

  DateTime? _buildDate(String dayStr, String monthStr, String yearStr) {
    try {
      final day = int.parse(dayStr);
      final month = int.parse(monthStr);
      final year = int.parse(yearStr);
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    } on FormatException catch (e) {
      debugPrint('Receipt date parse failed for "$dayStr/$monthStr/$yearStr": $e');
      return null;
    }
  }

  /// Try to find a station brand name in the first few lines.
  String? _extractStationName(List<String> lines) {
    const brands = [
      'total', 'totalenergies', 'shell', 'bp', 'aral', 'esso',
      'avia', 'jet', 'elf', 'agip', 'q8', 'omv', 'mol', 'orlen',
      'intermarché', 'intermarche', 'leclerc', 'carrefour', 'auchan',
      'super u', 'système u', 'systeme u', 'casino',
    ];

    for (final line in lines.take(5)) {
      final lower = line.toLowerCase().trim();
      for (final brand in brands) {
        // Match brand as a standalone word or the whole line
        if (lower == brand ||
            lower.startsWith('$brand ') ||
            lower.startsWith('$brand\t')) {
          return line;
        }
      }
    }
    return null;
  }

  /// Returns the first successful captured group decimal across
  /// [patterns], or null if none match.
  double? _matchFirst(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        return _parseDecimal(match.group(1)!);
      }
    }
    return null;
  }

  double? _parseDecimal(String value) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
