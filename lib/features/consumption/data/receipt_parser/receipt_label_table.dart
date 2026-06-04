// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Printed fuel-RECEIPT label table + classification for the receipt
/// label-anchored extractor (#2848).
///
/// Mirrors `ocr/_pump_label_table.dart` but with the receipt vocabulary,
/// where the labelling differs from a pump display:
///
///  * a fuel receipt prints the per-litre price under a bare **`Prix`**
///    (or `Prix/L`, `P.U.`) label — NOT the total — while the charged
///    amount is **`TOT TTC`** / `Total` / `Montant`. On the pump display
///    the bare `PRIX` is the total, so the two tables must stay distinct.
///  * volume is **`Volume`** / `Litres` / `Quantité`.
///
/// These are DATA values (the words printed on the paper receipt), never
/// user-facing ARB strings.
library;

import '../ocr/_pump_label_table.dart';

export '../ocr/_pump_label_table.dart' show PumpField, pumpFieldName;

/// A printed receipt label and the field it denotes, with a [weight] so
/// the disambiguator prefers the LONGEST / most-specific match per block
/// ("TOT TTC" outranks a bare "TTC"; "Prix" stays light so a Total label
/// never loses its row).
class ReceiptLabelDef {
  final RegExp pattern;
  final PumpField field;
  final int weight;
  const ReceiptLabelDef(this.pattern, this.field, this.weight);
}

/// Multi-locale fuel-receipt labels. On a receipt the bare `Prix` is the
/// per-litre price (the total is `TOT TTC` / `Total` / `Montant`), so it
/// carries the heaviest weight to claim its row before any lighter label.
final List<ReceiptLabelDef> kReceiptLabels = <ReceiptLabelDef>[
  // --- price per litre (most specific) -------------------------------
  ReceiptLabelDef(RegExp(r'prix\s*du\s*litre', caseSensitive: false),
      PumpField.pricePerLitre, 34),
  ReceiptLabelDef(RegExp(r'prix\s*unit', caseSensitive: false),
      PumpField.pricePerLitre, 34),
  ReceiptLabelDef(RegExp(r'prezzo\s*(?:unitario|al\s*litro)',
      caseSensitive: false), PumpField.pricePerLitre, 34),
  ReceiptLabelDef(RegExp(r'precio\s*por\s*litro', caseSensitive: false),
      PumpField.pricePerLitre, 34),
  ReceiptLabelDef(RegExp(r'(?:€|EUR)\s*/\s*l', caseSensitive: false),
      PumpField.pricePerLitre, 32),
  ReceiptLabelDef(RegExp(r'\bp\.?\s*u\.?\b', caseSensitive: false),
      PumpField.pricePerLitre, 32),
  ReceiptLabelDef(RegExp(r'literpreis', caseSensitive: false),
      PumpField.pricePerLitre, 32),
  // On a receipt the bare "Prix" is the per-litre price.
  ReceiptLabelDef(
      RegExp(r'\bprix\b', caseSensitive: false), PumpField.pricePerLitre, 30),
  // --- total amount --------------------------------------------------
  ReceiptLabelDef(RegExp(r'tot\.?\s*ttc', caseSensitive: false),
      PumpField.total, 24),
  ReceiptLabelDef(RegExp(r'total(?:e)?(?:\s*ttc)?', caseSensitive: false),
      PumpField.total, 22),
  ReceiptLabelDef(RegExp(r'montant(?:\s*(?:ttc|r[eé]el))?',
      caseSensitive: false), PumpField.total, 22),
  ReceiptLabelDef(RegExp(r'importo', caseSensitive: false), PumpField.total, 20),
  ReceiptLabelDef(RegExp(r'importe', caseSensitive: false), PumpField.total, 20),
  ReceiptLabelDef(RegExp(r'betra[gq]', caseSensitive: false), PumpField.total, 20),
  // --- volume --------------------------------------------------------
  ReceiptLabelDef(RegExp(r'volume', caseSensitive: false), PumpField.volume, 16),
  ReceiptLabelDef(RegExp(r'quantit[eéà]', caseSensitive: false),
      PumpField.volume, 16),
  ReceiptLabelDef(RegExp(r'litres?', caseSensitive: false), PumpField.volume, 14),
  ReceiptLabelDef(RegExp(r'litri', caseSensitive: false), PumpField.volume, 14),
  ReceiptLabelDef(RegExp(r'litros', caseSensitive: false), PumpField.volume, 14),
  ReceiptLabelDef(RegExp(r'menge', caseSensitive: false), PumpField.volume, 14),
];

/// Classifies [text] as a receipt label, returning the field of the
/// heaviest matching label so "TOT TTC" outranks a bare "Total" prefix
/// and the per-litre "Prix" never collides with the total (#2848). Null
/// when no label matches.
PumpField? classifyReceiptLabel(String text) {
  ReceiptLabelDef? best;
  for (final def in kReceiptLabels) {
    if (!def.pattern.hasMatch(text)) continue;
    if (best == null || def.weight > best.weight) best = def;
  }
  return best?.field;
}

/// Receipt-specific binding order weight (heaviest binds first). Mirrors
/// `pumpFieldWeight` but tuned for the receipt labelling where the bare
/// "Prix" is the per-litre price.
int receiptFieldWeight(PumpField field) {
  switch (field) {
    case PumpField.pricePerLitre:
      return 30;
    case PumpField.total:
      return 20;
    case PumpField.volume:
      return 14;
  }
}

/// `true` when [fullText] carries enough fuel-station markers to route a
/// receipt to the geometry-aware extractor instead of the generic
/// flat-string parser: a pump/volume/price marker AND a per-litre price
/// signal (a `€/L`-style token, OR both a `Prix`-family and a
/// `Volume`-family label so a column-aligned receipt with the units in a
/// separate block still routes). Deliberately conservative — anything
/// that doesn't look like a fuel-pump receipt stays on the generic path.
bool looksLikeFuelStationReceipt(String fullText) {
  final lower = fullText.toLowerCase();
  final hasPump =
      RegExp(r'\bpompe\b|\bpump\b|\bs[aä]ule\b|\bpista\b').hasMatch(lower);
  final hasVolume =
      RegExp(r'\bvolume\b|\bquantit|\blitres?\b|\blitri\b').hasMatch(lower);
  final hasPriceLabel =
      RegExp(r'\bprix\b|prix\s*unit|\bp\.?\s*u\.?\b|literpreis|prezzo')
          .hasMatch(lower);
  final hasPerLitreToken =
      RegExp(r'(?:€|eur)\s*/\s*l|/\s*l\b|€\s*\d').hasMatch(lower);

  final stationSignal = hasPump || hasVolume || hasPriceLabel;
  final priceSignal = hasPerLitreToken || (hasPriceLabel && hasVolume);
  return stationSignal && priceSignal;
}
