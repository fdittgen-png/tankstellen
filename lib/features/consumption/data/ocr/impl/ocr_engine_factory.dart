// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import '../mlkit_ocr_text_engine.dart';
import '../ocr_text_engine.dart';

/// Picks the platform's text-OCR backend (#3052): Apple **Vision** on iOS
/// (native, no Google, simulator-buildable), Google **ML Kit** everywhere
/// else (Android production — unchanged).
///
/// Lives in `impl/` so the `Platform.isIOS` branch stays out of shared code
/// (enforced by `test/lint/no_inline_platform_check_test.dart`).
OcrTextEngine createDefaultOcrTextEngine() =>
    Platform.isIOS ? VisionOcrTextEngine() : MlKitOcrTextEngine();
