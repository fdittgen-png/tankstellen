/// Regex patterns and lookup tables used by [PumpDisplayParser].
///
/// Centralised here so the parser class can stay focused on
/// orchestration. These patterns are intentionally conservative —
/// they match the German pump vocabulary and the most common
/// 7-segment OCR misreads, and nothing else.
library;

// ---------------------------------------------------------------------
// Labelled-extraction patterns
// ---------------------------------------------------------------------

/// Matches "Betrag 58,42", "Betrag € 58,42", "€ 58.42",
/// "EUR 58,42", and the common OCR misread "Betraq" where the
/// 'g' hook is thin.
final List<RegExp> kBetragPatterns = <RegExp>[
  // "Betrag 58,42", "Betrag € 58,42", "Betrag: 58,42".
  RegExp(
      r'betra[gq]\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})',
      caseSensitive: false),
  RegExp(r'(?:€|EUR)\s*[:=]?\s*(\d+[.,]\d{2})\b'),
  RegExp(r'\b(\d+[.,]\d{2})\s*€\b'),
];

/// Matches "Abgabe 31,12", "Abgabe L 31,12", "Volume 31.12 L",
/// "Liter 31,12", and the "Ab9abe" / "Abqabe" misreads where a
/// small glyph is mistaken for 9 or q.
final List<RegExp> kAbgabePatterns = <RegExp>[
  // Allow an optional "L" or "Liter" unit between the label and
  // the number — some pumps render "Abgabe L 31,12" across two
  // visual rows and ML Kit flattens that into a single line.
  RegExp(
      r'ab[g9q]abe\s*(?:L|l|Liter)?\s*[:=]?\s*(\d+[.,]\d{1,3})',
      caseSensitive: false),
  RegExp(r'(?:volume|menge|quantit[eé])\s*[:=]?\s*(\d+[.,]\d{1,3})',
      caseSensitive: false),
  // "31,12 L" or "31.12 Liter" — only when the line has no €
  // nearby (so we don't grab the Betrag by accident).
  RegExp(r'\b(\d+[.,]\d{1,3})\s*(?:L|l|Liter|Litres?)\b'),
];

/// Matches "Preis/Liter 1,849", "PREIS/L 1.849",
/// "CT / Preis/Liter 184,9" (cents-per-litre layout),
/// "1,849 €/L", "EUR/L 1.849".
final List<RegExp> kPricePerLiterPatterns = <RegExp>[
  RegExp(
      r'preis\s*/?\s*(?:liter|l)\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  RegExp(r'(?:€|EUR)\s*/\s*(?:L|l|Liter)\s*[:=]?\s*(\d+[.,]\d{2,3})'),
  RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*(?:L|l|Liter)'),
];

/// Cents-per-litre layout: "CT 184,9" means 184,9 ct = 1.849 €/L.
final RegExp kCentsPerLiterPattern =
    RegExp(r'\bCT\b\s*[:=]?\s*(\d{2,3}[.,]?\d?)', caseSensitive: false);

/// Matches a lone digit 1-9 on a line — the large pump-number glyph
/// printed on the cabinet.
final RegExp kLonePumpDigitPattern = RegExp(r'^[1-9]$');

/// Matches any decimal number inside a line (positional inference).
final RegExp kDecimalNumberPattern = RegExp(r'(\d+[.,]\d{1,3})');

/// Matches a numeric-ish token that might contain 7-segment
/// lookalike letters. Used by [normaliseDigits] to restrict
/// rewriting to plausible number tokens only.
final RegExp kNumericTokenPattern =
    RegExp(r'[0-9OoIlBSDZsdzbg]+(?:[.,][0-9OoIlBSDZsdzbg]+)*');

/// Single-char check for "this glyph could be a digit". Includes
/// real digits plus known 7-segment confusions.
final RegExp kDigitLookalikePattern = RegExp(r'^[0-9OoIlBSDZsdzbg]$');

// ---------------------------------------------------------------------
// Digit lookalike rewrite table
// ---------------------------------------------------------------------

/// Maps 7-segment OCR confusions back to their intended digit.
///
/// Only applied inside tokens that [isLikelyNumeric] already accepts,
/// so this table never corrupts German words like "Diesel" or "Super".
const Map<String, String> kDigitLookalikeMap = <String, String>{
  'O': '0', 'o': '0', 'D': '0',
  'I': '1', 'l': '1',
  'B': '8', 'b': '8',
  'S': '5', 's': '5',
  'Z': '2', 'z': '2',
  'g': '9',
};
