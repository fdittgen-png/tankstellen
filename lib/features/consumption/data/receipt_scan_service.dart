import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'pump_display_parser.dart';
import 'receipt_parser.dart';

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
  /// the result. Returns null if the user cancels the camera.
  Future<ReceiptParseResult?> scanReceipt() async {
    final text = await _captureAndRecognise();
    if (text == null) return null;
    return _parser.parse(text);
  }

  /// Opens the camera, captures a pump-display photo, runs OCR, and
  /// parses the three primary values (Betrag / Abgabe / Preis/Liter)
  /// into a [PumpDisplayParseResult]. Returns null if the user
  /// cancels the camera.
  Future<PumpDisplayParseResult?> scanPumpDisplay() async {
    final text = await _captureAndRecognise();
    if (text == null) return null;
    return _pumpParser.parse(text);
  }

  /// Opens the camera, reads OCR text, and cleans up the temp file.
  /// Returns null on cancel or OCR failure.
  Future<String?> _captureAndRecognise() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (image == null) return null;

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognized = await _recognizer.processImage(inputImage);
      final text = recognized.text;

      debugPrint('OCR text (${text.length} chars):\n$text');

      return text;
    } catch (e) {
      debugPrint('OCR scan failed: $e');
      return null;
    } finally {
      // Clean up temp file
      try {
        await File(image.path).delete();
      } catch (e) {
        debugPrint('OCR temp-file cleanup failed at ${image.path}: $e');
      }
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
