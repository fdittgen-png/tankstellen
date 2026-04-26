import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
    final text = await _recognise(capture);
    if (text == null) {
      await _tryDelete(capture);
      return null;
    }
    return PumpDisplayScanOutcome(
      parse: _pumpParser.parse(text),
      ocrText: text,
      imagePath: capture,
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

  Future<String?> _recognise(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;
      debugPrint('OCR text (${text.length} chars):\n$text');
      return text;
    } catch (e, st) {
      debugPrint('OCR scan failed: $e\n$st');
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
