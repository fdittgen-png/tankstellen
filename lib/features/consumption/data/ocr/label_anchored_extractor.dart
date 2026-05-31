// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../_pump_display_helpers.dart';
import '_pump_label_table.dart';
import 'label_anchored_trace.dart';
import 'ocr_trace_recorder.dart';
import 'pump_ocr_config.dart';
import 'recognized_text_block.dart';

export '_pump_label_table.dart' show PumpField, pumpFieldName;

/// A block already classified as a printed label (with its field).
@immutable
class _LabelHit {
  final RecognizedTextBlock block;
  final PumpField field;
  const _LabelHit(this.block, this.field);
}

/// A block already classified as a numeric value.
@immutable
class _NumericHit {
  final RecognizedTextBlock block;
  final double value;
  final int decimals;
  const _NumericHit(this.block, this.value, this.decimals);
}

/// The label-anchored read of a pump display (#2478).
///
/// Carries the three transaction values plus a [derived] set naming any
/// field the cross-check *computed* rather than read directly — so the UI
/// can flag a recovered value for the user to double-check.
@immutable
class LabelAnchoredResult {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;

  /// Fields whose value was DERIVED from the other two via
  /// `total ≈ volume × pricePerLitre`, not read off the display.
  final Set<PumpField> derived;

  const LabelAnchoredResult({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
    this.derived = const {},
  });

  static const empty = LabelAnchoredResult();

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

/// Reads the three pump-display values by anchoring each printed LABEL to
/// its nearest numeric block, then cross-checking the arithmetic (#2478).
///
/// This is the primary path that recovers the dropped PRIX DU LITRE unit
/// price. Unlike the flat-string parser it keeps ML Kit's block geometry,
/// so it can:
///
///  1. **Classify** each block label | numeric | noise (reusing the
///     7-segment digit normaliser so `0,79B` → `0.798`).
///  2. **Disambiguate** PRIX vs PRIX DU LITRE by LONGEST/heaviest match
///     per block, and **assemble** a label split across two blocks
///     ("PRIX DU" + "LITRE") by merging adjacent label fragments.
///  3. **Anchor** each label to the nearest numeric block — directly
///     BELOW it for a vertically-stacked readout (FR Tokheim) or to its
///     RIGHT for a horizontal strip. Because it reasons about *relative*
///     label↔value offsets, a 90°-rotated frame reads identically.
///  4. **Magnitude-fallback** any still-unbound field by bucketing the
///     leftover numerics against the locale [profile]'s range + decimal
///     signature (price 0.5..4.0 / 3-dec, volume 2-dec, total 2-dec).
///  5. **Cross-check** `total ≈ volume × €/L`: with exactly two values
///     read it DERIVES the third (and flags it [derived]).
LabelAnchoredResult extractByLabelAnchor(
  List<RecognizedTextBlock> blocks, {
  OcrLocaleProfile? profile,
  OcrTraceRecorder? trace,
}) {
  if (blocks.isEmpty) return LabelAnchoredResult.empty;

  final labels = <_LabelHit>[];
  final numerics = <_NumericHit>[];
  final rawLabelBlocks = <RecognizedTextBlock>[];

  for (final block in blocks) {
    final numeric = _asNumeric(block);
    if (numeric != null) {
      numerics.add(numeric);
      continue;
    }
    final field = classifyPumpLabel(block.text);
    if (field != null) {
      labels.add(_LabelHit(block, field));
      rawLabelBlocks.add(block);
      continue;
    }
    // Everything else (metrology prose, card-reader plate) is noise.
  }
  // Trace-only re-walk (guarded → read path pays nothing when null).
  if (trace != null) {
    for (final b in blocks) {
      final n = _asNumeric(b);
      recordClassification(
          trace, b.text, n?.value, n?.decimals, classifyPumpLabel(b.text));
    }
  }

  // Assemble multi-block labels: "PRIX DU" + "LITRE" recombine into the
  // unit-price label even when ML Kit split them across two blocks.
  for (final hit in _assembleSplitLabels(rawLabelBlocks)) {
    labels.removeWhere(
        (l) => l.block == hit.firstSource || l.block == hit.secondSource);
    labels.add(_LabelHit(hit.block, hit.field));
    trace?.assembled(
        first: hit.firstSource.text,
        second: hit.secondSource.text,
        combined: hit.block.text,
        field: pumpFieldName(hit.field));
  }

  final bound = <PumpField, double>{};
  final consumed = <_NumericHit>{};

  // Bind heaviest-weight labels first so PRIX DU LITRE claims its number
  // before bare PRIX gets a chance to.
  labels.sort(
      (a, b) => pumpFieldWeight(b.field).compareTo(pumpFieldWeight(a.field)));
  for (final label in labels) {
    if (bound.containsKey(label.field)) continue;
    final value = _anchorNumeric(label.block, numerics, consumed,
        field: label.field, trace: trace);
    if (value != null) {
      bound[label.field] = value.value;
      consumed.add(value);
    }
  }

  _magnitudeFallback(bound, numerics, consumed, profile, trace);

  return _crossCheck(
    total: bound[PumpField.total],
    volume: bound[PumpField.volume],
    price: bound[PumpField.pricePerLitre],
    trace: trace,
  );
}

/// Parses [block] as a numeric value when its text is a clean decimal
/// (after 7-segment normalisation), else null. A leading/trailing
/// currency or unit glyph (€, L, LITRES, €/L) is stripped first so the
/// value block "0,798 €" still reads as a bare number; a block that also
/// carries label text ("PRIX") never parses.
_NumericHit? _asNumeric(RecognizedTextBlock block) {
  final normalised = normaliseDigits(block.text).trim();
  final cleaned = normalised
      .replaceAll(RegExp(r'(?:€|EUR|LITRES?|litres?|L|l)\b'), ' ')
      .replaceAll('/', ' ')
      .trim();
  final m = RegExp(r'^(\d+[.,]\d{1,3})$').firstMatch(cleaned);
  if (m == null) return null;
  final raw = m.group(1)!;
  final value = parseDecimalFromOcr(raw);
  if (value == null) return null;
  final decimals = raw.split(RegExp(r'[.,]')).last.length;
  return _NumericHit(block, value, decimals);
}

/// A label reconstructed from two adjacent blocks (e.g. "PRIX DU" +
/// "LITRE"), naming the source blocks so they can be removed from the
/// single-block label list.
@immutable
class _AssembledLabel {
  final RecognizedTextBlock block;
  final PumpField field;
  final RecognizedTextBlock firstSource;
  final RecognizedTextBlock secondSource;
  const _AssembledLabel(
      this.block, this.field, this.firstSource, this.secondSource);
}

/// Merges adjacent label blocks whose concatenated text matches a heavier
/// label than either alone — recovering "PRIX DU" + "LITRE" → the
/// unit-price label when ML Kit split the wrapped line.
List<_AssembledLabel> _assembleSplitLabels(List<RecognizedTextBlock> labels) {
  final out = <_AssembledLabel>[];
  for (var i = 0; i < labels.length; i++) {
    for (var j = 0; j < labels.length; j++) {
      if (i == j) continue;
      final a = labels[i];
      final b = labels[j];
      if (!_areAdjacent(a.box, b.box)) continue;
      final combined = '${a.text} ${b.text}';
      final combinedField = classifyPumpLabel(combined);
      if (combinedField == null) continue;
      final aField = classifyPumpLabel(a.text);
      // Only assemble when the merge yields a HEAVIER label than the
      // first fragment alone (so "PRIX"+"DU" → PRIX DU LITRE wins).
      if (aField != null &&
          pumpFieldWeight(combinedField) <= pumpFieldWeight(aField)) {
        continue;
      }
      out.add(_AssembledLabel(
        RecognizedTextBlock(text: combined, box: _union(a.box, b.box)),
        combinedField,
        a,
        b,
      ));
    }
  }
  return out;
}

OcrBox _union(OcrBox a, OcrBox b) => OcrBox(
      left: a.left < b.left ? a.left : b.left,
      top: a.top < b.top ? a.top : b.top,
      right: a.right > b.right ? a.right : b.right,
      bottom: a.bottom > b.bottom ? a.bottom : b.bottom,
    );

/// Two label boxes are adjacent when one sits just below or just right of
/// the other within roughly a box-dimension's gap — the layout of a label
/// that wrapped onto a second line.
bool _areAdjacent(OcrBox a, OcrBox b) {
  final avgH = (a.height + b.height) / 2;
  final avgW = (a.width + b.width) / 2;
  final overlapX = a.left < b.right && b.left < a.right;
  final overlapY = a.top < b.bottom && b.top < a.bottom;
  final stackedBelow = overlapX && (b.top - a.bottom).abs() <= avgH * 1.5;
  final besideRight = overlapY && (b.left - a.right).abs() <= avgW * 1.5;
  return stackedBelow || besideRight;
}

/// Finds the numeric block anchored to [label]: the nearest unconsumed
/// numeric by squared centre distance.
///
/// Pure Euclidean nearest-neighbour is what makes the read
/// ROTATION-INVARIANT — distance is preserved under the `(x,y)→(H−y,x)`
/// 90° turn, so a value stacked BELOW its label upright (FR Tokheim) and
/// the same value sitting to the RIGHT after the frame is rotated bind
/// identically. Heaviest-weight labels anchor first and CONSUME their
/// number (see [extractByLabelAnchor]), so a label never steals a value
/// that a more specific label owns.
_NumericHit? _anchorNumeric(
  RecognizedTextBlock label,
  List<_NumericHit> numerics,
  Set<_NumericHit> consumed, {
  PumpField? field,
  OcrTraceRecorder? trace,
}) {
  _NumericHit? best;
  var bestScore = double.infinity;
  for (final n in numerics) {
    if (consumed.contains(n)) continue;
    final dx = n.block.box.cx - label.box.cx;
    final dy = n.block.box.cy - label.box.cy;
    final score = dx * dx + dy * dy;
    if (score < bestScore) {
      bestScore = score;
      best = n;
    }
  }
  if (trace != null && field != null) {
    recordAnchorCandidates(trace, field, label.text, label.box.cx, label.box.cy, [
      for (final n in numerics)
        if (!consumed.contains(n))
          AnchorCandidate(
              value: n.value,
              cx: n.block.box.cx,
              cy: n.block.box.cy,
              chosen: identical(n, best)),
    ]);
  }
  return best;
}

/// Buckets leftover numerics into any unbound field by the locale
/// [profile]'s range + decimal signature (#2478 magnitude fallback):
/// price ~0.5..4.0 with 3 decimals, volume/total with 2 decimals.
void _magnitudeFallback(
  Map<PumpField, double> bound,
  List<_NumericHit> numerics,
  Set<_NumericHit> consumed,
  OcrLocaleProfile? profile,
  OcrTraceRecorder? trace,
) {
  final leftover = numerics.where((n) => !consumed.contains(n)).toList();
  if (leftover.isEmpty) return;
  final priceMin = profile?.priceMin ?? 0.5;
  final priceMax = profile?.priceMax ?? 5.0;
  // Pre-fallback snapshot so the trace reports only fallback's own picks.
  final before = Map<PumpField, double>.from(bound);
  var reason = '';

  if (!bound.containsKey(PumpField.pricePerLitre)) {
    final priceLike = leftover
        .where((n) =>
            n.value >= priceMin && n.value <= priceMax && n.decimals >= 3)
        .toList()
      ..sort((a, b) => b.decimals.compareTo(a.decimals));
    if (priceLike.isNotEmpty) {
      bound[PumpField.pricePerLitre] = priceLike.first.value;
      consumed.add(priceLike.first);
    }
  }

  final twoDec = leftover
      .where((n) => !consumed.contains(n) && n.decimals == 2)
      .toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  if (!bound.containsKey(PumpField.volume) &&
      !bound.containsKey(PumpField.total) &&
      twoDec.length >= 2) {
    final a = twoDec.first.value;
    final b = twoDec.last.value;
    final price = bound[PumpField.pricePerLitre];
    if (price != null && price > 0) {
      // With a price to anchor on, the strongest cross-check is
      // `volume × price ≈ total`. Pick the (volume, total) ordering that
      // best satisfies it — at €/L < 1 the volume can EXCEED the total,
      // so a bare magnitude sort would mislabel them.
      final asAsc = (a * price - b).abs(); // volume=a (smaller), total=b
      final asDesc = (b * price - a).abs(); // volume=b (larger), total=a
      reason = 'price-anchored: best (volume×price≈total) ordering';
      if (asDesc < asAsc) {
        bound[PumpField.volume] = b;
        bound[PumpField.total] = a;
      } else {
        bound[PumpField.volume] = a;
        bound[PumpField.total] = b;
      }
    } else {
      // No price anchor — fall back to the usual `volume < total` (holds
      // whenever €/L > 1, the common case).
      bound[PumpField.volume] = a;
      bound[PumpField.total] = b;
      reason = 'no price anchor: volume<total';
    }
  } else if (!bound.containsKey(PumpField.volume) && twoDec.isNotEmpty) {
    bound[PumpField.volume] = twoDec.first.value;
    reason = 'lone 2-dec leftover → volume';
  } else if (!bound.containsKey(PumpField.total) && twoDec.isNotEmpty) {
    bound[PumpField.total] = twoDec.last.value;
    reason = 'lone 2-dec leftover → total';
  }

  recordFallback(trace, before, bound, priceMin, priceMax, reason);
}

/// Cross-checks `total ≈ volume × €/L`, deriving the missing third when
/// exactly two are read and flagging it [LabelAnchoredResult.derived].
LabelAnchoredResult _crossCheck({
  double? total,
  double? volume,
  double? price,
  OcrTraceRecorder? trace,
}) {
  final readTotal = total, readVolume = volume, readPrice = price;
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

  recordCrossCheck(trace, readTotal, readVolume, readPrice, derived,
      total: total, volume: volume, price: price);

  return LabelAnchoredResult(
    totalCost: total,
    liters: volume,
    pricePerLiter: price,
    derived: derived,
  );
}
