// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'pump_display_parser.dart';
import 'receipt_parser.dart';

/// Outcome of a single receipt capture: parsed fields plus the source
/// OCR text and the path to the captured JPEG on disk. The caller is
/// responsible for deleting [imagePath] once it no longer needs it — we
/// keep the file around so the "report bad scan" flow (#713) can share
/// the photo alongside the user's corrected values.
class ReceiptScanOutcome {
  final ReceiptParseResult parse;
  final String ocrText;
  final String imagePath;

  const ReceiptScanOutcome({
    required this.parse,
    required this.ocrText,
    required this.imagePath,
  });
}

/// Outcome of a single pump-display capture: parsed fields plus the
/// source OCR text and the path to the captured JPEG on disk. Mirrors
/// [ReceiptScanOutcome] so the bad-scan reporting flow (#953) can ship
/// the photo and OCR text alongside the user's corrected values when a
/// pump-display read fails.
///
/// The caller is responsible for deleting [imagePath] once it no longer
/// needs it (form saved, user dismissed the failure flow, or report
/// submitted).
class PumpDisplayScanOutcome {
  final PumpDisplayParseResult parse;
  final String ocrText;
  final String imagePath;

  const PumpDisplayScanOutcome({
    required this.parse,
    required this.ocrText,
    required this.imagePath,
  });
}

/// Service that captures a photo and runs on-device OCR.
///
/// Uses [ImagePicker] for camera access and [TextRecognizer] from
/// Google ML Kit for on-device text recognition (no network calls).
/// Supports two capture modes:
///   - [scanReceipt] — parses a paper receipt with prose labels
///     (TOTAL, MONTANT, Prix/L, …).
///   - [scanPumpDisplay] — parses the 7-segment LCD on the pump
///     itself (Betrag / Abgabe / Preis/Liter).
class ReceiptScanService {
  final ImagePicker _picker;
  final TextRecognizer _recognizer;
  final ReceiptParser _parser;
  final PumpDisplayParser _pumpParser;

  ReceiptScanService({
    ImagePicker? picker,
    TextRecognizer? recognizer,
    ReceiptParser? parser,
    PumpDisplayParser? pumpParser,
  })  : _picker = picker ?? ImagePicker(),
        _recognizer = recognizer ?? TextRecognizer(),
        _parser = parser ?? const ReceiptParser(),
        _pumpParser = pumpParser ?? const PumpDisplayParser();

  /// Opens the camera, captures a receipt photo, runs OCR, and parses
  /// the result. Returns null if the user cancels the camera or OCR
  /// fails. The captured photo is NOT deleted — callers hold the path
  /// from [ReceiptScanOutcome.imagePath] and delete when done (e.g.
  /// after the form is saved or after the user has shared a bad-scan
  /// report).
  Future<ReceiptScanOutcome?> scanReceipt() async {
    final capture = await _capture();
    if (capture == null) return null;
    final text = await _recognise(capture);
    if (text == null) {
      await _tryDelete(capture);
      return null;
    }
    return ReceiptScanOutcome(
      parse: _parser.parse(text),
      ocrText: text,
      imagePath: capture,
    );
  }

  /// Opens the camera, captures a pump-display photo, runs OCR, and
  /// parses the three primary values (Betrag / Abgabe / Preis/Liter)
  /// into a [PumpDisplayParseResult]. Returns null if the user
  /// cancels the camera or OCR itself fails (no text recognised).
  ///
  /// Unlike earlier revisions of this method, the photo is NOT deleted
  /// on success or on parse failure — callers hold the path from
  /// [PumpDisplayScanOutcome.imagePath] and decide when to clean up
  /// (#953 added the bad-scan reporting flow for pump displays, which
  /// needs the image bytes long after parse returned).
  Future<PumpDisplayScanOutcome?> scanPumpDisplay() async {
    final capture = await _capture();
    if (capture == null) return null;
    return parsePumpDisplayImage(capture);
  }

  /// Runs OCR + parsing on an already-captured pump-display photo at
  /// [path] (#1868).
  ///
  /// The #1868 in-app camera screen owns the capture (a framing
  /// reticle `image_picker` cannot provide); it hands the captured
  /// JPEG path here. Identical to [scanPumpDisplay] minus the capture
  /// step — same #1860 contrast preprocessing, same "delete on OCR
  /// failure, keep on success for the #953 bad-scan report" policy.
  /// Returns null when OCR recognises no text.
  Future<PumpDisplayScanOutcome?> parsePumpDisplayImage(String path) async {
    // #1860 — the pump path runs an extra grayscale + contrast pass so
    // ML Kit can read 7-segment LCDs and sky-washed displays. Scoped
    // here so the prose-receipt OCR is not affected.
    final text = await _recognise(path, enhanceContrast: true);
    if (text == null) {
      await _tryDelete(path);
      return null;
    }
    return PumpDisplayScanOutcome(
      parse: _pumpParser.parse(text),
      ocrText: text,
      imagePath: path,
    );
  }

  Future<String?> _capture() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1920,
      imageQuality: 85,
    );
    return image?.path;
  }

  /// Runs ML Kit text recognition on the capture at [path].
  ///
  /// #1711 — `InputImage.fromFilePath` does not reliably honour a
  /// JPEG's EXIF orientation tag, so a phone held in portrait while
  /// photographing a landscape pump display delivered the image to the
  /// recognizer rotated 90° — which ML Kit's general recognizer cannot
  /// read, the dominant cause of the pump-display OCR failures. We OCR
  /// an EXIF-upright temp copy and delete it immediately; the original
  /// [path] is untouched for the bad-scan reporting flow.
  ///
  /// #1860 — when [enhanceContrast] is set (the pump-display path) the
  /// temp copy also gets a grayscale + histogram-normalise + contrast
  /// pass so 7-segment LCDs and washed-out displays become readable.
  Future<String?> _recognise(String path, {bool enhanceContrast = false}) async {
    String? uprightTemp;
    try {
      uprightTemp = await _writeUprightCopy(path, enhanceContrast: enhanceContrast);
      final inputImage = InputImage.fromFilePath(uprightTemp ?? path);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;
      debugPrint('OCR text (${text.length} chars):\n$text');
      return text;
    } catch (e, st) {
      debugPrint('OCR scan failed: $e\n$st');
      return null;
    } finally {
      if (uprightTemp != null) await _tryDelete(uprightTemp);
    }
  }

  /// Decodes the JPEG at [path], bakes its EXIF orientation into the
  /// pixels, and writes the upright result to a sibling temp file —
  /// returns that temp path, or null when the image cannot be decoded
  /// (the caller then OCRs the original unchanged).
  ///
  /// #1860 — with [enhanceContrast] the temp copy is additionally run
  /// through [preprocessPumpDisplayForOcr] (grayscale + normalise +
  /// contrast); otherwise it is the plain [bakeImageOrientation] path.
  Future<String?> _writeUprightCopy(
    String path, {
    bool enhanceContrast = false,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      final upright = enhanceContrast
          ? preprocessPumpDisplayForOcr(bytes)
          : bakeImageOrientation(bytes);
      if (upright == null) return null;
      final tempPath = '$path.upright.jpg';
      await File(tempPath).writeAsBytes(upright);
      return tempPath;
    } catch (e, st) {
      debugPrint('OCR orientation-bake failed: $e\n$st');
      return null;
    }
  }

  Future<void> _tryDelete(String path) async {
    try {
      await File(path).delete();
    } catch (e, st) {
      debugPrint('OCR temp-file cleanup failed at $path: $e\n$st');
    }
  }

  /// Deletes a captured photo file. Public so the failure-flow handlers
  /// (#953) can drop the temp file when the user picks "Remove photo"
  /// after a parse fail. Wraps [_tryDelete] so cleanup errors are
  /// logged but never bubble up.
  Future<void> deleteCapturedImage(String path) => _tryDelete(path);

  void dispose() {
    _recognizer.close();
  }
}

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
    debugPrint('bakeImageOrientation: decode failed: $e\n$st');
    return null;
  }
}

/// Re-encodes a pump-display capture for OCR (#1860).
///
/// Bakes EXIF orientation (exactly as [bakeImageOrientation] does) and
/// then applies a three-step enhancement pass:
///
///   1. **grayscale** — colour carries no signal on a monochrome LCD
///      and only adds noise for the recognizer.
///   2. **histogram normalise** — stretches the tonal range to the
///      full 0–255 span, the fix for sky-washed / grey-on-grey
///      displays whose digits and background sit a few levels apart.
///   3. **contrast boost** — crisps the 7-segment edges so ML Kit's
///      general recognizer stops dropping/misreading segment digits.
///
/// Scoped to the pump-display path only — [scanReceipt]'s prose-receipt
/// OCR keeps the plain [bakeImageOrientation] path, since this much
/// contrast would crush faint thermal-receipt print and regress
/// full-page recognition (#1860 acceptance).
///
/// Returns the processed JPEG bytes, or `null` when the input cannot be
/// decoded as a JPEG — the caller then OCRs the original unchanged.
Uint8List? preprocessPumpDisplayForOcr(Uint8List jpegBytes) {
  try {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) return null;
    final upright = img.bakeOrientation(decoded);
    final gray = img.grayscale(upright);
    final normalized = img.normalize(gray, min: 0, max: 255);
    final boosted = img.contrast(normalized, contrast: 140);
    return img.encodeJpg(boosted, quality: 90);
  } catch (e, st) {
    // A malformed / non-JPEG file is not fatal — OCR the original.
    debugPrint('preprocessPumpDisplayForOcr: decode failed: $e\n$st');
    return null;
  }
}
