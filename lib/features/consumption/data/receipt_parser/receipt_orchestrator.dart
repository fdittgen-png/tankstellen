// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../ocr/ocr_trace_recorder.dart';
import '../ocr/pump_ocr_config.dart';
import '../ocr/pump_validation_gate.dart';
import '../ocr/recognized_text_block.dart';
import 'brand_detection.dart';
import 'receipt_field_extractors.dart';
import 'receipt_label_anchored_extractor.dart';
import 'receipt_label_table.dart';
import 'receipt_parse_result.dart';

/// Orchestrates the #2848 geometry-aware fuel-receipt read.
///
/// The receipt cousin of `orchestratePumpDisplayParse`: it runs the
/// label-anchored extractor over ML Kit's [blocks] (binding Volume→litres,
/// Prix→€/L, TOT TTC→total by row alignment), scores a confidence, runs
/// the SAME per-country [PumpValidationGate] (in-range + `litres × €/L ≈
/// total`), and folds the geometry numbers together with the
/// date/station/fuel still read from the flat [text]. Returns a
/// `ReceiptParseResult` with `validated` / `confidence` set.
ReceiptParseResult orchestrateReceiptParse({
  required List<RecognizedTextBlock> blocks,
  required String text,
  required List<String> lines,
  OcrLocaleProfile? profile,
  PumpValidationGate gate = const PumpValidationGate(),
  OcrTraceRecorder? trace,
}) {
  final anchored = extractReceiptByLabelAnchor(blocks);

  // Prose fields the geometry path never produces — read from flat text.
  final date = extractDate(text);
  final stationName = extractStationName(lines);
  final fuelType = extractFuelType(text);

  final confidence = _confidenceFor(anchored);
  final result = gate.evaluate(
    total: anchored.totalCost,
    volume: anchored.liters,
    pricePerLitre: anchored.pricePerLiter,
    confidence: confidence,
    profile: profile,
    trace: trace,
  );
  final derivedNames = anchored.derived.map(pumpFieldName).toSet();
  trace?.result(
    totalCost: anchored.totalCost,
    liters: anchored.liters,
    pricePerLiter: anchored.pricePerLiter,
    derived: derivedNames,
    confidence: confidence,
    validated: profile != null && result.accepted,
    validationReason: result.reason,
  );

  return ReceiptParseResult(
    liters: anchored.liters,
    totalCost: anchored.totalCost,
    pricePerLiter: anchored.pricePerLiter,
    date: date,
    stationName: stationName,
    fuelType: fuelType,
    brandLayout: 'fuel_station',
    confidence: confidence,
    validated: profile != null && result.accepted,
    validationReason: result.reason,
    derived: derivedNames,
  );
}

/// `true` when [text] / [blocks] look like a fuel-station receipt that
/// should route to [orchestrateReceiptParse] instead of the generic
/// flat-string parser. Conservative: needs the fuel-pump markers AND a
/// per-litre price signal (see [looksLikeFuelStationReceipt]).
bool shouldUseReceiptLabelAnchor(String text, List<RecognizedTextBlock> blocks) {
  if (blocks.length < 2) return false;
  return looksLikeFuelStationReceipt(text);
}

double _confidenceFor(ReceiptAnchoredResult r) {
  var score = 0.0;
  if (r.totalCost != null) score += 0.3;
  if (r.liters != null) score += 0.3;
  if (r.pricePerLiter != null) score += 0.3;
  if (r.isConsistent) score += 0.1;
  return score.clamp(0.0, 1.0);
}
