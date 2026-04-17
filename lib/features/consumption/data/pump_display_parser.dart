import 'package:flutter/foundation.dart';

/// Fields extracted from a fuel pump display (the 7-segment / LCD
/// panel on the pump itself, NOT the paper receipt).
///
/// All fields are nullable because OCR is best-effort: bright
/// sunlight, glare, a partially-visible display, or an unfamiliar
/// layout can all blank a field. Use [hasUsableData] to decide
/// whether the result is worth prefilling a form with.
class PumpDisplayParseResult {
  /// Volume dispensed in litres (the "Abgabe" / "Volume" line).
  final double? liters;

  /// Total amount charged on the pump (the "Betrag" / "€" line).
  final double? totalCost;

  /// Unit price per litre as shown on the pump (the "Preis/Liter" /
  /// "€/L" line). This is typically 3-decimal precision (e.g. 1.849).
  final double? pricePerLiter;

  /// Pump number printed or displayed on the housing (e.g. "3" in a
  /// large standalone digit on the cabinet). Optional — helps the
  /// user confirm which pump they scanned.
  final int? pumpNumber;

  /// Confidence ∈ [0, 1] based on how many of the three primary
  /// fields were extracted AND whether they are internally consistent
  /// (totalCost ≈ liters * pricePerLiter within tolerance).
  final double confidence;

  const PumpDisplayParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.pumpNumber,
    this.confidence = 0,
  });

  /// `true` when the parser extracted at least two of the three
  /// primary numeric fields. One alone (e.g. just a total) is rarely
  /// enough to auto-fill a fill-up log.
  bool get hasUsableData {
    final count = [liters, totalCost, pricePerLiter]
        .where((v) => v != null)
        .length;
    return count >= 2;
  }

  /// `true` when totalCost, liters and pricePerLiter are all present
  /// AND they satisfy `totalCost ≈ liters * pricePerLiter` within a
  /// small rounding tolerance. The three-way agreement is the
  /// strongest signal that OCR actually read the right numbers.
  bool get isConsistent {
    if (liters == null || totalCost == null || pricePerLiter == null) {
      return false;
    }
    final predicted = liters! * pricePerLiter!;
    final delta = (predicted - totalCost!).abs();
    // Pump displays round to the cent. A 2 cent tolerance covers
    // the rounding plus small OCR jitter on the last digit.
    return delta <= 0.02;
  }
}

/// Parses raw OCR text from a fuel pump 7-segment / LCD display.
///
/// Separate from [ReceiptParser] because the signal is different:
/// the pump display shows three unlabelled (or German-labelled)
/// numbers in fixed layout, not prose. The dedicated parser:
///
/// 1. Normalises common 7-segment OCR confusions (O↔0, I/l↔1,
///    B↔8, S↔5, D↔0) on digit-context strings only.
/// 2. Tries German pump labels first (Betrag, Abgabe, Preis/Liter,
///    Preis/L) and their likely OCR mis-reads (Betraq, Ab9abe,
///    Preis / L, Pre1s/L).
/// 3. Falls back to a positional heuristic: a pump display is three
///    numbers whose magnitudes fall into distinct ranges — total
///    cost and volume are typically two-digit, price-per-litre is
///    1.x to 2.x. That lets us disambiguate when labels are gone.
/// 4. Optionally cross-checks the three values for internal
///    consistency and exposes a [confidence] score, so callers can
///    choose to auto-fill only when the read is strongly corroborated.
class PumpDisplayParser {
  const PumpDisplayParser();

  PumpDisplayParseResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const PumpDisplayParseResult();
    }

    final normalised = _normaliseDigits(rawText);
    final lines = normalised
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final flat = lines.join(' ');

    double? total = _extractBetrag(flat);
    double? liters = _extractAbgabe(flat);
    double? price = _extractPricePerLiter(flat);

    // If labelled extraction missed some, try positional inference
    // from the raw numeric candidates. This rescues layouts where
    // the labels didn't OCR cleanly (e.g. photo with glare on the
    // text but the digits visible). Pass the values we already
    // claimed so the inferred step does not re-assign them.
    if (total == null || liters == null || price == null) {
      final claimed = <double>[
        ?total,
        ?liters,
        ?price,
      ];
      final inferred = _inferFromNumericOrder(lines, exclude: claimed);
      total ??= inferred.totalCost;
      liters ??= inferred.liters;
      price ??= inferred.pricePerLiter;
    }

    final pump = _extractPumpNumber(rawText, lines);
    final confidence = _scoreConfidence(
      total: total,
      liters: liters,
      price: price,
    );

    return PumpDisplayParseResult(
      totalCost: total,
      liters: liters,
      pricePerLiter: price,
      pumpNumber: pump,
      confidence: confidence,
    );
  }

  // ---------------------------------------------------------------------
  // Labelled extraction
  // ---------------------------------------------------------------------

  /// Matches "Betrag 58,42", "Betrag € 58,42", "€ 58.42",
  /// "EUR 58,42", and the common OCR misread "Betraq" where the
  /// 'g' hook is thin.
  double? _extractBetrag(String text) {
    final patterns = <RegExp>[
      // "Betrag 58,42", "Betrag € 58,42", "Betrag: 58,42".
      RegExp(
          r'betra[gq]\s*(?:€|EUR)?\s*[:=]?\s*(\d+[.,]\d{2})',
          caseSensitive: false),
      RegExp(r'(?:€|EUR)\s*[:=]?\s*(\d+[.,]\d{2})\b'),
      RegExp(r'\b(\d+[.,]\d{2})\s*€\b'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final value = _parseDecimal(m.group(1)!);
        if (value != null && value >= 0 && value < 10000) return value;
      }
    }
    return null;
  }

  /// Matches "Abgabe 31,12", "Abgabe L 31,12", "Volume 31.12 L",
  /// "Liter 31,12", and the "Ab9abe" / "Abqabe" misreads where a
  /// small glyph is mistaken for 9 or q.
  double? _extractAbgabe(String text) {
    final patterns = <RegExp>[
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
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        // Skip if this looks like a price/litre (has "€" right after).
        final tail = text.substring(m.end);
        if (tail.trimLeft().startsWith('€') ||
            tail.trimLeft().toLowerCase().startsWith('eur')) {
          continue;
        }
        final value = _parseDecimal(m.group(1)!);
        if (value != null && value >= 0 && value < 2000) return value;
      }
    }
    return null;
  }

  /// Matches "Preis/Liter 1,849", "PREIS/L 1.849",
  /// "CT / Preis/Liter 184,9" (cents-per-litre layout),
  /// "1,849 €/L", "EUR/L 1.849".
  double? _extractPricePerLiter(String text) {
    final patterns = <RegExp>[
      RegExp(
          r'preis\s*/?\s*(?:liter|l)\s*[:=]?\s*(\d+[.,]\d{2,3})',
          caseSensitive: false),
      RegExp(r'(?:€|EUR)\s*/\s*(?:L|l|Liter)\s*[:=]?\s*(\d+[.,]\d{2,3})'),
      RegExp(r'(\d+[.,]\d{2,3})\s*(?:€|EUR)\s*/\s*(?:L|l|Liter)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final value = _parseDecimal(m.group(1)!);
        if (value != null && value > 0 && value < 10) return value;
      }
    }
    // Cents-per-litre layout: "CT 184,9" means 184,9 ct = 1.849 €/L.
    final ctMatch =
        RegExp(r'\bCT\b\s*[:=]?\s*(\d{2,3}[.,]?\d?)', caseSensitive: false)
            .firstMatch(text);
    if (ctMatch != null) {
      final ct = _parseDecimal(ctMatch.group(1)!);
      if (ct != null && ct >= 80 && ct <= 400) {
        return ct / 100.0;
      }
    }
    return null;
  }

  /// Looks for a large standalone digit on the pump housing (1-9).
  /// These photos typically show the pump number as the biggest
  /// digit on the cabinet, which OCR picks up as an isolated
  /// short token. We only accept it when it's clearly isolated —
  /// part of a longer number is not a pump id.
  int? _extractPumpNumber(String rawText, List<String> lines) {
    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^[1-9]$').hasMatch(trimmed)) {
        return int.parse(trimmed);
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Positional inference
  // ---------------------------------------------------------------------

  /// When labelled extraction missed a field, scan all decimal
  /// numbers on the display and bucket them by magnitude:
  ///
  /// - Price per litre: strictly in (0, 5) with 3 decimals preferred.
  /// - Litres: typically (0, 200) with 1-2 decimals.
  /// - Total: typically (0, 500) with 2 decimals.
  ///
  /// This is deliberately conservative — when buckets overlap (e.g.
  /// a small fill-up of €1.80 could look like a price-per-litre),
  /// we leave the field null rather than guessing wrong.
  _InferredTriple _inferFromNumericOrder(
    List<String> lines, {
    List<double> exclude = const [],
  }) {
    final rawNumbers = <_Candidate>[];
    for (final line in lines) {
      for (final m in RegExp(r'(\d+[.,]\d{1,3})').allMatches(line)) {
        final v = _parseDecimal(m.group(1)!);
        if (v == null) continue;
        final decimals = m.group(1)!.contains(',') || m.group(1)!.contains('.')
            ? m.group(1)!.split(RegExp(r'[.,]')).last.length
            : 0;
        rawNumbers.add(_Candidate(value: v, decimals: decimals, line: line));
      }
    }
    // Consume `exclude` once per occurrence so duplicate values
    // (e.g. the pump reading 0.00 on every line at idle) are not
    // all wiped out by the first match.
    final toSkip = List<double>.from(exclude);
    final numbers = <_Candidate>[];
    for (final c in rawNumbers) {
      final idx = toSkip.indexWhere((e) => (e - c.value).abs() < 1e-6);
      if (idx >= 0) {
        toSkip.removeAt(idx);
      } else {
        numbers.add(c);
      }
    }
    if (numbers.isEmpty) return const _InferredTriple();

    _Candidate? price;
    _Candidate? liters;
    _Candidate? total;

    // Price-per-litre: smallest value in (0.5, 5) with 3 decimals.
    final priceCandidates = numbers
        .where((c) => c.value > 0.5 && c.value < 5 && c.decimals >= 2)
        .toList();
    priceCandidates.sort((a, b) => a.decimals == b.decimals
        ? a.value.compareTo(b.value)
        : b.decimals.compareTo(a.decimals));
    if (priceCandidates.isNotEmpty) price = priceCandidates.first;

    // Remaining 2-decimal candidates become the (liters, total)
    // pair. When price is known, prefer the ordering where
    // `liters * price ≈ total` — that's the strongest cross-check
    // the display gives us. With no price to anchor on, fall back
    // to magnitude ordering: liters < total is the usual case,
    // since prices > 1 €/L.
    final twoDecimals = numbers
        .where((c) =>
            c != price && c.decimals == 2 && c.value >= 0 && c.value < 10000)
        .toList();

    if (price != null && twoDecimals.length >= 2) {
      _Candidate? bestL;
      _Candidate? bestT;
      var bestDelta = double.infinity;
      for (var i = 0; i < twoDecimals.length; i++) {
        for (var j = 0; j < twoDecimals.length; j++) {
          if (i == j) continue;
          final l = twoDecimals[i];
          final t = twoDecimals[j];
          final delta = (l.value * price.value - t.value).abs();
          if (delta < bestDelta) {
            bestDelta = delta;
            bestL = l;
            bestT = t;
          }
        }
      }
      liters = bestL;
      total = bestT;
    } else if (twoDecimals.length >= 2) {
      // No price to anchor on — use magnitude heuristic.
      twoDecimals.sort((a, b) => a.value.compareTo(b.value));
      liters = twoDecimals[0];
      total = twoDecimals[1];
    } else if (twoDecimals.length == 1) {
      // Single 2-decimal number: guess based on magnitude.
      final c = twoDecimals.first;
      if (c.value >= 1 && c.value <= 200) {
        liters = c;
      } else {
        total = c;
      }
    }

    return _InferredTriple(
      totalCost: total?.value,
      liters: liters?.value,
      pricePerLiter: price?.value,
    );
  }

  // ---------------------------------------------------------------------
  // Digit normalisation — fixes common 7-segment OCR confusions on
  // digit-context characters only. We only rewrite characters that
  // appear inside a numeric token so we don't destroy German words
  // like "Diesel" or "Super".
  // ---------------------------------------------------------------------

  String _normaliseDigits(String text) {
    // Find tokens that look like numeric values (digits with optional
    // . , separators, possibly contaminated by lookalike letters such
    // as 'B' for 8) and rewrite just those. Non-numeric tokens like
    // 'Diesel' are left untouched by construction because they are
    // never inside a match of the numeric-token regex below.
    final tokenRe = RegExp(r'[0-9OoIlBSDZsdzbg]+(?:[.,][0-9OoIlBSDZsdzbg]+)*');
    return text.replaceAllMapped(tokenRe, (m) {
      final tok = m.group(0)!;
      if (!_isLikelyNumeric(tok)) return tok;
      return _rewriteDigitLookalikes(tok);
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
  bool _isLikelyNumeric(String token) {
    if (token.isEmpty) return false;
    if (!token.contains(RegExp(r'[.,]'))) {
      return RegExp(r'^\d+$').hasMatch(token);
    }
    final core = token.replaceAll(RegExp(r'[.,]'), '');
    if (core.isEmpty) return false;
    for (final ch in core.split('')) {
      if (!_looksLikeDigit(ch)) return false;
    }
    return true;
  }

  bool _looksLikeDigit(String ch) =>
      RegExp(r'^[0-9OoIlBSDZsdzbg]$').hasMatch(ch);

  String _rewriteDigitLookalikes(String token) {
    final sb = StringBuffer();
    for (final ch in token.split('')) {
      sb.write(_digitMap[ch] ?? ch);
    }
    return sb.toString();
  }

  static const _digitMap = <String, String>{
    'O': '0', 'o': '0', 'D': '0',
    'I': '1', 'l': '1',
    'B': '8', 'b': '8',
    'S': '5', 's': '5',
    'Z': '2', 'z': '2',
    'g': '9',
  };

  // ---------------------------------------------------------------------
  // Confidence scoring
  // ---------------------------------------------------------------------

  double _scoreConfidence({
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

  double? _parseDecimal(String value) {
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null) debugPrint('PumpDisplayParser: bad decimal "$value"');
    return n;
  }
}

class _Candidate {
  final double value;
  final int decimals;
  final String line;
  const _Candidate({
    required this.value,
    required this.decimals,
    required this.line,
  });
}

class _InferredTriple {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;
  const _InferredTriple({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
  });
}
