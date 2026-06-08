// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
    final recognized =
        await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return (text: recognized.text, blocks: mapRecognizedText(recognized));
  }

  @override
  void dispose() => _recognizer.close();
}
