// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// OCR digit normalisation shared by the receipt parsers (#3765).
///
/// Extracted from the removed pump-display parser: the receipt spatial
/// parser's value tokenizer runs OCR'd number candidates through the
/// same "rewrite glyph lookalikes inside numeric tokens only" pass, so
/// `1O.SO` reads as `10.50` while words like "Diesel" are untouched.

/// Matches a numeric-ish token that might contain OCR lookalike
/// letters. Used by [normaliseDigits] to restrict rewriting to
/// plausible number tokens only.
final RegExp kNumericTokenPattern =
    RegExp(r'[0-9OoIlBSDZsdzbg]+(?:[.,][0-9OoIlBSDZsdzbg]+)*');

/// Single-char check for "this glyph could be a digit". Includes
/// real digits plus known OCR confusions.
final RegExp kDigitLookalikePattern = RegExp(r'^[0-9OoIlBSDZsdzbg]$');

/// Maps OCR digit confusions back to their intended digit.
///
/// Only applied inside tokens that [isLikelyNumeric] already accepts,
/// so this table never corrupts words like "Diesel" or "Super".
const Map<String, String> kDigitLookalikeMap = <String, String>{
  'O': '0', 'o': '0', 'D': '0',
  'I': '1', 'l': '1',
  'B': '8', 'b': '8',
  'S': '5', 's': '5',
  'Z': '2', 'z': '2',
  'g': '9',
};

/// Parses a decimal string that may use either "," or "." as the
/// decimal separator. Returns null on malformed input and emits a
/// debugPrint trace so silent swallow doesn't hide OCR bugs.
double? parseDecimalFromOcr(String value) {
  final n = double.tryParse(value.replaceAll(',', '.'));
  if (n == null) debugPrint('ReceiptParser: bad decimal "$value"');
  return n;
}

/// Rewrites common OCR digit confusions (O↔0, I/l↔1, B↔8, S↔5,
/// D↔0, Z↔2, g↔9) but ONLY inside tokens that look numeric by
/// construction. Non-numeric tokens like "Diesel" are left untouched
/// because they never match [kNumericTokenPattern] on their own.
String normaliseDigits(String text) {
  return text.replaceAllMapped(kNumericTokenPattern, (m) {
    final tok = m.group(0)!;
    if (!isLikelyNumeric(tok)) return tok;
    return rewriteDigitLookalikes(tok);
  });
}

/// A token is "likely numeric" if either
/// - it contains a decimal separator AND every non-separator char
///   is a digit or a known lookalike letter
///   (so `58,42`, `B.OO`, `1O.SO` all qualify); or
/// - it is a pure digit sequence.
///
/// This deliberately excludes single lookalike letters ("D") and
/// multi-letter tokens without a separator ("Diesel") so the
/// rewriter never corrupts words.
bool isLikelyNumeric(String token) {
  if (token.isEmpty) return false;
  if (!token.contains(RegExp(r'[.,]'))) {
    return RegExp(r'^\d+$').hasMatch(token);
  }
  final core = token.replaceAll(RegExp(r'[.,]'), '');
  if (core.isEmpty) return false;
  for (final ch in core.split('')) {
    if (!looksLikeDigit(ch)) return false;
  }
  return true;
}

/// Single-char predicate for [isLikelyNumeric]. Accepts digits plus
/// known OCR confusions.
bool looksLikeDigit(String ch) => kDigitLookalikePattern.hasMatch(ch);

/// Rewrites a single token using [kDigitLookalikeMap]. Assumes the
/// caller already confirmed the token is numeric — see
/// [isLikelyNumeric].
String rewriteDigitLookalikes(String token) {
  final sb = StringBuffer();
  for (final ch in token.split('')) {
    sb.write(kDigitLookalikeMap[ch] ?? ch);
  }
  return sb.toString();
}
