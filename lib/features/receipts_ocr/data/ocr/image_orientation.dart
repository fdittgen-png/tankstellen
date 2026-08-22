// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../../core/logging/error_logger.dart';

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

/// Longest-side cap (pixels) for the temp copy handed to the OCR engine
/// (#3766). Receipt prose reads reliably from ~1080 px up; 1600 keeps
/// comfortable headroom while bounding the decoded bitmap the engine
/// (and this pipeline's own decode) must hold: a shared 4000×3000 photo
/// decodes to ~46 MB RGBA, the 1600 px copy to ~7 MB.
const int kReceiptOcrMaxDimension = 1600;

/// Re-encodes [jpegBytes] for OCR (#3766): bakes any EXIF orientation
/// into the pixels (#1711 — ML Kit ignores the tag) and, when the
/// upright image's longest side exceeds [maxDimension], downscales it
/// (aspect preserved) in the same single decode/encode pass. Images at
/// or under the cap are never upscaled — they take the exact
/// [bakeImageOrientation] output shape as before.
///
/// This runs on a temp COPY only — the original capture on disk keeps
/// its full resolution for the bad-scan report flow (#713).
///
/// Returns the processed JPEG bytes, or `null` when the input cannot be
/// decoded as a JPEG — the caller then OCRs the original unchanged.
Uint8List? prepareReceiptImageForOcr(
  Uint8List jpegBytes, {
  int maxDimension = kReceiptOcrMaxDimension,
}) {
  try {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) return null;
    var upright = img.bakeOrientation(decoded);
    final longest =
        upright.width > upright.height ? upright.width : upright.height;
    if (longest > maxDimension) {
      // `average` interpolation keeps thin receipt glyph strokes legible
      // on the way down (plain nearest-neighbour aliases them).
      upright = upright.width >= upright.height
          ? img.copyResize(upright,
              width: maxDimension, interpolation: img.Interpolation.average)
          : img.copyResize(upright,
              height: maxDimension, interpolation: img.Interpolation.average);
    }
    return img.encodeJpg(upright, quality: 90);
  } catch (e, st) {
    // A malformed / non-JPEG file is not fatal — OCR the original.
    unawaited(errorLogger.log(ErrorLayer.storage, e, st,
        context: const {'where': 'prepareReceiptImageForOcr: decode failed'}));
    return null;
  }
}
