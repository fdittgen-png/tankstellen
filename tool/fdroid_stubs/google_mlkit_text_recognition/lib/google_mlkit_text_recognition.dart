// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Libre / F-Droid no-op stub for `google_mlkit_text_recognition` (#3490,
/// epic #3473).
///
/// Provides the exact Dart surface the app compiles against so
/// `mlkit_ocr_text_engine.dart` + `recognized_text_adapter.dart` build on the
/// libre flavor, while carrying NO native code and NO `com.google.mlkit.*`
/// references. It is never reached at runtime on libre: the OCR factory selects
/// `NoopOcrTextEngine` when `AppFlavor.isLibre`, so the ML Kit engine is folded
/// out — this only needs to COMPILE.
library;

import 'dart:ui';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';

export 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// The ML Kit scripts the real plugin supports. Only [latin] is used by the
/// app (the default), but the full set is kept so any script argument still
/// compiles.
enum TextRecognitionScript { latin, chinese, devanagari, japanese, korean }

/// No-op stand-in for ML Kit's `TextRecognizer`. Recognizes nothing.
class TextRecognizer {
  TextRecognizer({this.script = TextRecognitionScript.latin});

  final TextRecognitionScript script;

  /// Always returns an empty result on libre — no on-device ML Kit backend.
  Future<RecognizedText> processImage(InputImage inputImage) async =>
      RecognizedText(text: '', blocks: const []);

  Future<void> close() async {}
}

/// Value stand-in for ML Kit's `RecognizedText`.
class RecognizedText {
  RecognizedText({required this.text, required this.blocks});

  final String text;
  final List<TextBlock> blocks;
}

/// Value stand-in for ML Kit's `TextBlock`.
class TextBlock {
  TextBlock({
    required this.text,
    required this.lines,
    required this.boundingBox,
  });

  final String text;
  final List<TextLine> lines;
  final Rect boundingBox;
}

/// Value stand-in for ML Kit's `TextLine`.
class TextLine {
  TextLine({required this.text, required this.boundingBox});

  final String text;
  final Rect boundingBox;
}
