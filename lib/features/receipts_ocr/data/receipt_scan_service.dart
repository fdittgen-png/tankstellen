// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr/image_orientation.dart';
import 'ocr/ocr_trace_recorder.dart';
import 'ocr/pump_ocr_config.dart';
import 'ocr/impl/ocr_engine_factory.dart';
import 'ocr/mlkit_ocr_text_engine.dart';
import 'ocr/ocr_text_engine.dart';
import 'receipt_parser.dart';
import 'receipt_scan_outcomes.dart';
import '../../../core/logging/error_logger.dart';

// Re-export the image-orientation helper (#1711) so existing callers /
// tests that import it from this file keep resolving after it moved to
// `ocr/image_orientation.dart` for the #2478 split.
export 'ocr/image_orientation.dart' show bakeImageOrientation;

// Re-export the scan-outcome value type so existing importers that read
// `ReceiptScanOutcome` from this file keep resolving after it moved to
// `receipt_scan_outcomes.dart` (#2518).
export 'receipt_scan_outcomes.dart' show ReceiptScanOutcome;

/// Service that captures a photo and runs on-device OCR.
///
/// Uses [ImagePicker] for camera access and [TextRecognizer] from
/// Google ML Kit for on-device text recognition (no network calls).
/// [scanReceipt] parses a paper receipt with prose labels
/// (TOTAL, MONTANT, Prix/L, …). (#3765 removed the second capture
/// mode — the 7-segment pump-display scanner — which never read
/// reliably in the field.)
class ReceiptScanService {
  final ImagePicker _picker;

  /// #3052 — the OCR backend. iOS → Apple Vision, Android/host → ML Kit
  /// (selected by [createDefaultOcrTextEngine]). Tests inject `recognizer:`
  /// (wrapped in [MlKitOcrTextEngine]) so the ML Kit path stays covered.
  final OcrTextEngine _engine;

  final ReceiptParser _parser;
  final PumpOcrConfig _ocrConfig;

  ReceiptScanService({
    ImagePicker? picker,
    TextRecognizer? recognizer,
    OcrTextEngine? engine,
    ReceiptParser? parser,
    PumpOcrConfig? ocrConfig,
  })  : _picker = picker ?? ImagePicker(),
        // An explicit [engine] wins; a legacy `recognizer:` (tests) keeps the
        // ML Kit path; otherwise the platform default (iOS Vision / else ML Kit).
        _engine = engine ??
            (recognizer != null
                ? MlKitOcrTextEngine(recognizer: recognizer)
                : createDefaultOcrTextEngine()),
        _parser = parser ?? const ReceiptParser(),
        _ocrConfig = ocrConfig ?? PumpOcrConfig();

  /// Opens the camera, captures a receipt photo, runs OCR, and parses
  /// the result. Returns null if the user cancels the camera or OCR
  /// fails. The captured photo is NOT deleted — callers hold the path
  /// from [ReceiptScanOutcome.imagePath] and delete when done (e.g.
  /// after the form is saved or after the user has shared a bad-scan
  /// report).
  ///
  /// #2273 — [country] (and, later, [brand]) thread the active region
  /// into the parser. The country's [OcrLocaleProfile] (from
  /// [PumpOcrConfig]) drives currency-aware extraction so GBP/£/p, kr,
  /// $ receipts read correctly. With no [country] the parser defaults
  /// to EUR, unchanged from before.
  Future<ReceiptScanOutcome?> scanReceipt({
    String? country,
    String? brand,
    OcrTraceRecorder? trace,
  }) async {
    trace?.input(country: country, brand: brand);
    final capture = await _capture();
    if (capture == null) return null;
    return parseReceiptImage(
      capture,
      country: country,
      brand: brand,
      trace: trace,
    );
  }

  /// Runs OCR + parsing on an already-captured receipt photo at [path].
  ///
  /// The capture-owning analogue of [scanReceipt]: the in-app OCR
  /// tester (#2518) and any future caller that already holds the
  /// image hand the path here instead of reopening the camera. The photo
  /// is NOT deleted on success (same #713 bad-scan-report policy); it is
  /// deleted only when OCR recognises no text. Returns null when OCR
  /// recognises nothing.
  Future<ReceiptScanOutcome?> parseReceiptImage(
    String path, {
    String? country,
    String? brand,
    OcrTraceRecorder? trace,
  }) async {
    trace?.input(country: country, brand: brand);
    final recognised = await _recognise(path, trace: trace);
    if (recognised == null) {
      await _tryDelete(path);
      return null;
    }
    OcrLocaleProfile? profile;
    if (country != null) {
      await _ocrConfig.load();
      profile = _ocrConfig.profileFor(country);
    }
    // #2848 — pass ML Kit's block geometry to the parser so a fuel-station
    // receipt (Volume/Prix/TOT TTC row-aligned with their left-column labels)
    // routes to the label-anchored extractor; non-fuel receipts fall back.
    return ReceiptScanOutcome(
      parse: _parser.parseBlocks(recognised.blocks, recognised.text,
          profile: profile, trace: trace),
      ocrText: recognised.text,
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
  /// #1711 — `InputImage.fromFilePath` does not reliably honour a JPEG's
  /// EXIF orientation tag, so a portrait-held shot arrived rotated 90°
  /// (unreadable by ML Kit). We OCR an EXIF-upright temp copy and delete
  /// it immediately; [path] is untouched for the bad-scan reporting flow.
  Future<OcrTextResult?> _recognise(
    String path, {
    OcrTraceRecorder? trace,
  }) async {
    final recognised = await _recogniseRaw(path);
    if (recognised == null) return null;
    // #3610 — never print the recognised text itself: a receipt can carry
    // PII (card fragments, loyalty ids). Character count only.
    debugPrint('OCR text: ${recognised.text.length} chars');
    // #2848 — the engine already carries the per-line block geometry so the
    // receipt path can route a fuel-station receipt to the label-anchored
    // extractor (ML Kit via mapRecognizedText, Vision via the channel).
    trace?.blocks(recognised.text, recognised.blocks);
    return recognised;
  }

  /// Core ML Kit pass: writes the EXIF-upright temp copy, runs the
  /// recognizer, and returns the raw [RecognizedText]. Returns null
  /// on any decode/recognize error (logged).
  Future<OcrTextResult?> _recogniseRaw(String path) async {
    String? uprightTemp;
    try {
      uprightTemp = await _writeUprightCopy(path);
      // #3052 — recognition is delegated to the platform engine (iOS Vision /
      // Android ML Kit); the EXIF-upright preprocessing above is
      // engine-agnostic.
      return await _engine.recognize(uprightTemp ?? path);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'OCR scan failed'}));
      return null;
    } finally {
      if (uprightTemp != null) await _tryDelete(uprightTemp);
    }
  }

  /// Decodes the JPEG at [path], bakes its EXIF orientation into the
  /// pixels, and writes the upright result to a sibling temp file —
  /// returns that temp path, or null when the image cannot be decoded
  /// (the caller then OCRs the original unchanged).
  Future<String?> _writeUprightCopy(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final upright = bakeImageOrientation(bytes);
      if (upright == null) return null;
      final tempPath = '$path.upright.jpg';
      await File(tempPath).writeAsBytes(upright);
      return tempPath;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'OCR orientation-bake failed'}));
      return null;
    }
  }

  Future<void> _tryDelete(String path) async {
    try {
      await File(path).delete();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {'where': 'OCR temp-file cleanup failed at $path'}));
    }
  }

  /// Deletes a captured photo file. Public so failure-flow handlers
  /// (#953) can drop the temp file when the user picks "Remove photo"
  /// after a parse fail. Wraps [_tryDelete] so cleanup errors are
  /// logged but never bubble up.
  Future<void> deleteCapturedImage(String path) => _tryDelete(path);

  void dispose() {
    _engine.dispose();
  }
}
