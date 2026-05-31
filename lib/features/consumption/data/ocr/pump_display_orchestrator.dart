// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../pump_display_parser.dart';
import 'label_anchored_extractor.dart';
import 'ocr_trace_recorder.dart';
import 'pump_ocr_config.dart';
import 'pump_validation_gate.dart';
import 'recognized_text_block.dart';

/// Orchestrates the #2478 pump-display read on recognized ML Kit [blocks]
/// (the PRIMARY label-anchored path) with the flat-string
/// [PumpDisplayParser] as a fallback, then the per-country validation
/// gate. Split out of `receipt_scan_service.dart` so the geometry logic
/// is unit-testable without a platform channel and the service file stays
/// under the 400-line norm.
///
///  1. **Label-anchored extraction** — geometry-aware, recovers the
///     dropped PRIX DU LITRE unit price and cross-checks the arithmetic.
///  2. **Flat-string parser** — when fewer than two fields bind from
///     geometry (block boxes too sparse / fused), fall back to the
///     existing pollution-strip + regex + positional-inference parser so
///     the German / Carrefour / Super-U paths stay unchanged.
///  3. **Validation gate** — the same per-country range + identity gate
///     decides `validated`, whichever path produced the values.
PumpDisplayParseResult orchestratePumpDisplayParse({
  required List<RecognizedTextBlock> blocks,
  required String text,
  OcrLocaleProfile? profile,
  PumpDisplayParser parser = const PumpDisplayParser(),
  PumpValidationGate gate = const PumpValidationGate(),
  OcrTraceRecorder? trace,
}) {
  final anchored = extractByLabelAnchor(blocks, profile: profile, trace: trace);
  if (anchored.boundCount < 2) {
    // Geometry too sparse to anchor — defer to the flat-string parser,
    // which keeps the legacy German / receipt-style behaviour.
    final fallback = parser.parse(text, profile: profile);
    trace?.result(
      totalCost: fallback.totalCost,
      liters: fallback.liters,
      pricePerLiter: fallback.pricePerLiter,
      derived: fallback.derived,
      confidence: fallback.confidence,
      validated: fallback.validated,
      validationReason: 'flat-string-fallback',
    );
    return fallback;
  }
  final confidence = _confidenceFor(anchored);
  trace?.confidence(
    hasTotal: anchored.totalCost != null,
    hasVolume: anchored.liters != null,
    hasPrice: anchored.pricePerLiter != null,
    isConsistent: anchored.isConsistent,
    total: confidence,
  );
  final result = gate.evaluate(
    total: anchored.totalCost,
    volume: anchored.liters,
    pricePerLitre: anchored.pricePerLiter,
    confidence: confidence,
    profile: profile,
    trace: trace,
  );
  trace?.result(
    totalCost: anchored.totalCost,
    liters: anchored.liters,
    pricePerLiter: anchored.pricePerLiter,
    derived: anchored.derived.map(pumpFieldName).toSet(),
    confidence: confidence,
    validated: profile != null && result.accepted,
    validationReason: result.reason,
  );
  return PumpDisplayParseResult(
    totalCost: anchored.totalCost,
    liters: anchored.liters,
    pricePerLiter: anchored.pricePerLiter,
    confidence: confidence,
    validated: profile != null && result.accepted,
    validationReason: result.reason,
    derived: anchored.derived.map(pumpFieldName).toSet(),
  );
}

double _confidenceFor(LabelAnchoredResult r) {
  var score = 0.0;
  if (r.totalCost != null) score += 0.3;
  if (r.liters != null) score += 0.3;
  if (r.pricePerLiter != null) score += 0.3;
  if (r.isConsistent) score += 0.1;
  return score.clamp(0.0, 1.0);
}
