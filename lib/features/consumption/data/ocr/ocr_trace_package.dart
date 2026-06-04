// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import 'ocr_trace_models.dart';
import 'ocr_trace_result_models.dart';

// The leaf sub-models live in `ocr_trace_models.dart` (pump-side) and
// `ocr_trace_result_models.dart` (receipt + final read), kept under the
// 400-line norm; re-exported so importers of this file see one unit.
export 'ocr_trace_models.dart';
export 'ocr_trace_result_models.dart';

/// The serialise-ready OCR reasoning trace (#2517, Epic #2516).
///
/// A [OcrTracePackage] is the side-channel snapshot the dev tester (a
/// later Epic child) reads back after running the pump / receipt pipeline
/// with a non-null `OcrTraceRecorder`. It captures the WHOLE reasoning
/// chain — geometry classification, every anchor candidate, the magnitude
/// fallback buckets, the cross-check derivation branch, the per-component
/// confidence, the ordered validation-gate checks and the final read —
/// none of which the result types expose. Production never builds one
/// (the recorder is null), so this model has ZERO runtime cost there.
///
/// PURE Dart, no freezed: hand-written immutable classes + `toJson()` so
/// the foundation adds no codegen and the package round-trips through the
/// JSON serialiser (`formatOcrTracePackageJson`) with `schema: 1`.
@immutable
class OcrTracePackage {
  /// On-disk/serialisation schema version. Bumped when a field's meaning
  /// changes so a stored fixture can be migrated.
  static const int schema = 1;

  /// Which pipeline produced the trace — pump display or paper receipt.
  final OcrTraceKind kind;

  /// When the trace was captured (UTC instant).
  final DateTime capturedAt;

  /// Active region / profile inputs the pipeline ran against.
  final OcrTraceInput input;

  /// Glare-rejection preprocessing decision (pump path).
  final OcrTracePreprocess? preprocess;

  /// ML Kit output: the flat string + each recognized block with its box.
  final OcrTraceMlkit? mlkit;

  /// Per-block label|numeric|noise classification.
  final List<OcrTraceClassification> classification;

  /// Split-label merges ("PRIX DU" + "LITRE" → unit-price label).
  final List<OcrTraceAssembledLabel> assembledLabels;

  /// Every label→numeric anchor candidate, with the chosen one flagged.
  final List<OcrTraceAnchor> anchors;

  /// Magnitude-fallback bucket decisions for still-unbound fields.
  final List<OcrTraceFallback> magnitudeFallback;

  /// The `total ≈ volume × €/L` cross-check derivation, when it ran.
  final OcrTraceCrossCheck? crossCheck;

  /// Per-component + total confidence breakdown.
  final OcrTraceConfidence? confidence;

  /// Ordered validation-gate checks + final reason + identity delta.
  final OcrTraceGate? gate;

  /// Receipt brand detect + dispatched layout + per-field overrides +
  /// reconcile (receipt path).
  final OcrTraceReceipt? receipt;

  /// The final read — what was read directly vs derived.
  final OcrTraceResult? result;

  /// Optional expected values, set when promoting a real capture to a
  /// regression fixture (a later Epic child wires this).
  final OcrTraceExpected? expected;

  /// The capture as base64 + the sibling file name the tester writes
  /// alongside the JSON. Null in unit replays (blocks only, no image).
  final OcrTraceImage? image;

  const OcrTracePackage({
    required this.kind,
    required this.capturedAt,
    required this.input,
    this.preprocess,
    this.mlkit,
    this.classification = const [],
    this.assembledLabels = const [],
    this.anchors = const [],
    this.magnitudeFallback = const [],
    this.crossCheck,
    this.confidence,
    this.gate,
    this.receipt,
    this.result,
    this.expected,
    this.image,
  });

  /// Serialises the trace. The capture [image] is ~5 MB of base64 and is
  /// only meaningful as a sibling file, so callers headed for a size-bounded
  /// sink (the clipboard — #2853, Android's Binder limit is ~1 MB) pass
  /// `includeImage: false` to elide it; the file/fixture export keeps the
  /// default so the source frame still rides alongside the JSON.
  Map<String, dynamic> toJson({bool includeImage = true}) => {
        'schema': schema,
        'kind': kind.name,
        'capturedAt': capturedAt.toIso8601String(),
        'input': input.toJson(),
        if (preprocess != null) 'preprocess': preprocess!.toJson(),
        if (mlkit != null) 'mlkit': mlkit!.toJson(),
        if (classification.isNotEmpty)
          'classification': [for (final c in classification) c.toJson()],
        if (assembledLabels.isNotEmpty)
          'assembledLabels': [for (final a in assembledLabels) a.toJson()],
        if (anchors.isNotEmpty)
          'anchors': [for (final a in anchors) a.toJson()],
        if (magnitudeFallback.isNotEmpty)
          'magnitudeFallback': [for (final f in magnitudeFallback) f.toJson()],
        if (crossCheck != null) 'crossCheck': crossCheck!.toJson(),
        if (confidence != null) 'confidence': confidence!.toJson(),
        if (gate != null) 'gate': gate!.toJson(),
        if (receipt != null) 'receipt': receipt!.toJson(),
        if (result != null) 'result': result!.toJson(),
        if (expected != null) 'expected': expected!.toJson(),
        if (includeImage && image != null) 'image': image!.toJson(),
      };
}

/// Which pipeline a [OcrTracePackage] came from.
enum OcrTraceKind { pump, receipt }

/// Active region inputs the pipeline ran against.
@immutable
class OcrTraceInput {
  final String? country;
  final String? brand;

  /// Reticle ROI as `left,top,width,height` (normalised 0..1), when set.
  final List<double>? roi;

  /// The resolved locale profile (priceMin/Max, volumeMax, totalMax, …).
  final Map<String, dynamic>? profile;

  const OcrTraceInput({this.country, this.brand, this.roi, this.profile});

  Map<String, dynamic> toJson() => {
        if (country != null) 'country': country,
        if (brand != null) 'brand': brand,
        if (roi != null) 'roi': roi,
        if (profile != null) 'profile': profile,
      };
}
