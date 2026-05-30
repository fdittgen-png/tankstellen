// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../../core/logging/error_logger.dart';
import 'ocr_image_preprocessor.dart';

/// Re-encodes [jpegBytes] with any EXIF orientation baked into the
/// pixel data (#1711).
///
/// A camera capture stores the raw sensor orientation plus an EXIF tag
/// describing how to rotate it for display. ML Kit's
/// `InputImage.fromFilePath` does not reliably apply that tag, so a
/// sideways capture reaches the recognizer rotated and OCR fails. This
/// applies the rotation to the pixels and clears the tag, so the
/// recognizer always sees an upright image.
///
/// Returns the upright JPEG bytes, or `null` when the input cannot be
/// decoded as a JPEG — the caller then OCRs the original unchanged.
Uint8List? bakeImageOrientation(Uint8List jpegBytes) {
  try {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) return null;
    final upright = img.bakeOrientation(decoded);
    return img.encodeJpg(upright, quality: 90);
  } catch (e, st) {
    // A malformed / non-JPEG file is not fatal — OCR the original.
    unawaited(errorLogger.log(ErrorLayer.storage, e, st,
        context: const {'where': 'bakeImageOrientation: decode failed'}));
    return null;
  }
}

/// Re-encodes a pump-display capture for OCR (#2275, replacing #1860).
///
/// The #1860 pass did `grayscale → normalize → contrast(140)` over the
/// **whole frame** — a *global* operation that AMPLIFIES specular glare
/// (a bright reflection drags the whole histogram and crushes the
/// digits beside it) and never used the reticle the user framed. This
/// rebuild:
///
///   1. **bakes EXIF orientation** (phone-hold correction);
///   2. **crops to the reticle [roi]** FIRST so all downstream work is
///      on the readout, not the metrology stickers / card reader;
///   3. **grayscale** — colour is noise on a monochrome LCD;
///   4. **denoise** — a light blur before thresholding;
///   5. **Sauvola adaptive (local) binarization** — each pixel is
///      thresholded against its own neighbourhood, so a reflection on
///      one corner no longer blows out the digits elsewhere;
///   6. **morphological close** — bridges the gaps adaptive
///      thresholding leaves between a glyph's strokes.
///
/// Scoped to the pump-display path only — `scanReceipt`'s prose-receipt
/// OCR keeps the plain [bakeImageOrientation] path. Returns the
/// processed JPEG bytes, or `null` when the input cannot be decoded.
Uint8List? preprocessPumpDisplayForOcr(
  Uint8List jpegBytes, {
  OcrNormalizedRect? roi,
  OcrImagePreprocessor preprocessor = const OcrImagePreprocessor(),
}) {
  try {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) return null;
    final upright = img.bakeOrientation(decoded);
    final cropped =
        roi != null ? preprocessor.cropToRoi(upright, roi) : upright;
    final gray = preprocessor.toGrayscale(cropped);
    final denoised = preprocessor.denoise(gray);
    final binary = preprocessor.sauvolaBinarize(denoised);
    final closed = preprocessor.morphologicalClose(binary);
    return img.encodeJpg(closed, quality: 90);
  } catch (e, st) {
    // A malformed / non-JPEG file is not fatal — OCR the original.
    unawaited(errorLogger.log(ErrorLayer.storage, e, st,
        context: const {
          'where': 'preprocessPumpDisplayForOcr: decode failed'
        }));
    return null;
  }
}
