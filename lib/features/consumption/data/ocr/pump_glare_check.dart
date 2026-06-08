// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../../../../core/logging/error_logger.dart';
import 'ocr_image_preprocessor.dart';
import 'ocr_trace_recorder.dart';

/// #2275 — `true` when the [roi] of the pump-display photo at [path] is
/// over-glared per [GlarePolicy.standard], so the caller can prompt a re-angle
/// BEFORE OCR rather than show a generic failure. Best-effort: a decode error
/// returns `false` so a quirky image still reaches OCR.
///
/// Extracted from `ReceiptScanService` (#3052) to keep that file decomposed.
Future<bool> isPumpFrameOverGlared(
  String path,
  OcrNormalizedRect? roi,
  OcrImagePreprocessor preprocessor, {
  OcrTraceRecorder? trace,
}) async {
  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) return false;
    final upright = img.bakeOrientation(decoded);
    final region = roi != null ? preprocessor.cropToRoi(upright, roi) : upright;
    final fraction = preprocessor.glareFraction(region);
    final threshold = GlarePolicy.standard.rejectAbove;
    final rejected = fraction > threshold;
    trace?.glare(fraction: fraction, threshold: threshold, rejected: rejected);
    return rejected;
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.storage, e, st,
        context: const {'where': 'pump glare check failed'}));
    return false;
  }
}
