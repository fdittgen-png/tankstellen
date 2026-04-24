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
///
/// Also covers French ("PRIX"), Italian ("Importo"), Spanish ("Importe"),
/// and English ("Amount") labels — issue #948 surfaced French Tokheim
/// and Dresser Wayne pumps whose total-amount field is labelled
/// *PRIX* (not *Betrag*).
final List<RegExp> kBetragPatterns = <RegExp>[
  // "Betrag 58,42", "Betrag € 58,42", "Betrag: 58,42".
  RegExp(
      r'betra[gq]\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})',
      caseSensitive: false),
  // French: "PRIX 79,91 €", "Prix: 79,91".
  RegExp(r'prix\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})\b',
      caseSensitive: false),
  // Italian: "Importo 58,42".
  RegExp(r'importo\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})\b',
      caseSensitive: false),
  // Spanish: "Importe 58,42".
  RegExp(r'importe\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})\b',
      caseSensitive: false),
  // English: "Amount 58.42", "Amount $ 58.42".
  RegExp(r'amount\s*(?:€|EUR|\$)?\s*[:=]?\s*(\d+[.,]\d{2})\b',
      caseSensitive: false),
  RegExp(r'(?:€|EUR)\s*[:=]?\s*(\d+[.,]\d{2})\b'),
  RegExp(r'\b(\d+[.,]\d{2})\s*€\b'),
];

/// Matches "Abgabe 31,12", "Abgabe L 31,12", "Volume 31.12 L",
/// "Liter 31,12", and the "Ab9abe" / "Abqabe" misreads where a
/// small glyph is mistaken for 9 or q.
///
/// Also covers French ("VOLUME", "LITRES"), Italian ("Litri"),
/// Spanish ("Litros"), and English ("Liters") labels — issue #948
/// surfaced French Tokheim and Dresser Wayne displays where the
/// volume field is labelled *VOLUME* or suffixed with *LITRES*.
final List<RegExp> kAbgabePatterns = <RegExp>[
  // Allow an optional "L" or "Liter" unit between the label and
  // the number — some pumps render "Abgabe L 31,12" across two
  // visual rows and ML Kit flattens that into a single line.
  RegExp(
      r'ab[g9q]abe\s*(?:L|l|Liter)?\s*[:=]?\s*(\d+[.,]\d{1,3})',
      caseSensitive: false),
  RegExp(r'(?:volume|menge|quantit[eé])\s*[:=]?\s*(\d+[.,]\d{1,3})',
      caseSensitive: false),
  // French: "VOLUME: 36,06" (case-insensitive — pump labels are UPPERCASE).
  RegExp(r'volume\s*[:=]?\s*(\d+[.,]\d{1,3})\b', caseSensitive: false),
  // Italian: "Litri 31,65".
  RegExp(r'litri\s*[:=]?\s*(\d+[.,]\d{1,3})\b', caseSensitive: false),
  // Spanish: "Litros 31,65".
  RegExp(r'litros\s*[:=]?\s*(\d+[.,]\d{1,3})\b', caseSensitive: false),
  // English: "Liters 10.50" / "Liter 10.50".
  RegExp(r'liters?\s*[:=]?\s*(\d+[.,]\d{1,3})\b', caseSensitive: false),
  // "31,12 L" or "31.12 Liter" / "36,06 LITRES" — only when the
  // line has no € nearby (so we don't grab the Betrag by accident).
  RegExp(r'\b(\d+[.,]\d{1,3})\s*(?:L|l|Liter|Litres?|LITRES?|litres?)\b'),
];

/// Matches "Preis/Liter 1,849", "PREIS/L 1.849",
/// "CT / Preis/Liter 184,9" (cents-per-litre layout),
/// "1,849 €/L", "EUR/L 1.849".
///
/// Also covers French ("PRIX DU LITRE", "x,xxx €/L"), Italian
/// ("Prezzo al litro") and Spanish ("Precio por litro") variants —
/// issue #948 surfaced French Tokheim displays labelled
/// *PRIX DU LITRE*.
final List<RegExp> kPricePerLiterPatterns = <RegExp>[
  RegExp(
      r'preis\s*/?\s*(?:liter|l)\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  // French: "PRIX DU LITRE 2,216" / "prix du litre: 2,216".
  RegExp(
      r'prix\s*du\s*litre\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  // Italian: "Prezzo al litro 1,846".
  RegExp(
      r'prezzo\s*al\s*litro\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  // Spanish: "Precio por litro 1,846".
  RegExp(
      r'precio\s*por\s*litro\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  RegExp(r'(?:€|EUR)\s*/\s*(?:L|l|Liter|litre)\s*[:=]?\s*(\d+[.,]\d{2,3})',
      caseSensitive: false),
  RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/?\s*(?:L|l|Liter|litre)\b',
      caseSensitive: false),
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
