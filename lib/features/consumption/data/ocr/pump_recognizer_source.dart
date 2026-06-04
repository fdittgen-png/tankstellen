// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../../../../core/logging/error_logger.dart';
import '../pump_display_parse_result.dart';
import 'ocr_image_preprocessor.dart';
import 'ocr_trace_recorder.dart';
import 'pump_ocr_config.dart';
import 'pump_ocr_recognizer.dart';
import 'pump_validation_gate.dart';

/// Resolves the #2830 recognizer-source inputs for the pump-display scan.
///
/// Returns a non-null `(frame, fields)` pair ONLY when a brand template
/// with `pumpDisplay` ROIs matches [country]/[brand] (FR/Tokheim today).
/// In that case the captured JPEG at [path] is decoded once,
/// EXIF-uprighted, and cropped to the reticle [roi] (the ROIs in the
/// template are relative to the reticle-cropped frame), so the
/// orchestrator can run the 7-segment recognizer over the field ROIs.
/// Everywhere else both are null and the orchestrator skips the source
/// entirely — production is unchanged.
///
/// Best-effort: any decode error logs and degrades to `(null, null)` so
/// a quirky image still completes via the existing two sources.
Future<({img.Image? frame, OcrPumpFieldSpec? fields})> resolveRecognizerSource(
  String path,
  String? country,
  String? brand,
  OcrNormalizedRect? roi, {
  required PumpOcrConfig config,
  OcrImagePreprocessor preprocessor = const OcrImagePreprocessor(),
}) async {
  if (country == null) return (frame: null, fields: null);
  await config.load();
  final template = config.templateFor(country: country, brand: brand);
  final fields = template?.pumpDisplay;
  if (fields == null) return (frame: null, fields: null);
  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) return (frame: null, fields: null);
    final upright = img.bakeOrientation(decoded);
    final frame = roi != null ? preprocessor.cropToRoi(upright, roi) : upright;
    return (frame: frame, fields: fields);
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st,
        context: const {'where': 'pump recognizer-source decode failed'}));
    return (frame: null, fields: null);
  }
}

/// The #2830 STRICTLY-ADDITIVE 3rd parse source: the on-device
/// 7-segment [PumpOcrRecognizer] read, merged against the winner the
/// existing two sources (label-anchored + flat-string) already produced.
///
/// The recognizer wins ONLY when its read clears **all three** bars,
/// otherwise the [existing] result stands untouched:
///
///  1. it recovers **≥ 2** of the three fields, AND
///  2. it passes the **same** [PumpValidationGate] the other sources do
///     (range + identity, country-config-driven), AND
///  3. it reads **at least as many fields** as [existing] did — so a
///     thinner recognizer read can never displace a richer existing one.
///
/// This is why production stays unchanged today: the only brand template
/// carrying `pumpDisplay` ROIs is FR/Tokheim, so [mergeRecognizerSource]
/// is only ever reached for that path; everywhere else [frame] /
/// [fields] are null and [existing] is returned verbatim. It also never
/// regresses the FR `fr_tokheim_18_59` label-anchored read nor the
/// German flat-string read — both already bind ≥2 fields, so the
/// recognizer must MATCH OR BEAT that count *and* pass the gate to win.
///
/// Returns a record carrying the chosen [PumpDisplayParseResult] plus
/// whether the recognizer won, so callers can trace the decision.
({PumpDisplayParseResult result, bool recognizerWon}) mergeRecognizerSource({
  required PumpDisplayParseResult existing,
  required img.Image frame,
  required OcrPumpFieldSpec fields,
  OcrLocaleProfile? profile,
  PumpOcrRecognizer recognizer = const PumpOcrRecognizer(),
  PumpValidationGate gate = const PumpValidationGate(),
  OcrTraceRecorder? trace,
}) {
  final read = recognizer.recognizeWithSweep(frame, fields);
  if (read.glareRejected || read.fieldCount < 2) {
    return (result: existing, recognizerWon: false);
  }

  final gateResult = gate.evaluate(
    total: read.total,
    volume: read.volume,
    pricePerLitre: read.pricePerLitre,
    confidence: read.confidence,
    profile: profile,
  );
  // The recognizer source is only ever accepted as VALIDATED — it must
  // clear the same country gate the other two sources answer to. A
  // gate-rejected recognizer read is discarded outright (the existing
  // winner stands), never auto-filled as a plausible-but-wrong pair.
  if (!gateResult.accepted) {
    return (result: existing, recognizerWon: false);
  }

  final existingCount = [
    existing.totalCost,
    existing.liters,
    existing.pricePerLiter,
  ].where((v) => v != null).length;
  if (read.fieldCount < existingCount) {
    return (result: existing, recognizerWon: false);
  }

  final won = PumpDisplayParseResult(
    totalCost: read.total,
    liters: read.volume,
    pricePerLiter: read.pricePerLitre,
    confidence: read.confidence,
    validated: profile != null && gateResult.accepted,
    validationReason: gateResult.reason,
    validationApplied: profile != null,
  );
  trace?.result(
    totalCost: won.totalCost,
    liters: won.liters,
    pricePerLiter: won.pricePerLiter,
    derived: const {},
    confidence: won.confidence,
    validated: won.validated,
    validationReason: 'recognizer-source',
  );
  return (result: won, recognizerWon: true);
}
