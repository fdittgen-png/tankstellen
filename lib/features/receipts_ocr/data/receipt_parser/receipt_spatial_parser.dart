// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../ocr/_pump_label_table.dart';
import '../ocr/ocr_trace_package.dart';
import '../ocr/ocr_trace_recorder.dart';
import '../ocr/recognized_text_block.dart';
import 'receipt_spatial_geometry.dart';
import 'receipt_spatial_lexicon.dart';
import 'receipt_value_token.dart';

/// The pure spatial receipt parser (#3458) — the rewrite of the #2848
/// label-anchored extractor after the Pézenas E85 field failure
/// (`liters 37.21 / price 41.39 / total 1540.12` accepted at
/// confidence 1.0).
///
/// What changed versus the old extractor, mapped to the three field
/// defects:
///
///  1. **Rotation-normalized, row-only pairing.** Blocks are first
///     orientation-normalized ([normalizeReceiptOrientation]); a label
///     then binds ONLY to a value sharing its row
///     ([kReceiptRowOverlapMin]). The old "nearest by centre distance"
///     cross-row fallback — the mechanism that bound `Prix` to `41.39`
///     two rows up — is gone: a label with no row-mate stays unbound,
///     honestly.
///  2. **Unit-suffix price detection.** A value carrying the `/ℓ` suffix
///     (or any of its OCR mangles — `/?`, `/l`, `/1`, `/L`) is a
///     per-litre price regardless of magnitude or label
///     ([ReceiptValueToken.perLiter]).
///  3. **Currency-aware plausibility.** The printed symbol/code selects
///     per-currency ranges ([ReceiptCurrencyRange]); a paired value
///     outside its field's band is REJECTED from the read (traced as
///     `rejected-out-of-range`), never silently accepted.
///
/// VAT (`TVA`/`MwSt`/`IVA`/`VAT`/`DPH`) and Net (`Net`/`Netto`/`HT`)
/// rows are matched first and their row values consumed, so a tax line
/// can never win the total.
///
/// This parser only READS — it never derives a missing field. Derivation
/// (and the honest confidence/gate rules around it) lives in the
/// orchestrator, so a derived value can never feed back into the
/// consistency signal (#3458 defect 3, the tautological gate).

/// The spatial read: what was independently READ off the paper, plus the
/// signals the orchestrator's gate needs.
@immutable
class ReceiptSpatialRead {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;

  /// The fields that were independently READ (row-paired + in-range).
  /// Never contains a derived field — this parser does not derive.
  final Set<PumpField> readFields;

  /// Range-table key of the currency detected on the paper (`EUR`,
  /// `CZK`, …), null when no marker was printed/recognized.
  final String? detectedCurrency;

  /// The plausibility band the read was filtered against.
  final ReceiptCurrencyRange range;

  /// `true` when the frame arrived 90°/270°-rotated and was transposed.
  final bool transposed;

  const ReceiptSpatialRead({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
    this.readFields = const {},
    this.detectedCurrency,
    this.range = kEuroRange,
    this.transposed = false,
  });

  /// `true` when all three fields were READ and agree on
  /// `total ≈ litres × €/L` within 2 cents. Only meaningful over read
  /// fields — derived values never enter this object.
  bool get isConsistentRead {
    if (readFields.length < 3) return false;
    return (liters! * pricePerLiter! - totalCost!).abs() <= 0.02;
  }
}

class _LabelHit {
  final RecognizedTextBlock block;
  final ReceiptLabelKind kind;
  _LabelHit(this.block, this.kind);
}

/// Reads the receipt spatially. [rangeOverride] (from a threaded locale
/// profile) wins over the currency detected on the paper; [volumeMax]
/// likewise overrides the default volume band.
ReceiptSpatialRead parseReceiptSpatially(
  List<RecognizedTextBlock> blocks, {
  ReceiptCurrencyRange? rangeOverride,
  double? volumeMax,
  OcrTraceRecorder? trace,
}) {
  if (blocks.isEmpty) return const ReceiptSpatialRead();
  final frame = normalizeReceiptOrientation(blocks);

  // --- classify -----------------------------------------------------
  final values = <ReceiptValueToken>[];
  final labels = <_LabelHit>[];
  for (final block in frame.blocks) {
    final token = parseReceiptValueToken(block);
    if (token != null) {
      values.add(token);
      trace?.classify(block.text, 'value',
          value: token.value, decimals: token.decimals);
      continue;
    }
    final kind = classifySpatialLabel(block.text);
    if (kind != null) {
      labels.add(_LabelHit(block, kind));
      trace?.classify(block.text, 'label', field: kind.name);
    }
  }

  // --- currency ------------------------------------------------------
  final detected = _majorityCurrency(values);
  final range = rangeOverride ?? receiptCurrencyRangeFor(detected);

  // --- pair -----------------------------------------------------------
  final consumed = <ReceiptValueToken>{};

  // Exclusion rows first: a VAT/Net label consumes EVERY value on its
  // row so tax/net amounts can never be claimed as transaction fields.
  for (final label in labels) {
    if (label.kind != ReceiptLabelKind.vat &&
        label.kind != ReceiptLabelKind.net) {
      continue;
    }
    final rule = label.kind == ReceiptLabelKind.vat
        ? 'vat-row-excluded'
        : 'net-row-excluded';
    for (final v in values) {
      if (consumed.contains(v)) continue;
      if (rowOverlapFraction(label.block.box, v.block.box) <
          kReceiptRowOverlapMin) {
        continue;
      }
      consumed.add(v);
      _tracePairing(trace, label.kind.name, label.block, v, rule);
    }
  }

  // Transaction rows: per-litre price first (its unit suffix makes it
  // the most identifiable), then total, then volume.
  final bound = <ReceiptLabelKind, ReceiptValueToken>{};
  for (final kind in const [
    ReceiptLabelKind.unitPrice,
    ReceiptLabelKind.total,
    ReceiptLabelKind.volume,
  ]) {
    for (final label in labels) {
      if (label.kind != kind || bound.containsKey(kind)) continue;
      final v = _bestRowMate(label.block.box, values, consumed);
      if (v == null) continue;
      bound[kind] = v;
      consumed.add(v);
      _tracePairing(trace, kind.name, label.block, v, 'row-overlap');
    }
  }

  // Unit-suffix rule: a `/ℓ`-suffixed value IS the per-litre price
  // regardless of magnitude — it claims the field when the label row
  // read nothing, and overrides a suffix-less row pairing.
  final suffix = values
      .where((v) => v.perLiter && !consumed.contains(v))
      .toList(growable: false);
  if (suffix.isNotEmpty) {
    final current = bound[ReceiptLabelKind.unitPrice];
    if (current == null || !current.perLiter) {
      final v = suffix.first;
      bound[ReceiptLabelKind.unitPrice] = v;
      consumed.add(v);
      _tracePairing(trace, ReceiptLabelKind.unitPrice.name,
          _labelBlockFor(labels, ReceiptLabelKind.unitPrice), v,
          current == null ? 'unit-suffix' : 'unit-suffix-override');
    }
  }

  // --- currency-aware plausibility ------------------------------------
  final vMax = volumeMax ?? kReceiptVolumeMax;
  final read = <PumpField, double>{};
  bound.forEach((kind, token) {
    final field = _pumpFieldFor(kind);
    final inRange = switch (field) {
      PumpField.pricePerLitre => range.priceInRange(token.value),
      PumpField.total => range.totalInRange(token.value),
      PumpField.volume =>
        token.value >= kReceiptVolumeMin && token.value <= vMax,
    };
    if (inRange) {
      read[field] = token.value;
    } else {
      _tracePairing(trace, kind.name, _labelBlockFor(labels, kind), token,
          'rejected-out-of-range');
    }
  });

  return ReceiptSpatialRead(
    totalCost: read[PumpField.total],
    liters: read[PumpField.volume],
    pricePerLiter: read[PumpField.pricePerLitre],
    readFields: read.keys.toSet(),
    detectedCurrency: detected,
    range: range,
    transposed: frame.transposed,
  );
}

/// `true` when the classified blocks alone justify routing to the
/// spatial parser: at least two DISTINCT transaction labels plus two
/// value tokens — language-agnostic, so a DE `Menge/Preis/Summe` or CZ
/// `Množství/Cena/Celkem` receipt routes without a flat-text marker.
bool hasSpatialRoutingSignal(List<RecognizedTextBlock> blocks) {
  final frame = normalizeReceiptOrientation(blocks);
  final kinds = <ReceiptLabelKind>{};
  var valueTokens = 0;
  for (final b in frame.blocks) {
    if (parseReceiptValueToken(b) != null) {
      valueTokens++;
      continue;
    }
    final kind = classifySpatialLabel(b.text);
    if (kind == ReceiptLabelKind.volume ||
        kind == ReceiptLabelKind.unitPrice ||
        kind == ReceiptLabelKind.total) {
      kinds.add(kind!);
    }
  }
  return kinds.length >= 2 && valueTokens >= 2;
}

String? _majorityCurrency(List<ReceiptValueToken> values) {
  final counts = <String, int>{};
  for (final v in values) {
    final code = v.currencyCode;
    if (code == null) continue;
    counts[code] = (counts[code] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  counts.forEach((code, count) {
    if (count > bestCount) {
      best = code;
      bestCount = count;
    }
  });
  return best;
}

/// The value sharing [label]'s row with the smallest horizontal gap —
/// side-agnostic so 180°-rotated frames pair identically. Returns null
/// when NO value shares the row: no cross-row guessing (#3458 defect 1).
ReceiptValueToken? _bestRowMate(
  OcrBox label,
  List<ReceiptValueToken> values,
  Set<ReceiptValueToken> consumed,
) {
  ReceiptValueToken? best;
  var bestGap = double.infinity;
  for (final v in values) {
    if (consumed.contains(v)) continue;
    if (rowOverlapFraction(label, v.block.box) < kReceiptRowOverlapMin) {
      continue;
    }
    final gap = horizontalGap(label, v.block.box);
    if (gap < bestGap) {
      bestGap = gap;
      best = v;
    }
  }
  return best;
}

PumpField _pumpFieldFor(ReceiptLabelKind kind) => switch (kind) {
      ReceiptLabelKind.volume => PumpField.volume,
      ReceiptLabelKind.unitPrice => PumpField.pricePerLitre,
      ReceiptLabelKind.total => PumpField.total,
      // VAT/Net rows are exclusions — they never reach field binding.
      ReceiptLabelKind.vat || ReceiptLabelKind.net => PumpField.total,
    };

RecognizedTextBlock? _labelBlockFor(
  List<_LabelHit> labels,
  ReceiptLabelKind kind,
) {
  for (final l in labels) {
    if (l.kind == kind) return l.block;
  }
  return null;
}

void _tracePairing(
  OcrTraceRecorder? trace,
  String field,
  RecognizedTextBlock? label,
  ReceiptValueToken value,
  String rule,
) {
  if (trace == null) return;
  final lb = label?.box;
  final vb = value.block.box;
  trace.pairing(OcrTracePairing(
    field: field,
    labelText: label?.text ?? '',
    labelBox: lb == null ? const [] : [lb.left, lb.top, lb.right, lb.bottom],
    valueText: value.block.text,
    valueBox: [vb.left, vb.top, vb.right, vb.bottom],
    rule: rule,
    value: value.value,
  ));
}
