// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

// The leaf sub-models of the OCR trace package (#2517) — split out of
// `ocr_trace_package.dart` so each file stays under the 400-line norm.
// `ocr_trace_package.dart` re-exports everything here, so importers see
// one unit. PURE Dart, no freezed: hand-written immutable classes +
// `toJson()`.

/// Glare-rejection preprocessing decision.
@immutable
class OcrTracePreprocess {
  final double glareFraction;
  final double threshold;
  final bool rejected;

  const OcrTracePreprocess({
    required this.glareFraction,
    required this.threshold,
    required this.rejected,
  });

  Map<String, dynamic> toJson() => {
        'glareFraction': glareFraction,
        'threshold': threshold,
        'rejected': rejected,
      };
}

/// ML Kit output — the flat text plus every block with its box.
@immutable
class OcrTraceMlkit {
  final String flatText;
  final List<OcrTraceBlock> blocks;

  const OcrTraceMlkit({required this.flatText, this.blocks = const []});

  Map<String, dynamic> toJson() => {
        'flatText': flatText,
        'blocks': [for (final b in blocks) b.toJson()],
      };
}

/// One recognized block: its text and its bounding box.
@immutable
class OcrTraceBlock {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrTraceBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'box': [left, top, right, bottom],
      };
}

/// Per-block classification outcome.
@immutable
class OcrTraceClassification {
  final String text;

  /// `label` | `numeric` | `noise`.
  final String kind;

  /// Label field name (`total`|`volume`|`pricePerLitre`) when a label.
  final String? field;

  /// Label weight when a label.
  final int? weight;

  /// Parsed numeric value when numeric.
  final double? value;

  /// Decimal count when numeric.
  final int? decimals;

  const OcrTraceClassification({
    required this.text,
    required this.kind,
    this.field,
    this.weight,
    this.value,
    this.decimals,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'kind': kind,
        if (field != null) 'field': field,
        if (weight != null) 'weight': weight,
        if (value != null) 'value': value,
        if (decimals != null) 'decimals': decimals,
      };
}

/// A label reconstructed by merging two adjacent blocks.
@immutable
class OcrTraceAssembledLabel {
  final String first;
  final String second;
  final String combined;
  final String field;

  const OcrTraceAssembledLabel({
    required this.first,
    required this.second,
    required this.combined,
    required this.field,
  });

  Map<String, dynamic> toJson() => {
        'first': first,
        'second': second,
        'combined': combined,
        'field': field,
      };
}

/// One label→numeric anchor candidate.
@immutable
class OcrTraceAnchor {
  final String labelField;
  final String labelText;
  final double numericValue;

  /// Squared centre distance label↔numeric (the anchoring score).
  final double sqDistance;

  /// `true` for the nearest candidate the binder actually chose.
  final bool chosen;

  const OcrTraceAnchor({
    required this.labelField,
    required this.labelText,
    required this.numericValue,
    required this.sqDistance,
    required this.chosen,
  });

  Map<String, dynamic> toJson() => {
        'labelField': labelField,
        'labelText': labelText,
        'numericValue': numericValue,
        'sqDistance': sqDistance,
        'chosen': chosen,
      };
}

/// One magnitude-fallback bucket decision for a leftover numeric.
@immutable
class OcrTraceFallback {
  final String field;
  final double value;
  final int decimals;

  /// Why this leftover landed in [field] (e.g. `3-dec in price band`).
  final String reason;

  const OcrTraceFallback({
    required this.field,
    required this.value,
    required this.decimals,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'value': value,
        'decimals': decimals,
        'reason': reason,
      };
}

/// The cross-check derivation: which of the three identity branches ran.
@immutable
class OcrTraceCrossCheck {
  final double? total;
  final double? volume;
  final double? price;

  /// `total`|`volume`|`pricePerLitre`|`none` — which field was derived.
  final String derivedPath;

  /// The arithmetic computed value of the derived field, when one ran.
  final double? computed;

  const OcrTraceCrossCheck({
    this.total,
    this.volume,
    this.price,
    required this.derivedPath,
    this.computed,
  });

  Map<String, dynamic> toJson() => {
        if (total != null) 'total': total,
        if (volume != null) 'volume': volume,
        if (price != null) 'price': price,
        'derivedPath': derivedPath,
        if (computed != null) 'computed': computed,
      };
}

/// Per-component confidence breakdown.
@immutable
class OcrTraceConfidence {
  final bool hasTotal;
  final bool hasVolume;
  final bool hasPrice;
  final bool isConsistent;
  final double total;

  const OcrTraceConfidence({
    required this.hasTotal,
    required this.hasVolume,
    required this.hasPrice,
    required this.isConsistent,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'hasTotal': hasTotal,
        'hasVolume': hasVolume,
        'hasPrice': hasPrice,
        'isConsistent': isConsistent,
        'total': total,
      };
}

/// The ordered validation-gate decision.
@immutable
class OcrTraceGate {
  final List<OcrTraceGateCheck> checks;
  final String reason;
  final bool accepted;
  final double? identityDelta;

  const OcrTraceGate({
    this.checks = const [],
    required this.reason,
    required this.accepted,
    this.identityDelta,
  });

  Map<String, dynamic> toJson() => {
        'checks': [for (final c in checks) c.toJson()],
        'reason': reason,
        'accepted': accepted,
        if (identityDelta != null) 'identityDelta': identityDelta,
      };
}

/// One ordered gate check (range / identity / confidence).
@immutable
class OcrTraceGateCheck {
  final String name;
  final bool passed;

  const OcrTraceGateCheck({required this.name, required this.passed});

  Map<String, dynamic> toJson() => {'name': name, 'passed': passed};
}
