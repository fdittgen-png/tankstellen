import '_pump_display_helpers.dart';
import '_pump_display_patterns.dart';
import 'pump_display_parse_result.dart';

// Re-export so existing callers that `import 'pump_display_parser.dart'`
// keep resolving [PumpDisplayParseResult] without changes.
export 'pump_display_parse_result.dart';

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

    final normalised = normaliseDigits(rawText);
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
    final confidence = scorePumpDisplayConfidence(
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

  double? _extractBetrag(String text) {
    for (final p in kBetragPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final value = parseDecimalFromOcr(m.group(1)!);
        if (value != null && value >= 0 && value < 10000) return value;
      }
    }
    return null;
  }

  double? _extractAbgabe(String text) {
    for (final p in kAbgabePatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        // Skip if this looks like a price/litre (has "€" right after).
        final tail = text.substring(m.end);
        if (tail.trimLeft().startsWith('€') ||
            tail.trimLeft().toLowerCase().startsWith('eur')) {
          continue;
        }
        final value = parseDecimalFromOcr(m.group(1)!);
        if (value != null && value >= 0 && value < 2000) return value;
      }
    }
    return null;
  }

  double? _extractPricePerLiter(String text) {
    for (final p in kPricePerLiterPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final value = parseDecimalFromOcr(m.group(1)!);
        if (value != null && value > 0 && value < 10) return value;
      }
    }
    final ctMatch = kCentsPerLiterPattern.firstMatch(text);
    if (ctMatch != null) {
      final ct = parseDecimalFromOcr(ctMatch.group(1)!);
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
      if (kLonePumpDigitPattern.hasMatch(trimmed)) {
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
  PumpDisplayInferredTriple _inferFromNumericOrder(
    List<String> lines, {
    List<double> exclude = const [],
  }) {
    final rawNumbers = <PumpDisplayCandidate>[];
    for (final line in lines) {
      for (final m in kDecimalNumberPattern.allMatches(line)) {
        final v = parseDecimalFromOcr(m.group(1)!);
        if (v == null) continue;
        final decimals = m.group(1)!.contains(',') || m.group(1)!.contains('.')
            ? m.group(1)!.split(RegExp(r'[.,]')).last.length
            : 0;
        rawNumbers.add(
            PumpDisplayCandidate(value: v, decimals: decimals, line: line));
      }
    }
    // Consume `exclude` once per occurrence so duplicate values
    // (e.g. the pump reading 0.00 on every line at idle) are not
    // all wiped out by the first match.
    final toSkip = List<double>.from(exclude);
    final numbers = <PumpDisplayCandidate>[];
    for (final c in rawNumbers) {
      final idx = toSkip.indexWhere((e) => (e - c.value).abs() < 1e-6);
      if (idx >= 0) {
        toSkip.removeAt(idx);
      } else {
        numbers.add(c);
      }
    }
    if (numbers.isEmpty) return PumpDisplayInferredTriple.empty;

    PumpDisplayCandidate? price;
    PumpDisplayCandidate? liters;
    PumpDisplayCandidate? total;

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
      PumpDisplayCandidate? bestL;
      PumpDisplayCandidate? bestT;
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

    return PumpDisplayInferredTriple(
      totalCost: total?.value,
      liters: liters?.value,
      pricePerLiter: price?.value,
    );
  }
}
