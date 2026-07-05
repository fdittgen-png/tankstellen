// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'ocr_text_engine.dart';

/// Libre / F-Droid text-OCR engine: an explicit no-op (#3490, epic #3473).
///
/// On the GMS-free build the ML Kit text-recognition plugin is swapped for a
/// zero-native-code stub (`tool/fdroid_stubs/google_mlkit_text_recognition`),
/// so there is no on-device OCR backend. Rather than let a call reach the stub
/// and pretend, this returns `null` — the SAME "no data" outcome
/// [ReceiptScanService] already handles when a recognize pass fails — so
/// receipt scanning and pump-display OCR degrade cleanly to manual entry.
///
/// Making libre OCR an EXPLICIT no-op (selected on [AppFlavor.isLibre] in the
/// factory) — rather than a caught `MissingPluginException` at runtime — is
/// what lets the fdroid variant drop the proprietary `com.google.mlkit.*`
/// references entirely, with no libre code path ever touching them. Play + iOS
/// keep their real ML Kit / Vision engines unchanged.
class NoopOcrTextEngine implements OcrTextEngine {
  const NoopOcrTextEngine();

  @override
  Future<OcrTextResult?> recognize(
    String imagePath, {
    bool languageCorrection = true,
    List<String> languages = const [],
  }) async =>
      null;

  @override
  void dispose() {/* Nothing to release — the no-op holds no resources. */}
}
