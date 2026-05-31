// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '_pump_label_table.dart';
import 'ocr_trace_package.dart';
import 'ocr_trace_recorder.dart';

/// Trace-recording helpers split out of `label_anchored_extractor.dart`
/// (#2517) so the extractor file stays under the 400-line norm and its
/// geometry logic is not diluted by the (trace-only, prod-null) recording
/// code. Every function here is a no-op when [trace] is null.

/// Records one block's classification — `numeric` when [value] is set,
/// `label` when [field] is set, else `noise`. Numeric wins over label,
/// mirroring the extractor's own branch order. No-op when [trace] null.
void recordClassification(
  OcrTraceRecorder? trace,
  String text,
  double? value,
  int? decimals,
  PumpField? field,
) {
  if (trace == null) return;
  if (value != null) {
    trace.classify(text, 'numeric', value: value, decimals: decimals);
  } else if (field != null) {
    trace.classify(text, 'label',
        field: pumpFieldName(field), weight: pumpFieldWeight(field));
  } else {
    trace.classify(text, 'noise');
  }
}

/// One anchor candidate's geometry, as the extractor sees it just before
/// recording — plain types so this file needs no `_NumericHit` access.
class AnchorCandidate {
  final double value;
  final double cx;
  final double cy;
  final bool chosen;
  const AnchorCandidate({
    required this.value,
    required this.cx,
    required this.cy,
    required this.chosen,
  });
}

/// Records every label→numeric anchor candidate for [field]/[labelText]
/// anchored at ([labelCx], [labelCy]), flagging the chosen one. The
/// squared centre distance is computed here so the extractor's hot loop
/// stays untouched.
void recordAnchorCandidates(
  OcrTraceRecorder? trace,
  PumpField field,
  String labelText,
  double labelCx,
  double labelCy,
  List<AnchorCandidate> candidates,
) {
  if (trace == null) return;
  final fieldName = pumpFieldName(field);
  trace.anchorCandidates([
    for (final c in candidates)
      OcrTraceAnchor(
        labelField: fieldName,
        labelText: labelText,
        numericValue: c.value,
        sqDistance:
            (c.cx - labelCx) * (c.cx - labelCx) + (c.cy - labelCy) * (c.cy - labelCy),
        chosen: c.chosen,
      ),
  ]);
}

/// Records the cross-check derivation: the read inputs ([readTotal] etc.),
/// which field (if any) the identity `total≈volume×€/L` derived, and the
/// computed value of that field. No-op when [trace] is null.
void recordCrossCheck(
  OcrTraceRecorder? trace,
  double? readTotal,
  double? readVolume,
  double? readPrice,
  Set<PumpField> derived, {
  double? total,
  double? volume,
  double? price,
}) {
  if (trace == null) return;
  final path = derived.isEmpty ? 'none' : derived.first.name;
  final computed = derived.contains(PumpField.total)
      ? total
      : derived.contains(PumpField.volume)
          ? volume
          : derived.contains(PumpField.pricePerLitre)
              ? price
              : null;
  trace.crossCheck(
      total: readTotal,
      volume: readVolume,
      price: readPrice,
      derivedPath: path,
      computed: computed);
}

/// Emits a [OcrTraceRecorder.fallback] event for every field the magnitude
/// fallback assigned (absent in [before], present in [after]).
void recordFallback(
  OcrTraceRecorder? trace,
  Map<PumpField, double> before,
  Map<PumpField, double> after,
  double priceMin,
  double priceMax,
  String reason,
) {
  if (trace == null) return;
  for (final field in after.keys) {
    if (before.containsKey(field)) continue;
    final isPrice = field == PumpField.pricePerLitre;
    trace.fallback(
      field: pumpFieldName(field),
      value: after[field]!,
      decimals: isPrice ? 3 : 2,
      reason: isPrice ? 'in price band $priceMin..$priceMax, >=3 dec' : reason,
    );
  }
}
