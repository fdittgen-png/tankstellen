import 'package:flutter/foundation.dart';

import '_pump_display_patterns.dart';

/// A single decimal number lifted out of an OCR'd pump-display line.
///
/// Tracks its magnitude ([value]), the number of decimal places seen
/// ([decimals] — 3 suggests price-per-litre, 2 suggests total/litres),
/// and the [line] it came from for diagnostics.
@immutable
class PumpDisplayCandidate {
  final double value;
  final int decimals;
  final String line;
  const PumpDisplayCandidate({
    required this.value,
    required this.decimals,
    required this.line,
  });
}

/// Output of positional inference — the three fields that the parser
/// could recover from raw numeric ordering when labelled extraction
/// didn't catch them.
@immutable
class PumpDisplayInferredTriple {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;
  const PumpDisplayInferredTriple({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
  });

  static const empty = PumpDisplayInferredTriple();
}

/// Parses a decimal string that may use either "," or "." as the
/// decimal separator. Returns null on malformed input and emits a
/// debugPrint trace so silent swallow doesn't hide OCR bugs.
double? parseDecimalFromOcr(String value) {
  final n = double.tryParse(value.replaceAll(',', '.'));
  if (n == null) debugPrint('PumpDisplayParser: bad decimal "$value"');
  return n;
}

/// Rewrites common 7-segment OCR confusions (O↔0, I/l↔1, B↔8, S↔5,
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
///   is a digit or a known 7-segment lookalike letter
///   (so `58,42`, `B.OO`, `1O.SO` all qualify); or
/// - it is a pure digit sequence (catches the bare pump number
///   like "8" on its own line).
///
/// This deliberately excludes single lookalike letters ("D") and
/// multi-letter tokens without a separator ("Diesel") so the
/// rewriter never corrupts German words.
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
/// known 7-segment confusions.
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

/// Scores the parser output in [0, 1]. +0.3 per extracted primary
/// field; +0.1 bonus when all three are internally consistent
/// (|liters * price - total| <= 0.02); +0.05 when they're close
/// but off by at most 10 cents.
double scorePumpDisplayConfidence({
  required double? total,
  required double? liters,
  required double? price,
}) {
  var score = 0.0;
  if (total != null) score += 0.3;
  if (liters != null) score += 0.3;
  if (price != null) score += 0.3;
  if (total != null && liters != null && price != null) {
    final predicted = liters * price;
    final delta = (predicted - total).abs();
    if (delta <= 0.02) {
      score += 0.1;
    } else if (delta <= 0.10) {
      score += 0.05;
    }
  }
  return score.clamp(0.0, 1.0);
}
