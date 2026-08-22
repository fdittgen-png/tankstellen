// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:image/image.dart' as img;

import 'ocr_image_preprocessor.dart';
import 'pump_ocr_config.dart';
import 'seven_segment_recognizer.dart';

/// Outcome of recognizing one pump display from a decoded image (#2275).
///
/// The three optional values are only set when the segment decoder read
/// them with enough confidence; [glareRejected] is set when the frame
/// was too washed-out to attempt a read (the camera UI then prompts a
/// re-angle). [orientationQuarterTurns] records which of the
/// `0/90/180/270` sweep candidates scored best, so the camera can
/// remember the user's typical hold.
class PumpOcrResult {
  final double? total;
  final double? volume;
  final double? pricePerLitre;
  final double confidence;
  final bool glareRejected;
  final int orientationQuarterTurns;

  const PumpOcrResult({
    this.total,
    this.volume,
    this.pricePerLitre,
    this.confidence = 0,
    this.glareRejected = false,
    this.orientationQuarterTurns = 0,
  });

  static const glare = PumpOcrResult(glareRejected: true);

  /// How many of the three fields were recovered.
  int get fieldCount =>
      [total, volume, pricePerLitre].where((v) => v != null).length;
}

/// On-device pump-display recognizer (#2275).
///
/// This is the orchestration seam the Epic asked for: it owns the
/// preprocess → orientation-sweep → 7-segment-decode pipeline and sits
/// **behind the validation gate** so a consent-gated cloud/VLM fallback
/// (a later batch) can be slotted in as an alternate
/// [recognize] implementation without touching the parser, the camera
/// screen, or the fill-up form.
///
/// ## What runs where
///
/// The deterministic [SevenSegmentRecognizer] + [OcrImagePreprocessor]
/// run in pure Dart, so this whole class is exercisable end-to-end in
/// `flutter test` against the real fixture photos (no platform channel).
/// At runtime the field ROIs come from the [PumpOcrConfig] brand
/// template; ML Kit is used **only** to locate the printed
/// PRIX/VOLUME/PRIX-DU-LITRE label blocks so the template ROIs can be
/// anchored to where the labels actually landed in the frame — never to
/// read the 7-segment value digits, which it structurally cannot do.
class PumpOcrRecognizer {
  final OcrImagePreprocessor _preprocessor;
  final SevenSegmentRecognizer _decoder;
  final GlarePolicy _glarePolicy;

  /// Width (px) each field ROI is resized to before binarization — big
  /// enough that the segment-sampling windows have pixels to count,
  /// small enough to stay fast.
  final int workingWidth;

  const PumpOcrRecognizer({
    OcrImagePreprocessor preprocessor = const OcrImagePreprocessor(),
    SevenSegmentRecognizer decoder = const SevenSegmentRecognizer(),
    GlarePolicy glarePolicy = GlarePolicy.standard,
    this.workingWidth = 600,
  })  : _preprocessor = preprocessor,
        _decoder = decoder,
        _glarePolicy = glarePolicy;

  /// Recognizes the three values from an already-decoded, **upright**
  /// (orientation-corrected), reticle-cropped [frame] using the field
  /// ROIs in [fields].
  ///
  /// Returns [PumpOcrResult.glare] when the frame is over-glared. Does
  /// NOT apply the domain-sanity validation gate — that lives in the
  /// parser, which also fuses this read with any labelled ML Kit text.
  PumpOcrResult recognize(
    img.Image frame,
    OcrPumpFieldSpec fields, {
    int orientationQuarterTurns = 0,
  }) {
    if (_preprocessor.glareFraction(frame) > _glarePolicy.rejectAbove) {
      return PumpOcrResult.glare;
    }
    final total = _readField(frame, fields.total);
    final volume = _readField(frame, fields.volume);
    final price = _readField(frame, fields.pricePerLitre);

    final readings = [total, volume, price].where((r) => !r.isEmpty);
    final confidence = readings.isEmpty
        ? 0.0
        : readings.map((r) => r.confidence).reduce((a, b) => a + b) /
            readings.length;

    return PumpOcrResult(
      total: total.value,
      volume: volume.value,
      pricePerLitre: price.value,
      confidence: confidence,
      orientationQuarterTurns: orientationQuarterTurns,
    );
  }

  /// Runs the full orientation sweep: tries `0/90/180/270`° and keeps
  /// the rotation whose recognition recovered the most fields (ties
  /// broken by mean confidence). [decodedUpright] is the EXIF-baked
  /// image; the sweep then corrects the *content* rotation a sideways
  /// hold introduces, which EXIF never fixes.
  PumpOcrResult recognizeWithSweep(
    img.Image decodedUpright,
    OcrPumpFieldSpec fields,
  ) {
    PumpOcrResult? best;
    for (var turns = 0; turns < 4; turns++) {
      final rotated =
          _preprocessor.rotateQuarterTurns(decodedUpright, turns);
      final result =
          recognize(rotated, fields, orientationQuarterTurns: turns);
      if (result.glareRejected) continue;
      if (best == null ||
          result.fieldCount > best.fieldCount ||
          (result.fieldCount == best.fieldCount &&
              result.confidence > best.confidence)) {
        best = result;
      }
    }
    return best ?? PumpOcrResult.glare;
  }

  SevenSegmentReading _readField(img.Image frame, OcrNormalizedRect roi) {
    final crop = _preprocessor.cropToRoi(frame, roi);
    final scaled = img.copyResize(crop, width: workingWidth);
    final gray = _preprocessor.toGrayscale(scaled);
    final denoised = _preprocessor.denoise(gray);
    final binary = _preprocessor.sauvolaBinarize(denoised);
    final cleaned = _preprocessor.morphologicalClose(binary);
    return _decoder.decode(cleaned);
  }
}
