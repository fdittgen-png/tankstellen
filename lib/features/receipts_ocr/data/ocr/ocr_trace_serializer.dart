// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'ocr_trace_package.dart';

/// Serialises an [OcrTracePackage] to a self-contained, pretty-printed
/// JSON document (#2517) — mirrors `formatObd2DebugSessionXml` but JSON.
///
/// This is the format the gated OCR tester (Epic #2516 Child 2) exports
/// for developer analysis of a pump / receipt read: the full reasoning
/// chain (geometry classification, anchor candidates, magnitude fallback,
/// cross-check derivation, confidence breakdown, the ordered gate checks,
/// and the final read), carried as `schema: 1`.
///
/// Shape (abridged):
///
/// ```json
/// {
///   "schema": 1,
///   "kind": "pump",
///   "capturedAt": "2026-05-31T08:00:00.000Z",
///   "input": { "country": "FR", "profile": { ... } },
///   "mlkit": { "flatText": "PRIX 18,59 ...", "blocks": [ ... ] },
///   "classification": [ { "text": "PRIX", "kind": "label", ... } ],
///   "anchors": [ { "labelField": "total", "chosen": true, ... } ],
///   "crossCheck": { "derivedPath": "pricePerLitre", "computed": 0.798 },
///   "gate": { "checks": [ ... ], "reason": "consistent" },
///   "result": { "totalCost": 18.59, "derived": [], ... }
/// }
/// ```
///
/// [includeImage] defaults to `true` (the file / fixture export carries the
/// base64 capture). Pass `false` for size-bounded sinks like the clipboard
/// (#2853) — the ~5 MB base64 blob is meaningless as pasted text and trips
/// Android's ~1 MB Binder limit.
String formatOcrTracePackageJson(
  OcrTracePackage package, {
  bool includeImage = true,
}) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(package.toJson(includeImage: includeImage));
}
