import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'receipt_parser.dart';

/// Service that captures a receipt photo and runs on-device OCR.
///
/// Uses [ImagePicker] for camera access and [TextRecognizer] from
/// Google ML Kit for on-device text recognition (no network calls).
class ReceiptScanService {
  final ImagePicker _picker;
  final TextRecognizer _recognizer;
  final ReceiptParser _parser;

  ReceiptScanService({
    ImagePicker? picker,
    TextRecognizer? recognizer,
    ReceiptParser? parser,
  })  : _picker = picker ?? ImagePicker(),
        _recognizer = recognizer ?? TextRecognizer(),
        _parser = parser ?? const ReceiptParser();

  /// Opens the camera, captures a receipt photo, runs OCR, and parses
  /// the result. Returns null if the user cancels the camera.
  Future<ReceiptParseResult?> scanReceipt() async {
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

      debugPrint('Receipt OCR text (${text.length} chars):\n$text');

      return _parser.parse(text);
    } catch (e) {
      debugPrint('Receipt scan failed: $e');
      return null;
    } finally {
      // Clean up temp file
      try {
        await File(image.path).delete();
      } catch (e) {
        debugPrint('Receipt temp-file cleanup failed at ${image.path}: $e');
      }
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
