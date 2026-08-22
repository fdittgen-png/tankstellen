// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

// Receipt-path + final-read leaf models of the OCR trace package (#2517),
// split off `ocr_trace_models.dart` to stay under the 400-line norm.

/// Receipt-path brand detect + layout + overrides + reconcile.
@immutable
class OcrTraceReceipt {
  final String? brand;
  final String layout;
  final List<OcrTraceOverride> overrides;
  final OcrTraceReconcile? reconcile;

  const OcrTraceReceipt({
    this.brand,
    required this.layout,
    this.overrides = const [],
    this.reconcile,
  });

  Map<String, dynamic> toJson() => {
        if (brand != null) 'brand': brand,
        'layout': layout,
        if (overrides.isNotEmpty)
          'overrides': [for (final o in overrides) o.toJson()],
        if (reconcile != null) 'reconcile': reconcile!.toJson(),
      };
}

/// One per-station override field that fired.
@immutable
class OcrTraceOverride {
  final String field;
  final String pattern;
  final String match;
  final double? value;

  const OcrTraceOverride({
    required this.field,
    required this.pattern,
    required this.match,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'pattern': pattern,
        'match': match,
        if (value != null) 'value': value,
      };
}

/// The receipt reconcile invariant outcome.
@immutable
class OcrTraceReconcile {
  final double? read;
  final double? derived;
  final double? predictedTotal;
  final double? delta;

  const OcrTraceReconcile({
    this.read,
    this.derived,
    this.predictedTotal,
    this.delta,
  });

  Map<String, dynamic> toJson() => {
        if (read != null) 'read': read,
        if (derived != null) 'derived': derived,
        if (predictedTotal != null) 'predictedTotal': predictedTotal,
        if (delta != null) 'delta': delta,
      };
}

/// The final read: the three values + which were derived vs read.
@immutable
class OcrTraceResult {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;
  final Set<String> derived;
  final double confidence;
  final bool validated;
  final String? validationReason;

  const OcrTraceResult({
    this.totalCost,
    this.liters,
    this.pricePerLiter,
    this.derived = const {},
    this.confidence = 0,
    this.validated = false,
    this.validationReason,
  });

  Map<String, dynamic> toJson() => {
        if (totalCost != null) 'totalCost': totalCost,
        if (liters != null) 'liters': liters,
        if (pricePerLiter != null) 'pricePerLiter': pricePerLiter,
        'derived': derived.toList(),
        'confidence': confidence,
        'validated': validated,
        if (validationReason != null) 'validationReason': validationReason,
      };
}

/// Expected ground-truth values, attached during fixture promotion.
@immutable
class OcrTraceExpected {
  final double? totalCost;
  final double? liters;
  final double? pricePerLiter;

  const OcrTraceExpected({this.totalCost, this.liters, this.pricePerLiter});

  Map<String, dynamic> toJson() => {
        if (totalCost != null) 'totalCost': totalCost,
        if (liters != null) 'liters': liters,
        if (pricePerLiter != null) 'pricePerLiter': pricePerLiter,
      };
}

/// The capture image carried for export — base64 plus the sibling file
/// name the tester writes next to the JSON.
@immutable
class OcrTraceImage {
  final String fileName;
  final String base64;

  const OcrTraceImage({required this.fileName, required this.base64});

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'base64': base64,
      };
}
