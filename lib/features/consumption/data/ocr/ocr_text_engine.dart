// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';

import 'recognized_text_block.dart';

/// The recognized text from one OCR pass: the flat string (legacy fallback
/// parsers) plus the per-line geometry the #2478 label-anchored extractor
/// needs. Mirrors the tuple `ReceiptScanService` already passes around.
typedef OcrTextResult = ({String text, List<RecognizedTextBlock> blocks});

/// Pluggable on-device text-OCR backend (#3052).
///
/// Lets iOS use Apple's native **Vision** framework while Android keeps Google
/// ML Kit unchanged (Android is in production — its path is untouched). The
/// result type is the app's PURE [RecognizedTextBlock] list, so everything
/// downstream (the receipt + pump-display parsers) is engine-agnostic.
abstract class OcrTextEngine {
  /// Runs OCR on the (already EXIF-upright / preprocessed) image at
  /// [imagePath]. Returns null on any recognize error so the caller degrades
  /// exactly as before. [languageCorrection] is off for 7-segment pump
  /// displays (digits, not prose). [languages] is an optional priority list of
  /// BCP-47 codes (e.g. `fr-FR`); empty lets the engine auto-detect.
  Future<OcrTextResult?> recognize(
    String imagePath, {
    bool languageCorrection = true,
    List<String> languages = const [],
  });

  /// Releases native resources (ML Kit holds a recognizer; Vision is
  /// stateless). Default no-op so stateless engines need not override.
  void dispose() {}
}

/// iOS engine backed by Apple Vision (`VNRecognizeTextRequest`) over the
/// `tankstellen/vision_ocr` MethodChannel handled by `VisionOcrBridge` in
/// `ios/Runner/AppDelegate.swift`. The Swift side already converts Vision's
/// normalized, bottom-left boxes into pixel, top-left coordinates so the
/// [OcrBox] geometry matches what the ML Kit adapter produces.
class VisionOcrTextEngine implements OcrTextEngine {
  VisionOcrTextEngine({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('tankstellen/vision_ocr');

  final MethodChannel _channel;

  @override
  Future<OcrTextResult?> recognize(
    String imagePath, {
    bool languageCorrection = true,
    List<String> languages = const [],
  }) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      'recognizeText',
      {
        'path': imagePath,
        'languageCorrection': languageCorrection,
        'languages': languages,
      },
    );
    if (res == null) return null;
    final text = (res['text'] as String?) ?? '';
    final rawBlocks = (res['blocks'] as List?) ?? const [];
    final blocks = <RecognizedTextBlock>[];
    for (final entry in rawBlocks) {
      final m = (entry as Map).cast<String, dynamic>();
      final boxText = (m['text'] as String?) ?? '';
      if (boxText.isEmpty) continue;
      blocks.add(
        RecognizedTextBlock(
          text: boxText,
          box: OcrBox(
            left: (m['left'] as num).toDouble(),
            top: (m['top'] as num).toDouble(),
            right: (m['right'] as num).toDouble(),
            bottom: (m['bottom'] as num).toDouble(),
          ),
        ),
      );
    }
    return (text: text, blocks: blocks);
  }

  @override
  void dispose() {/* Vision is stateless — nothing to release. */}
}
