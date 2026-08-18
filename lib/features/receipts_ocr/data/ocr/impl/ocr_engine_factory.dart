// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import '../../../../../core/platform/app_flavor.dart';
import '../mlkit_ocr_text_engine.dart';
import '../noop_ocr_text_engine.dart';
import '../ocr_text_engine.dart';

/// Picks the platform's text-OCR backend (#3052): Apple **Vision** on iOS
/// (native, no Google, simulator-buildable), Google **ML Kit** everywhere
/// else (Android production — unchanged).
///
/// #3490 — on the GMS-free / F-Droid (libre) build there is no proprietary OCR
/// backend: the ML Kit plugin is swapped for a zero-native-code stub to keep
/// the dex free of `com.google.mlkit.*`, so the libre build gets the explicit
/// [NoopOcrTextEngine]. Receipt / pump OCR then degrade to manual entry (the
/// same null-result path a failed recognize already takes); Play + iOS keep
/// their real engines. Selecting on [AppFlavor.isLibre] — a compile-time
/// constant — lets R8 fold the ML Kit branch out of the libre build entirely.
///
/// Lives in `impl/` so the `Platform.isIOS` branch stays out of shared code
/// (enforced by `test/lint/no_inline_platform_check_test.dart`).
OcrTextEngine createDefaultOcrTextEngine() {
  if (AppFlavor.isLibre) return const NoopOcrTextEngine();
  return Platform.isIOS ? VisionOcrTextEngine() : MlKitOcrTextEngine();
}
