// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/logging/error_logger.dart';
import 'ocr_text_engine.dart';
import 'recognized_text_adapter.dart';

/// Google ML Kit text-OCR engine — the **Android** (and test-host) backend
/// (#3052). This is the exact recognition path the app shipped before the
/// engine seam existed: `TextRecognizer.processImage` + the #2478
/// `mapRecognizedText` block-geometry adapter. Android is in production and
/// its behaviour is unchanged — only its location moved out of
/// `ReceiptScanService`.
///
/// ML Kit ignores [languageCorrection] / [languages] (it auto-detects); they
/// exist only so the [OcrTextEngine] contract is uniform with the iOS Vision
/// engine, which honours them.
class MlKitOcrTextEngine implements OcrTextEngine {
  MlKitOcrTextEngine({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer();

  final TextRecognizer _recognizer;

  @override
  Future<OcrTextResult?> recognize(
    String imagePath, {
    bool languageCorrection = true,
    List<String> languages = const [],
  }) async {
    try {
      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(imagePath));
      return (text: recognized.text, blocks: mapRecognizedText(recognized));
    } catch (e, st) {
      // Upstream (`ReceiptScanService`) already catches — log here so the
      // recognizer-level failure reason survives into the trace export.
      unawaited(errorLogger.log(ErrorLayer.services, e, st,
          context: const {'ocrFailureReason': 'recognizerThrow'}));
      rethrow;
    }
  }

  @override
  void dispose() => _recognizer.close();
}
