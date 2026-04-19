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
    return switch (brand) {
      'super_u' => _parseSuperU(fullText, lines),
      'carrefour' => _parseCarrefour(fullText, lines),
      _ => _parseGeneric(fullText, lines),
    };
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
  FuelType? _extractFuelType(String text) {
    final lower = text.toLowerCase();
    // Order matters: e10 before e5 so "e10" doesn't slip through as "e".
    if (RegExp(r'\be10\b|sp95-e10|super\s*e10').hasMatch(lower)) {
      return FuelType.e10;
    }
    if (RegExp(r'\be5\b|sp95(?!\s*-?e10)|super\s*e5').hasMatch(lower)) {
      return FuelType.e5;
    }
    if (RegExp(r'\be98\b|sp98|super\s*98').hasMatch(lower)) {
      return FuelType.e98;
    }
    if (RegExp(r'\be85\b|bio\s*[eé]thanol').hasMatch(lower)) {
      return FuelType.e85;
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

  /// Matches patterns like "42.35 L", "42,35 l", "42.35 litres",
  /// "VOLUME 42.35", "Quantité = 5.27".
  double? _extractLiters(String text) {
    final patterns = [
      // "42.35 L" or "42,35 l" or "42.35 litres"
      RegExp(r'(\d+[.,]\d+)\s*(?:l(?:itres?)?|L)\b'),
      // "VOLUME : 42.35" / "Volume: 42,35" / "Quantité = 5.27"
      RegExp(
        r'(?:volume|quantit[eé])\s*[:=]?\s*(\d+[.,]\d+)',
        caseSensitive: false,
      ),
    ];
    return _matchFirst(text, patterns);
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

    // Fallback: first standalone amount attached to €/EUR that is NOT a
    // price-per-liter (no "/l" right after).
    final currencyPattern = RegExp(
      r'(?:€\s*(\d+[.,]\d+)|(\d+[.,]\d+)\s*(?:€|EUR))(\s*/\s*[lL])?',
    );
    for (final match in currencyPattern.allMatches(text)) {
      if (match.group(3) != null) continue; // "/L" suffix → price-per-liter
      final value = match.group(1) ?? match.group(2);
      if (value != null) return _parseDecimal(value);
    }
    return null;
  }

  /// Matches price-per-liter: "1.899 €/L", "€ 1,999/L", "PU: 1,899",
  /// "PRIX/L 1.899", "Prix unit. = 2,028 EUR", "Literpreis: 1.799".
  double? _extractPricePerLiter(String text) {
    return _matchFirst(text, [
      // "1.899 €/L" or "1,899 EUR/L"
      RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*[lL]'),
      // "€ 1.999/L" or "EUR 1,999/L" — currency before number
      RegExp(r'(?:€|EUR)\s*(\d+[.,]\d{2,3})\s*/\s*[lL]'),
      // Labels: PRIX/L, PU, Preis/L, Literpreis, Prix unit(.), Preis je Liter
      RegExp(
        r'(?:prix\s*/\s*l|prix\s*unit\.?|pu|preis\s*/\s*l|'
        r'preis\s*je\s*liter|literpreis)'
        r'\s*[:=]?\s*€?\s*(\d+[.,]\d{2,3})',
        caseSensitive: false,
      ),
    ]);
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
