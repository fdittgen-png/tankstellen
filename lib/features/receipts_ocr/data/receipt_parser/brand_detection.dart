// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Brand-name heuristics that sit between the raw OCR lines and the
// per-layout parsers in `brand_layouts.dart`. Kept separate from the
// numeric field extractors so the brand string list is easy to grow
// without spilling into regex territory.

/// Returns a coarse brand key — `super_u`, `carrefour`, `total`, …, or
/// `null` when no known retailer is recognised anywhere in the receipt.
/// The key is used by `ReceiptParser.parse` to dispatch to brand-
/// specific extractors.
String? detectBrand(List<String> lines, String fullText) {
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
  // #2838 — Italian retailers (e-receipt phase 1). enilive is Eni's
  // forecourt brand; check it before the broader "eni" token so the more
  // specific name wins. Q8 / IP / Tamoil / Api round out the IT majors.
  if (haystack.contains('enilive')) return 'enilive';
  if (RegExp(r'\beni\b').hasMatch(haystack)) return 'eni';
  if (RegExp(r'\bq8\b').hasMatch(haystack)) return 'q8';
  if (RegExp(r'\bip\b').hasMatch(haystack)) return 'ip';
  if (haystack.contains('tamoil')) return 'tamoil';
  return null;
}

/// Try to find a station brand name in the first few lines.
String? extractStationName(List<String> lines) {
  const brands = [
    'total', 'totalenergies', 'shell', 'bp', 'aral', 'esso',
    'avia', 'jet', 'elf', 'agip', 'q8', 'omv', 'mol', 'orlen',
    'intermarché', 'intermarche', 'leclerc', 'carrefour', 'auchan',
    'super u', 'système u', 'systeme u', 'casino',
    // #2838 — Italian retailers (e-receipt phase 1).
    'enilive', 'eni', 'ip', 'tamoil', 'api',
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
