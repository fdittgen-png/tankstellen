// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Printed pump-label table + classification for the label-anchored
/// extractor (#2478).
///
/// Split out of `label_anchored_extractor.dart` so the extractor file
/// stays focused on geometry / anchoring and keeps under the 400-line
/// norm. These are DATA values (the words printed on the physical pump),
/// never user-facing ARB strings.
library;

/// Which transaction field a printed label denotes.
enum PumpField { total, volume, pricePerLitre }

/// A printed pump label and the field it denotes, with a [weight] so the
/// disambiguator prefers the LONGEST / most-specific match per block
/// ("PRIX DU LITRE" outranks the bare "PRIX" prefix → the #2478 root bug
/// where the unit price was swallowed by the total label).
class PumpLabelDef {
  final RegExp pattern;
  final PumpField field;
  final int weight;
  const PumpLabelDef(this.pattern, this.field, this.weight);
}

/// Canonical per-field weight, also used to order label binding so the
/// unit-price label claims its number before the bare total label.
int pumpFieldWeight(PumpField field) {
  switch (field) {
    case PumpField.pricePerLitre:
      return 30;
    case PumpField.volume:
      return 12;
    case PumpField.total:
      return 8;
  }
}

/// Maps a [PumpField] to the [PumpDisplayParseResult.derived] field-name
/// key (`'totalCost'` / `'liters'` / `'pricePerLiter'`).
String pumpFieldName(PumpField field) {
  switch (field) {
    case PumpField.total:
      return 'totalCost';
    case PumpField.volume:
      return 'liters';
    case PumpField.pricePerLitre:
      return 'pricePerLiter';
  }
}

/// Multi-locale pump labels. The unit-price labels carry the heaviest
/// weight so a block reading "PRIX DU LITRE" is never mis-claimed as the
/// bare-PRIX total — the exact collision that dropped the unit price.
final List<PumpLabelDef> kPumpLabels = <PumpLabelDef>[
  // --- price per litre (most specific) -------------------------------
  PumpLabelDef(RegExp(r'prix\s*du\s*litre', caseSensitive: false),
      PumpField.pricePerLitre, 30),
  PumpLabelDef(RegExp(r'prezzo\s*al\s*litro', caseSensitive: false),
      PumpField.pricePerLitre, 30),
  PumpLabelDef(RegExp(r'precio\s*por\s*litro', caseSensitive: false),
      PumpField.pricePerLitre, 30),
  PumpLabelDef(RegExp(r'preis\s*/?\s*liter', caseSensitive: false),
      PumpField.pricePerLitre, 30),
  PumpLabelDef(RegExp(r'price\s*/?\s*litre', caseSensitive: false),
      PumpField.pricePerLitre, 30),
  PumpLabelDef(RegExp(r'(?:€|EUR)\s*/\s*l', caseSensitive: false),
      PumpField.pricePerLitre, 20),
  // --- volume --------------------------------------------------------
  PumpLabelDef(RegExp(r'volume', caseSensitive: false), PumpField.volume, 12),
  PumpLabelDef(RegExp(r'litres?', caseSensitive: false), PumpField.volume, 10),
  PumpLabelDef(RegExp(r'litri', caseSensitive: false), PumpField.volume, 10),
  PumpLabelDef(RegExp(r'litros', caseSensitive: false), PumpField.volume, 10),
  PumpLabelDef(
      RegExp(r'ab[g9q]abe', caseSensitive: false), PumpField.volume, 12),
  PumpLabelDef(RegExp(r'menge', caseSensitive: false), PumpField.volume, 10),
  // --- total amount (bare PRIX is LIGHTEST) --------------------------
  PumpLabelDef(RegExp(r'betra[gq]', caseSensitive: false), PumpField.total, 8),
  PumpLabelDef(RegExp(r'importo', caseSensitive: false), PumpField.total, 8),
  PumpLabelDef(RegExp(r'importe', caseSensitive: false), PumpField.total, 8),
  PumpLabelDef(RegExp(r'amount', caseSensitive: false), PumpField.total, 8),
  PumpLabelDef(RegExp(r'prix', caseSensitive: false), PumpField.total, 4),
];

/// Classifies [text] as a label, returning the field of the LONGEST /
/// heaviest matching label so "PRIX DU LITRE" outranks the bare "PRIX"
/// prefix in the same block (#2478). Null when no label matches.
PumpField? classifyPumpLabel(String text) {
  PumpLabelDef? best;
  for (final def in kPumpLabels) {
    if (!def.pattern.hasMatch(text)) continue;
    if (best == null || def.weight > best.weight) best = def;
  }
  return best?.field;
}
