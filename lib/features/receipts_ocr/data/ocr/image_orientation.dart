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
