// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../_pump_display_helpers.dart';
import '../ocr/recognized_text_block.dart';
import 'receipt_label_table.dart';

/// A receipt block already classified as a printed label (with its field).
@immutable
class _LabelHit {
  final RecognizedTextBlock block;
  final PumpField field;
  const _LabelHit(this.block, this.field);
}

/// A receipt block already classified as a numeric value.
@immutable
class _NumericHit {
  final RecognizedTextBlock block;
  final double value;
  final int decimals;
  const _NumericHit(this.block, this.value, this.decimals);
}

/// The geometry-aware read of a fuel-station receipt (#2848).
///
/// Carries the three transaction values plus a [derived] set naming any
/// field the cross-check *computed* rather than read directly.
@immutable
class ReceiptAnchoredResult {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;

  /// Fields whose value was DERIVED from the other two via
  /// `total ≈ volume × pricePerLitre`, not read off the receipt.
  final Set<PumpField> derived;

  const ReceiptAnchoredResult({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
    this.derived = const {},
  });

  static const empty = ReceiptAnchoredResult();

  /// Number of the three transaction fields that are bound.
  int get boundCount =>
      [totalCost, liters, pricePerLiter].where((v) => v != null).length;

  /// `true` when all three agree on `total ≈ volume × €/L` within a cent.
  bool get isConsistent {
    if (totalCost == null || liters == null || pricePerLiter == null) {
      return false;
    }
    return (liters! * pricePerLiter! - totalCost!).abs() <= 0.02;
  }
}

/// Reads the three fuel-receipt values by anchoring each printed LABEL to
/// its row-aligned numeric block, then cross-checking the arithmetic
/// (#2848).
///
/// The receipt cousin of `extractByLabelAnchor` (the #2478 pump-display
/// path) — it reuses the same geometry technique (a value block binds to
/// the nearest label block) but for the receipt layout, where the value
/// sits in a RIGHT column ROW-ALIGNED with its left-column label:
///
///  1. **Classify** each block label | numeric | noise (reusing the
///     7-segment digit normaliser + a tolerant numeric tokenizer that
///     strips a leading currency glyph and trailing OCR noise like `!`,
///     `/`, stray punctuation, and reads both `0,819` and `30.96`).
///  2. **Anchor** each label to the numeric block on the SAME ROW (best
///     vertical overlap, then nearest to its right), so `Volume` binds to
///     `30.96`, `Prix` to `0.819`, `TOT TTC` to `25.36`.
///  3. **Cross-check** `total ≈ volume × €/L`: with exactly two values
///     read it DERIVES the third (and flags it [derived]).
ReceiptAnchoredResult extractReceiptByLabelAnchor(
  List<RecognizedTextBlock> blocks,
) {
  if (blocks.isEmpty) return ReceiptAnchoredResult.empty;

  final labels = <_LabelHit>[];
  final numerics = <_NumericHit>[];

  for (final block in blocks) {
    final numeric = _asNumeric(block);
    if (numeric != null) {
      numerics.add(numeric);
      continue;
    }
    final field = classifyReceiptLabel(block.text);
    if (field != null) {
      labels.add(_LabelHit(block, field));
    }
    // Everything else (header prose, card-reader plate, IDs) is noise.
  }

  final bound = <PumpField, double>{};
  final consumed = <_NumericHit>{};

  // Bind heaviest-weight labels first so the per-litre "Prix" claims its
  // number before a lighter label could.
  labels.sort((a, b) =>
      receiptFieldWeight(b.field).compareTo(receiptFieldWeight(a.field)));
  for (final label in labels) {
    if (bound.containsKey(label.field)) continue;
    final value = _anchorOnRow(label.block, numerics, consumed);
    if (value != null) {
      bound[label.field] = value.value;
      consumed.add(value);
    }
  }

  return _crossCheck(
    total: bound[PumpField.total],
    volume: bound[PumpField.volume],
    price: bound[PumpField.pricePerLitre],
  );
}

/// Parses [block] as a numeric value when its text — after 7-segment
/// normalisation, stripping a leading/embedded currency glyph (€, EUR)
/// and unit (L/litres/€/L), and trimming TRAILING OCR noise (`!`, `/`,
/// stray punctuation) — is a clean decimal. Reads both comma and dot
/// decimals (FR `0,819` + `30.96` on the same receipt). A block that
/// also carries label text never parses.
_NumericHit? _asNumeric(RecognizedTextBlock block) {
  final normalised = normaliseDigits(block.text).trim();
  var cleaned = normalised
      .replaceAll(RegExp(r'(?:€|EUR|LITRES?|litres?|L|l)\b'), ' ')
      .replaceAll('€', ' ')
      .replaceAll('/', ' ')
      // Trailing OCR noise the receipt printer / ML Kit leaves on a value
      // ("30.96 !", "€ 0,819/", "25,36 ."): drop any non-numeric tail.
      .replaceAll(RegExp(r'[!|;:*°"º°\s]+$'), '')
      .trim();
  // A leading currency/space residue ("  25,36") is already handled by the
  // anchored ^...$ match below once trimmed.
  cleaned = cleaned.replaceAll(RegExp(r'^[^\d]+'), '');
  final m = RegExp(r'^(\d+[.,]\d{1,3})$').firstMatch(cleaned);
  if (m == null) return null;
  final raw = m.group(1)!;
  final value = parseDecimalFromOcr(raw);
  if (value == null) return null;
  final decimals = raw.split(RegExp(r'[.,]')).last.length;
  return _NumericHit(block, value, decimals);
}

/// Finds the numeric block ROW-ALIGNED with [label]: prefers a numeric
/// whose vertical span overlaps the label's row, then — among those — the
/// nearest to the RIGHT (receipt values sit in a right column). When no
/// numeric shares the row it falls back to the nearest by centre distance
/// so a slightly mis-aligned value still binds.
_NumericHit? _anchorOnRow(
  RecognizedTextBlock label,
  List<_NumericHit> numerics,
  Set<_NumericHit> consumed,
) {
  _NumericHit? bestRow;
  var bestRowScore = double.infinity;
  _NumericHit? bestAny;
  var bestAnyScore = double.infinity;

  for (final n in numerics) {
    if (consumed.contains(n)) continue;
    final dx = n.block.box.cx - label.box.cx;
    final dy = n.block.box.cy - label.box.cy;
    final anyScore = dx * dx + dy * dy;
    if (anyScore < bestAnyScore) {
      bestAnyScore = anyScore;
      bestAny = n;
    }
    // Row-aligned: the numeric's vertical span overlaps the label's, and
    // it lies to the right (or roughly level). Score by horizontal gap so
    // the closest right-column value on the row wins.
    final overlapsRow =
        n.block.box.top < label.box.bottom && label.box.top < n.block.box.bottom;
    final toRight = n.block.box.cx >= label.box.cx;
    if (overlapsRow && toRight) {
      final gap = (n.block.box.left - label.box.right).abs();
      if (gap < bestRowScore) {
        bestRowScore = gap;
        bestRow = n;
      }
    }
  }
  return bestRow ?? bestAny;
}

/// Cross-checks `total ≈ volume × €/L`, deriving the missing third when
/// exactly two are read and flagging it [ReceiptAnchoredResult.derived].
ReceiptAnchoredResult _crossCheck({
  double? total,
  double? volume,
  double? price,
}) {
  final derived = <PumpField>{};
  final present = [total, volume, price].where((v) => v != null).length;

  if (present == 2) {
    if (total == null && volume != null && price != null) {
      total = double.parse((volume * price).toStringAsFixed(2));
      derived.add(PumpField.total);
    } else if (volume == null && total != null && price != null && price > 0) {
      volume = double.parse((total / price).toStringAsFixed(2));
      derived.add(PumpField.volume);
    } else if (price == null &&
        total != null &&
        volume != null &&
        volume > 0) {
      price = double.parse((total / volume).toStringAsFixed(3));
      derived.add(PumpField.pricePerLitre);
    }
  }

  return ReceiptAnchoredResult(
    totalCost: total,
    liters: volume,
    pricePerLiter: price,
    derived: derived,
  );
}
