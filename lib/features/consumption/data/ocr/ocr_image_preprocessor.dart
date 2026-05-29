// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'ocr_geometry.dart';

export 'ocr_geometry.dart' show OcrNormalizedRect, GlarePolicy;

/// On-device image preprocessing for pump-display OCR (#2275).
///
/// The previous pump path ran ML Kit's general Latin recognizer on the
/// **full** camera frame after a *global* `normalize → contrast(140)`
/// pass — which AMPLIFIES glare and cannot read 7-segment LCD glyphs.
/// This module replaces that with a 7-segment-friendly pipeline built
/// entirely on top of `image: ^4.5.0` (no native plugin):
///
///  1. [cropToRoi]            — copyCrop to the reticle rect FIRST so all
///                              downstream work runs on the readout only.
///  2. [toGrayscale]          — colour carries no signal on a mono LCD.
///  3. [sauvolaBinarize]      — *local* adaptive threshold (Sauvola, via an
///                              integral image) so a bright reflection on
///                              one corner no longer blows out the digits
///                              the way a single global threshold did.
///  4. [morphologicalClose]   — bridges the gaps between the strokes of a
///                              7-segment glyph that adaptive thresholding
///                              tends to break apart.
///  5. [glareFraction]        — fraction of near-white pixels, used to
///                              auto-reject an over-glared frame and prompt
///                              the user to re-angle (#2275 concern 2).
///
/// ## Why pure Dart and not OpenCV-FFI
///
/// `image` ships grayscale / crop / rotate / convolution / gaussian-blur
/// but **not** adaptive thresholding or morphology — those are
/// implemented here directly over the pixel buffer (integral-image
/// Sauvola is O(n); morphology is a separable min/max window). Bench:
/// a 900×600 ROI binarizes + closes in a few ms on a mid phone, well
/// inside the capture-to-result budget. An OpenCV-FFI plugin would only
/// be worth its build/binary-size cost if we later need sub-pixel
/// deskew or contour analysis the `image` package cannot express; the
/// Sauvola + morphology here is sufficient for the FR/Tokheim fixtures
/// (see the recognizer's fixture harness for the per-frame results).
class OcrImagePreprocessor {
  const OcrImagePreprocessor();

  /// Crops [source] to the normalized [roi] (each component in `0..1`,
  /// relative to the upright image). Clamps to the image bounds so a
  /// reticle that overhangs the frame edge never throws. Returns the
  /// crop, or [source] unchanged when [roi] degenerates to zero area.
  img.Image cropToRoi(img.Image source, OcrNormalizedRect roi) {
    final x = (roi.left * source.width).round().clamp(0, source.width - 1);
    final y = (roi.top * source.height).round().clamp(0, source.height - 1);
    final w = (roi.width * source.width)
        .round()
        .clamp(1, source.width - x);
    final h = (roi.height * source.height)
        .round()
        .clamp(1, source.height - y);
    if (w <= 1 || h <= 1) return source;
    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  /// Rotates [source] by [quarterTurns] × 90° clockwise. Used by the
  /// recognizer's orientation sweep — a pump photographed with a
  /// landscape phone against a vertical pump reads sideways, and EXIF
  /// only corrects the phone-hold, never the reading axis.
  img.Image rotateQuarterTurns(img.Image source, int quarterTurns) {
    final turns = quarterTurns % 4;
    if (turns == 0) return source;
    return img.copyRotate(source, angle: turns * 90);
  }

  /// Grayscale conversion. Kept as a named step so the pipeline reads
  /// top-to-bottom and tests can assert each stage independently.
  img.Image toGrayscale(img.Image source) => img.grayscale(source);

  /// Light gaussian blur to suppress sensor noise and JPEG ringing
  /// before thresholding, so single speckles don't survive as stray
  /// "segments". Radius 1 is enough at ROI scale.
  img.Image denoise(img.Image source, {int radius = 1}) =>
      img.gaussianBlur(source, radius: radius);

  /// Sauvola adaptive (local) binarization.
  ///
  /// For each pixel the threshold is `m·(1 + k·(s/R − 1))` where `m` and
  /// `s` are the mean and standard deviation of luminance in a
  /// `window×window` neighbourhood and `R` is the dynamic range (128).
  /// Computed in O(n) with two integral images (sum and sum-of-squares).
  ///
  /// Returns a 1-channel image where ink (the dark digits) is **black**
  /// (0) and background is **white** (255) — the convention the segment
  /// decoder expects.
  ///
  /// [window] should be a few times the stroke width; [k] in `0.2..0.5`
  /// trades sensitivity for noise (higher = stricter, fewer false ink
  /// pixels). Defaults are tuned for the FR/Tokheim LCD at ROI scale.
  img.Image sauvolaBinarize(
    img.Image source, {
    int window = 15,
    double k = 0.2,
  }) {
    final gray = source.numChannels == 1 ? source : img.grayscale(source);
    final w = gray.width;
    final h = gray.height;
    final lum = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        lum[y * w + x] = gray.getPixel(x, y).luminance.round();
      }
    }

    // Integral images (use Float64 for sum-of-squares to avoid overflow).
    final cols = w + 1;
    final integral = Float64List((w + 1) * (h + 1));
    final integralSq = Float64List((w + 1) * (h + 1));
    for (var y = 1; y <= h; y++) {
      var rowSum = 0.0;
      var rowSumSq = 0.0;
      for (var x = 1; x <= w; x++) {
        final v = lum[(y - 1) * w + (x - 1)].toDouble();
        rowSum += v;
        rowSumSq += v * v;
        integral[y * cols + x] = integral[(y - 1) * cols + x] + rowSum;
        integralSq[y * cols + x] =
            integralSq[(y - 1) * cols + x] + rowSumSq;
      }
    }

    final half = window ~/ 2;
    const dynamicRange = 128.0;
    final out = img.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - half);
      final y1 = math.min(h - 1, y + half);
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - half);
        final x1 = math.min(w - 1, x + half);
        final area = (x1 - x0 + 1) * (y1 - y0 + 1);
        final sum = _boxSum(integral, cols, x0, y0, x1, y1);
        final sumSq = _boxSum(integralSq, cols, x0, y0, x1, y1);
        final mean = sum / area;
        final variance = (sumSq / area) - (mean * mean);
        final std = variance > 0 ? math.sqrt(variance) : 0.0;
        final threshold = mean * (1 + k * ((std / dynamicRange) - 1));
        final isInk = lum[y * w + x] < threshold;
        final value = isInk ? 0 : 255;
        out.setPixelRgb(x, y, value, value, value);
      }
    }
    return out;
  }

  /// Morphological close (dilate then erode) on a binarized image where
  /// ink is black. Bridges the small gaps adaptive thresholding leaves
  /// between the strokes of a single 7-segment glyph so the decoder
  /// reads one connected digit instead of a scatter of segments.
  ///
  /// Implemented as a separable square structuring element of side
  /// `2·radius+1` over the ink mask (ink = pixel value < 128).
  img.Image morphologicalClose(img.Image source, {int radius = 1}) {
    final w = source.width;
    final h = source.height;
    var ink = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        ink[y * w + x] =
            source.getPixel(x, y).luminance < 128 ? 1 : 0;
      }
    }
    ink = _dilate(ink, w, h, radius);
    ink = _erode(ink, w, h, radius);
    final out = img.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final value = ink[y * w + x] == 1 ? 0 : 255;
        out.setPixelRgb(x, y, value, value, value);
      }
    }
    return out;
  }

  /// Removes ink blobs that touch the image border on a binarized
  /// mask (ink = dark). The LCD bezel and the dark pump body around a
  /// tightly-framed readout flood in as one large border-connected
  /// region; clearing it leaves only the free-floating digit strokes,
  /// which makes the row/column projection in the segment decoder
  /// robust to how tightly the ROI was framed.
  ///
  /// A flood fill from every border ink pixel marks the connected
  /// component; marked pixels are set to background (white).
  img.Image clearBorderInk(img.Image source) {
    final w = source.width;
    final h = source.height;
    final ink = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        ink[y * w + x] = source.getPixel(x, y).luminance < 128 ? 1 : 0;
      }
    }
    final visited = Uint8List(w * h);
    final stack = <int>[];
    void seed(int x, int y) {
      final i = y * w + x;
      if (ink[i] == 1 && visited[i] == 0) {
        visited[i] = 1;
        stack.add(i);
      }
    }

    for (var x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w;
      final y = i ~/ w;
      if (x > 0) seed(x - 1, y);
      if (x < w - 1) seed(x + 1, y);
      if (y > 0) seed(x, y - 1);
      if (y < h - 1) seed(x, y + 1);
    }

    final out = img.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final keepInk = ink[i] == 1 && visited[i] == 0;
        final value = keepInk ? 0 : 255;
        out.setPixelRgb(x, y, value, value, value);
      }
    }
    return out;
  }

  /// Fraction of pixels in `0..1` that are near-saturated white — a
  /// cheap proxy for specular glare. The recognizer rejects a frame
  /// above [GlarePolicy.rejectAbove] and asks the user to re-angle.
  double glareFraction(img.Image source, {int threshold = 250}) {
    final gray = source.numChannels == 1 ? source : img.grayscale(source);
    var bright = 0;
    final total = gray.width * gray.height;
    if (total == 0) return 0;
    for (final p in gray) {
      if (p.luminance >= threshold) bright++;
    }
    return bright / total;
  }

  // -- internals -------------------------------------------------------

  double _boxSum(
    Float64List integral,
    int cols,
    int x0,
    int y0,
    int x1,
    int y1,
  ) {
    final a = integral[y0 * cols + x0];
    final b = integral[y0 * cols + (x1 + 1)];
    final c = integral[(y1 + 1) * cols + x0];
    final d = integral[(y1 + 1) * cols + (x1 + 1)];
    return d - b - c + a;
  }

  Uint8List _dilate(Uint8List src, int w, int h, int r) {
    // Horizontal pass then vertical pass (separable max).
    final tmp = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 0;
        for (var dx = -r; dx <= r; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) continue;
          if (src[y * w + nx] == 1) {
            v = 1;
            break;
          }
        }
        tmp[y * w + x] = v;
      }
    }
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 0;
        for (var dy = -r; dy <= r; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          if (tmp[ny * w + x] == 1) {
            v = 1;
            break;
          }
        }
        out[y * w + x] = v;
      }
    }
    return out;
  }

  Uint8List _erode(Uint8List src, int w, int h, int r) {
    final tmp = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 1;
        for (var dx = -r; dx <= r; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) {
            continue;
          }
          if (src[y * w + nx] == 0) {
            v = 0;
            break;
          }
        }
        tmp[y * w + x] = v;
      }
    }
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 1;
        for (var dy = -r; dy <= r; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) {
            continue;
          }
          if (tmp[ny * w + x] == 0) {
            v = 0;
            break;
          }
        }
        out[y * w + x] = v;
      }
    }
    return out;
  }
}
