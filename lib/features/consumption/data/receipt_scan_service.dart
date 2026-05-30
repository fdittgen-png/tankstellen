// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'ocr/image_orientation.dart';
import 'ocr/ocr_image_preprocessor.dart';
import 'ocr/pump_display_orchestrator.dart';
import 'ocr/pump_ocr_config.dart';
import 'ocr/pump_validation_gate.dart';
import 'ocr/recognized_text_adapter.dart';
import 'ocr/recognized_text_block.dart';
import 'pump_display_parser.dart';
import 'receipt_parser.dart';
import '../../../core/logging/error_logger.dart';

// Re-export the image-orientation helpers (#1711/#2275) so existing
// callers / tests that import them from this file keep resolving after
// they moved to `ocr/image_orientation.dart` for the #2478 split.
export 'ocr/image_orientation.dart'
    show bakeImageOrientation, preprocessPumpDisplayForOcr;

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

  /// `true` when the captured ROI was rejected for excessive glare
  /// (#2275) — the caller shows a "re-angle" prompt instead of the
  /// generic failure sheet.
  final bool glareRejected;

  const PumpDisplayScanOutcome({
    required this.parse,
    required this.ocrText,
    required this.imagePath,
    this.glareRejected = false,
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
  final PumpValidationGate _pumpGate;
  final PumpOcrConfig _ocrConfig;
  final OcrImagePreprocessor _preprocessor;

  ReceiptScanService({
    ImagePicker? picker,
    TextRecognizer? recognizer,
    ReceiptParser? parser,
    PumpDisplayParser? pumpParser,
    PumpValidationGate? pumpGate,
    PumpOcrConfig? ocrConfig,
    OcrImagePreprocessor? preprocessor,
  })  : _picker = picker ?? ImagePicker(),
        _recognizer = recognizer ?? TextRecognizer(),
        _parser = parser ?? const ReceiptParser(),
        _pumpParser = pumpParser ?? const PumpDisplayParser(),
        _pumpGate = pumpGate ?? const PumpValidationGate(),
        _ocrConfig = ocrConfig ?? PumpOcrConfig(),
        _preprocessor = preprocessor ?? const OcrImagePreprocessor();

  /// Opens the camera, captures a receipt photo, runs OCR, and parses
  /// the result. Returns null if the user cancels the camera or OCR
  /// fails. The captured photo is NOT deleted — callers hold the path
  /// from [ReceiptScanOutcome.imagePath] and delete when done (e.g.
  /// after the form is saved or after the user has shared a bad-scan
  /// report).
  ///
  /// #2273 — [country] (and, later, [brand]) thread the active region
  /// into the parser, mirroring [scanPumpDisplay]. The country's
  /// [OcrLocaleProfile] (from [PumpOcrConfig]) drives currency-aware
  /// extraction so GBP/£/p, kr, $ receipts read correctly. With no
  /// [country] the parser defaults to EUR, unchanged from before.
  Future<ReceiptScanOutcome?> scanReceipt({
    String? country,
    String? brand,
  }) async {
    final capture = await _capture();
    if (capture == null) return null;
    final text = await _recognise(capture);
    if (text == null) {
      await _tryDelete(capture);
      return null;
    }
    OcrLocaleProfile? profile;
    if (country != null) {
      await _ocrConfig.load();
      profile = _ocrConfig.profileFor(country);
    }
    return ReceiptScanOutcome(
      parse: _parser.parse(text, profile: profile),
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
  Future<PumpDisplayScanOutcome?> scanPumpDisplay({
    String? country,
    String? brand,
    OcrNormalizedRect? roi,
  }) async {
    final capture = await _capture();
    if (capture == null) return null;
    return parsePumpDisplayImage(
      capture,
      country: country,
      brand: brand,
      roi: roi,
    );
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
  Future<PumpDisplayScanOutcome?> parsePumpDisplayImage(
    String path, {
    String? country,
    String? brand,
    OcrNormalizedRect? roi,
  }) async {
    // #2275 — auto-reject an over-glared frame BEFORE OCR so the caller
    // can prompt a re-angle rather than show a generic failure.
    if (await _isOverGlared(path, roi)) {
      return PumpDisplayScanOutcome(
        parse: const PumpDisplayParseResult(),
        ocrText: '',
        imagePath: path,
        glareRejected: true,
      );
    }
    // Crop to the reticle ROI FIRST, then run the 7-segment
    // preprocessing pass (adaptive Sauvola binarization, replacing the
    // glare-amplifying #1860 global contrast). ML Kit reads the printed
    // PRIX/VOLUME/PRIX-DU-LITRE labels off the cleaned crop; we keep its
    // block geometry (#2478) — not just the flat string — so the
    // label-anchored extractor can tell which number sits under which
    // label and recover the dropped unit price.
    final recognised = await _recognisePump(path, roi: roi);
    if (recognised == null) {
      await _tryDelete(path);
      return null;
    }
    OcrLocaleProfile? profile;
    if (country != null) {
      await _ocrConfig.load();
      profile = _ocrConfig.profileFor(country);
    }
    return PumpDisplayScanOutcome(
      // #2478 — PRIMARY label-anchored read (recovers the dropped PRIX DU
      // LITRE unit price), flat-string parser fallback, then the gate.
      parse: orchestratePumpDisplayParse(
        blocks: recognised.blocks,
        text: recognised.text,
        profile: profile,
        parser: _pumpParser,
        gate: _pumpGate,
      ),
      ocrText: recognised.text,
      imagePath: path,
    );
  }

  /// Decodes [path], crops to [roi], and returns `true` when the ROI is
  /// over-glared per [GlarePolicy.standard]. Best-effort: a decode error
  /// returns `false` so a quirky image still reaches OCR (#2275).
  Future<bool> _isOverGlared(String path, OcrNormalizedRect? roi) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeJpg(bytes);
      if (decoded == null) return false;
      final upright = img.bakeOrientation(decoded);
      final region =
          roi != null ? _preprocessor.cropToRoi(upright, roi) : upright;
      return _preprocessor.glareFraction(region) >
          GlarePolicy.standard.rejectAbove;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'pump glare check failed'}));
      return false;
    }
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
  Future<String?> _recognise(
    String path, {
    bool enhanceContrast = false,
    OcrNormalizedRect? roi,
  }) async {
    final text = (await _recogniseRaw(path, enhanceContrast: enhanceContrast, roi: roi))?.text;
    if (text != null) debugPrint('OCR text (${text.length} chars):\n$text');
    return text;
  }

  /// Runs ML Kit on the pump-display crop and returns BOTH the flat text
  /// and the per-line block geometry (#2478).
  ///
  /// The pump path needs the boxes — discarding them (the old behaviour)
  /// is exactly why the unit price could not be anchored to its label.
  /// Same EXIF-upright + #2275 Sauvola preprocessing as [_recognise]; the
  /// flat text is retained for the legacy fallback parser. Returns null
  /// when OCR recognises nothing.
  Future<({String text, List<RecognizedTextBlock> blocks})?> _recognisePump(
    String path, {
    OcrNormalizedRect? roi,
  }) async {
    final recognized = await _recogniseRaw(path, enhanceContrast: true, roi: roi);
    if (recognized == null) return null;
    final blocks = mapRecognizedText(recognized);
    debugPrint('Pump OCR: ${recognized.text.length} chars, ${blocks.length} blocks');
    return (text: recognized.text, blocks: blocks);
  }

  /// Core ML Kit pass shared by [_recognise] and [_recognisePump]: writes
  /// the EXIF-upright (optionally Sauvola-preprocessed) temp copy, runs
  /// the recognizer, and returns the raw [RecognizedText] so each caller
  /// can keep just the flat text or the full block geometry. Returns null
  /// on any decode/recognize error (logged).
  Future<RecognizedText?> _recogniseRaw(
    String path, {
    bool enhanceContrast = false,
    OcrNormalizedRect? roi,
  }) async {
    String? uprightTemp;
    try {
      uprightTemp =
          await _writeUprightCopy(path, enhanceContrast: enhanceContrast, roi: roi);
      final inputImage = InputImage.fromFilePath(uprightTemp ?? path);
      return await _recognizer.processImage(inputImage);
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
  ///
  /// #1860 — with [enhanceContrast] the temp copy is additionally run
  /// through [preprocessPumpDisplayForOcr] (grayscale + normalise +
  /// contrast); otherwise it is the plain [bakeImageOrientation] path.
  Future<String?> _writeUprightCopy(
    String path, {
    bool enhanceContrast = false,
    OcrNormalizedRect? roi,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      final upright = enhanceContrast
          ? preprocessPumpDisplayForOcr(bytes, roi: roi, preprocessor: _preprocessor)
          : bakeImageOrientation(bytes);
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

  /// Deletes a captured photo file. Public so the failure-flow handlers
  /// (#953) can drop the temp file when the user picks "Remove photo"
  /// after a parse fail. Wraps [_tryDelete] so cleanup errors are
  /// logged but never bubble up.
  Future<void> deleteCapturedImage(String path) => _tryDelete(path);

  void dispose() {
    _recognizer.close();
  }
}
