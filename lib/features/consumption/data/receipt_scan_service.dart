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
import 'ocr/ocr_trace_recorder.dart';
import 'ocr/pump_display_orchestrator.dart';
import 'ocr/pump_ocr_config.dart';
import 'ocr/pump_validation_gate.dart';
import 'ocr/recognized_text_adapter.dart';
import 'ocr/recognized_text_block.dart';
import 'pump_display_parser.dart';
import 'receipt_parser.dart';
import 'receipt_scan_outcomes.dart';
import '../../../core/logging/error_logger.dart';

// Re-export the image-orientation helpers (#1711/#2275) so existing
// callers / tests that import them from this file keep resolving after
// they moved to `ocr/image_orientation.dart` for the #2478 split.
export 'ocr/image_orientation.dart'
    show bakeImageOrientation, preprocessPumpDisplayForOcr;

// Re-export the scan-outcome value types so existing importers that read
// `ReceiptScanOutcome` / `PumpDisplayScanOutcome` from this file keep
// resolving after they moved to `receipt_scan_outcomes.dart` (#2518).
export 'receipt_scan_outcomes.dart'
    show ReceiptScanOutcome, PumpDisplayScanOutcome;

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
  /// The capture-owning analogue of [parsePumpDisplayImage]: the in-app
  /// OCR tester (#2518) and any future caller that already holds the
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
    final text = await _recognise(path, trace: trace);
    if (text == null) {
      await _tryDelete(path);
      return null;
    }
    OcrLocaleProfile? profile;
    if (country != null) {
      await _ocrConfig.load();
      profile = _ocrConfig.profileFor(country);
    }
    return ReceiptScanOutcome(
      parse: _parser.parse(text, profile: profile, trace: trace),
      ocrText: text,
      imagePath: path,
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
    OcrTraceRecorder? trace,
  }) async {
    final capture = await _capture();
    if (capture == null) return null;
    return parsePumpDisplayImage(
      capture,
      country: country,
      brand: brand,
      roi: roi,
      trace: trace,
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
    OcrTraceRecorder? trace,
  }) async {
    // Resolve the profile up front (independent of the image) so the
    // trace's input section is complete even on a glare-rejected frame.
    OcrLocaleProfile? profile;
    if (country != null) {
      await _ocrConfig.load();
      profile = _ocrConfig.profileFor(country);
    }
    trace?.input(
      country: country,
      brand: brand,
      roi: roi == null ? null : [roi.left, roi.top, roi.width, roi.height],
      profile: profile?.toTraceJson(),
    );
    // #2275 — auto-reject an over-glared frame BEFORE OCR so the caller
    // can prompt a re-angle rather than show a generic failure.
    if (await _isOverGlared(path, roi, trace: trace)) {
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
    var recognised = await _recognisePump(path, roi: roi);
    if (recognised == null) {
      await _tryDelete(path);
      return null;
    }
    // #2478 PRIMARY label-anchored read (recovers the dropped PRIX DU LITRE),
    // flat-string fallback, then the gate.
    PumpDisplayParseResult parseFor(
            ({String text, List<RecognizedTextBlock> blocks}) r) =>
        orchestratePumpDisplayParse(
            blocks: r.blocks,
            text: r.text,
            profile: profile,
            parser: _pumpParser,
            gate: _pumpGate,
            trace: trace);
    var parse = parseFor(recognised);

    // #2798 — the #2275 binarization can dissolve faint 7-seg value digits
    // (ML Kit returns only labels → nothing derived). When the binarized pass
    // recovers nothing, retry once with grayscale and keep it only if it reads
    // more — non-regressive: a usable binarized read is never replaced.
    if (!parse.hasUsableData) {
      final gray = await _recognisePump(path, roi: roi, binarize: false);
      final grayParse = gray == null ? null : parseFor(gray);
      if (gray != null && grayParse!.hasUsableData) {
        recognised = gray;
        parse = grayParse;
      }
    }
    trace?.blocks(recognised.text, recognised.blocks);
    return PumpDisplayScanOutcome(
      parse: parse,
      ocrText: recognised.text,
      imagePath: path,
    );
  }

  /// Decodes [path], crops to [roi], and returns `true` when the ROI is
  /// over-glared per [GlarePolicy.standard]. Best-effort: a decode error
  /// returns `false` so a quirky image still reaches OCR (#2275).
  Future<bool> _isOverGlared(
    String path,
    OcrNormalizedRect? roi, {
    OcrTraceRecorder? trace,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeJpg(bytes);
      if (decoded == null) return false;
      final upright = img.bakeOrientation(decoded);
      final region =
          roi != null ? _preprocessor.cropToRoi(upright, roi) : upright;
      final fraction = _preprocessor.glareFraction(region);
      final threshold = GlarePolicy.standard.rejectAbove;
      final rejected = fraction > threshold;
      trace?.glare(
          fraction: fraction, threshold: threshold, rejected: rejected);
      return rejected;
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
    OcrTraceRecorder? trace,
  }) async {
    final recognized =
        await _recogniseRaw(path, enhanceContrast: enhanceContrast, roi: roi);
    final text = recognized?.text;
    if (text != null) debugPrint('OCR text (${text.length} chars):\n$text');
    // #2517 — TRACE ONLY: recover the ML Kit geometry the receipt path
    // discards (production still reads only the flat [text]).
    if (trace != null && recognized != null) {
      trace.blocks(recognized.text, mapRecognizedText(recognized));
    }
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
    bool binarize = true,
  }) async {
    final recognized = await _recogniseRaw(path,
        enhanceContrast: true, roi: roi, binarize: binarize);
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
    bool binarize = true,
  }) async {
    String? uprightTemp;
    try {
      uprightTemp = await _writeUprightCopy(path,
          enhanceContrast: enhanceContrast, roi: roi, binarize: binarize);
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
  /// #1860/#2275/#2798 — with [enhanceContrast] the temp copy is run through
  /// [preprocessPumpDisplayForOcr]: by default a #2275 Sauvola binarization;
  /// with [binarize] false a contrast-stretched grayscale (the pump path's
  /// #2798 retry when binarization erased the faint 7-seg value digits).
  /// Without [enhanceContrast] it is the plain [bakeImageOrientation] path.
  Future<String?> _writeUprightCopy(
    String path, {
    bool enhanceContrast = false,
    OcrNormalizedRect? roi,
    bool binarize = true,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      final upright = enhanceContrast
          ? preprocessPumpDisplayForOcr(bytes,
              roi: roi, preprocessor: _preprocessor, binarize: binarize)
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
