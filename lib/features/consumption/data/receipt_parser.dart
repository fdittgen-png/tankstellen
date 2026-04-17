import 'package:flutter/foundation.dart';

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

  const ReceiptParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.date,
    this.stationName,
  });

  /// `true` when the parser extracted at least volume or total cost.
  bool get hasData => liters != null || totalCost != null;
}

/// Parses raw OCR text from a fuel station receipt into a
/// [ReceiptParseResult].
///
/// Supports common French and German receipt layouts. The matchers
/// tolerate decimal commas/dots and the most frequent label variants
/// (`TOTAL`, `MONTANT`, `BETRAG`, `Volume`, `Prix/L`, etc.).
class ReceiptParser {
  const ReceiptParser();

  /// Parse OCR [text] from a fuel receipt and return the extracted fields.
  ///
  /// The result is always non-null; check [ReceiptParseResult.hasData] to
  /// know whether the parser recognised anything useful.
  ReceiptParseResult parse(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final fullText = lines.join(' ');

    return ReceiptParseResult(
      liters: _extractLiters(fullText),
      totalCost: _extractTotalCost(fullText),
      pricePerLiter: _extractPricePerLiter(fullText),
      date: _extractDate(fullText),
      stationName: _extractStationName(lines),
    );
  }

  /// Matches patterns like "42.35 L", "42,35 l", "42.35 litres", "VOLUME 42.35"
  double? _extractLiters(String text) {
    final patterns = [
      // "42.35 L" or "42,35 l" or "42.35 litres"
      RegExp(r'(\d+[.,]\d+)\s*(?:l(?:itres?)?|L)\b'),
      // "VOLUME : 42.35" or "Volume: 42,35"
      RegExp(r'(?:volume|quantit[eé])\s*:?\s*(\d+[.,]\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseDecimal(match.group(1)!);
      }
    }
    return null;
  }

  /// Matches patterns like "TOTAL 58.42", "MONTANT 58,42 EUR", "€ 58.42"
  double? _extractTotalCost(String text) {
    final patterns = [
      // "TOTAL: 58.42" or "TOTAL 58,42 EUR"
      RegExp(r'(?:total|montant|betrag|summe|gesamt)\s*:?\s*(\d+[.,]\d+)', caseSensitive: false),
      // "€ 58.42" or "58.42 €" or "58.42 EUR"
      RegExp(r'€\s*(\d+[.,]\d+)|(\d+[.,]\d+)\s*(?:€|EUR)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1) ?? match.group(2);
        if (value != null) return _parseDecimal(value);
      }
    }
    return null;
  }

  /// Matches patterns like "1.899 €/L", "PU: 1,899", "PRIX/L 1.899"
  double? _extractPricePerLiter(String text) {
    final patterns = [
      // "1.899 €/L" or "1,899 EUR/L"
      RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*[lL]'),
      // "PRIX/L: 1.899" or "PU: 1,899" or "Preis/L: 1.899"
      RegExp(r'(?:prix\s*/\s*l|pu|preis\s*/\s*l|literpreis)\s*:?\s*(\d+[.,]\d{2,3})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _parseDecimal(match.group(1)!);
      }
    }
    return null;
  }

  /// Matches common date formats: DD/MM/YYYY, DD.MM.YYYY, DD-MM-YYYY
  DateTime? _extractDate(String text) {
    final pattern = RegExp(r'(\d{2})[/.\-](\d{2})[/.\-](\d{4})');
    final match = pattern.firstMatch(text);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      } on FormatException catch (e) {
        debugPrint('Receipt date parse failed for "${match.group(0)}": $e');
      }
    }
    return null;
  }

  /// Try to find a station brand name in the first few lines.
  String? _extractStationName(List<String> lines) {
    const brands = [
      'total', 'totalenergies', 'shell', 'bp', 'aral', 'esso',
      'avia', 'jet', 'elf', 'agip', 'q8', 'omv', 'mol', 'orlen',
      'intermarché', 'intermarche', 'leclerc', 'carrefour', 'auchan',
      'super u', 'système u', 'casino',
    ];

    for (final line in lines.take(5)) {
      final lower = line.toLowerCase().trim();
      for (final brand in brands) {
        // Match brand as a standalone word or the whole line
        if (lower == brand || lower.startsWith('$brand ') || lower.startsWith('$brand\t')) {
          return line;
        }
      }
    }
    return null;
  }

  double? _parseDecimal(String value) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
