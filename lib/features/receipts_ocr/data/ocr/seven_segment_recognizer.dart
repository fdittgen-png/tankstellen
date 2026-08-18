// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'seven_segment_decode_table.dart';

export 'seven_segment_decode_table.dart' show SevenSegmentReading;

/// Deterministic ssocr-style 7-segment decoder (#2275).
///
/// Stock ML Kit / Tesseract Latin recognizers are trained on *printed*
/// type and structurally cannot read the disconnected strokes of a
/// 7-segment LCD — the root cause of the pump-OCR failures. This decoder
/// instead works directly on the binarized ink mask the
/// `OcrImagePreprocessor` produces, the same way the `ssocr` C utility
/// does:
///
///  1. **Row segmentation** — a horizontal ink-projection finds the
///     band(s) of pixels that actually contain digits, ignoring the
///     dark LCD bezel above/below.
///  2. **Column segmentation** — within a row, a vertical projection
///     splits the band into individual digit cells (and recognises the
///     narrow gaps that are the decimal point / colon separators).
///  3. **Segment sampling** — each digit cell is divided into the seven
///     canonical segment regions (a–g). A segment is "on" when its
///     region is mostly ink; the on/off pattern maps to a digit via
///     [_segmentTable]. A `1` is detected by its anomalously narrow
///     aspect ratio before the table is consulted.
///
/// The decoder returns a [SevenSegmentReading] with the recovered digit
/// string, the inferred decimal position, and a `0..1` confidence from
/// how cleanly each glyph matched a known pattern. It never throws — an
/// unreadable cell lowers confidence and yields a `?` placeholder that
/// the caller's validation gate rejects.
class SevenSegmentRecognizer {
  /// Minimum fraction of a segment region that must be ink for the
  /// segment to count as "on".
  final double segmentOnThreshold;

  /// A digit cell narrower than this fraction of the median cell width
  /// is treated as a `1` (only segments b+c lit).
  final double oneWidthRatio;

  const SevenSegmentRecognizer({
    this.segmentOnThreshold = 0.32,
    this.oneWidthRatio = 0.42,
  });

  /// Decodes the single horizontal number rendered in [binary] (ink =
  /// dark, background = light). Returns an empty, zero-confidence
  /// reading when no digit band is found.
  SevenSegmentReading decode(img.Image binary) {
    final w = binary.width;
    final h = binary.height;
    if (w < 4 || h < 4) return SevenSegmentReading.empty;

    final ink = _inkMask(binary);
    final band = _largestRowBand(ink, w, h);
    if (band == null) return SevenSegmentReading.empty;

    final cells = _segmentColumns(ink, w, band.start, band.end);
    if (cells.isEmpty) return SevenSegmentReading.empty;

    // A full digit (0,2-9) is the widest glyph on the row; a "1" and a
    // decimal point are always narrower. Anchoring `digitWidth` on the
    // widest cell therefore keeps the narrow-cell test below correct
    // even for numbers that are *mostly* 1s (e.g. "11.12"), where a
    // median would collapse onto the narrow width and misread the 1s.
    final widths = cells.where((c) => !c.isGap).map((c) => c.width).toList();
    if (widths.isEmpty) return SevenSegmentReading.empty;
    final digitWidth = widths.reduce((a, b) => a > b ? a : b);

    final buffer = StringBuffer();
    var matched = 0;
    var digits = 0;
    for (final cell in cells) {
      if (cell.isGap) {
        // A gap whose ink sits low in the band is a decimal point.
        if (cell.hasLowInk) buffer.write('.');
        continue;
      }
      // A narrow run whose ink sits in the bottom of the band — and
      // which is too short to be a "1" — is a decimal point attached
      // between digits, not a glyph.
      if (_isDecimalCell(ink, w, cell, band, digitWidth: digitWidth)) {
        buffer.write('.');
        continue;
      }
      final glyph = _decodeCell(
        ink,
        w,
        cell,
        band,
        digitWidth: digitWidth,
      );
      digits++;
      if (glyph.matched) matched++;
      buffer.write(glyph.value);
    }
    if (digits == 0) return SevenSegmentReading.empty;

    final text = buffer.toString();
    final confidence = matched / digits;
    return SevenSegmentReading(
      text: text,
      confidence: confidence,
      digitCount: digits,
    );
  }

  // -- row / column segmentation --------------------------------------

  Uint8List _inkMask(img.Image binary) {
    final w = binary.width;
    final h = binary.height;
    final mask = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        mask[y * w + x] = binary.getPixel(x, y).luminance < 128 ? 1 : 0;
      }
    }
    return mask;
  }

  /// Finds the tallest contiguous run of rows whose ink density exceeds
  /// a fraction of the peak row density — the digit band, excluding the
  /// dark bezel rows where ink density is near-constant noise.
  _Band? _largestRowBand(Uint8List ink, int w, int h) {
    final rowInk = List<int>.filled(h, 0);
    var peak = 0;
    for (var y = 0; y < h; y++) {
      var c = 0;
      for (var x = 0; x < w; x++) {
        if (ink[y * w + x] == 1) c++;
      }
      rowInk[y] = c;
      if (c > peak) peak = c;
    }
    if (peak == 0) return null;
    final floor = peak * 0.12;
    _Band? best;
    var start = -1;
    for (var y = 0; y <= h; y++) {
      final active = y < h && rowInk[y] > floor;
      if (active && start < 0) {
        start = y;
      } else if (!active && start >= 0) {
        final band = _Band(start, y - 1);
        if (best == null || band.height > best.height) best = band;
        start = -1;
      }
    }
    return best;
  }

  /// Splits the band `[start..end]` rows into digit cells via a vertical
  /// ink projection. Columns with ink form cells; runs of empty columns
  /// become [_Cell.gap]s (candidate decimal points / spacing).
  List<_Cell> _segmentColumns(Uint8List ink, int w, int start, int end) {
    final colInk = List<int>.filled(w, 0);
    final bandHeight = end - start + 1;
    var peak = 0;
    for (var x = 0; x < w; x++) {
      var c = 0;
      for (var y = start; y <= end; y++) {
        if (ink[y * w + x] == 1) c++;
      }
      colInk[x] = c;
      if (c > peak) peak = c;
    }
    if (peak == 0) return const [];
    final floor = peak * 0.08;

    final cells = <_Cell>[];
    var runStart = -1;
    var emptyStart = -1;
    for (var x = 0; x <= w; x++) {
      final active = x < w && colInk[x] > floor;
      if (active) {
        if (emptyStart >= 0) {
          final gap = _Cell.gap(emptyStart, x - 1);
          // Decide if the gap holds a low-sitting decimal point.
          gap.hasLowInk =
              _gapHasLowInk(ink, w, emptyStart, x - 1, start, end, bandHeight);
          cells.add(gap);
          emptyStart = -1;
        }
        if (runStart < 0) runStart = x;
      } else {
        if (runStart >= 0) {
          cells.add(_Cell(runStart, x - 1, start, end));
          runStart = -1;
          emptyStart = x;
        } else if (emptyStart < 0) {
          emptyStart = x;
        }
      }
    }
    // Drop leading/trailing gaps; merge thin specks into neighbours.
    return _cleanCells(cells);
  }

  bool _gapHasLowInk(
    Uint8List ink,
    int w,
    int x0,
    int x1,
    int yTop,
    int yBottom,
    int bandHeight,
  ) {
    // A decimal point sits in the bottom ~30% of the band.
    final lowStart = yBottom - (bandHeight * 0.30).round();
    var lowInk = 0;
    for (var x = x0; x <= x1; x++) {
      for (var y = lowStart; y <= yBottom; y++) {
        if (ink[y * w + x] == 1) lowInk++;
      }
    }
    final gapWidth = x1 - x0 + 1;
    // Require a compact blob, not a stray column.
    return gapWidth >= 2 &&
        lowInk >= gapWidth &&
        gapWidth <= (bandHeight * 0.5);
  }

  List<_Cell> _cleanCells(List<_Cell> cells) {
    final out = <_Cell>[];
    for (final c in cells) {
      if (c.isGap && (out.isEmpty)) continue; // leading gap
      out.add(c);
    }
    while (out.isNotEmpty && out.last.isGap) {
      out.removeLast();
    }
    return out;
  }

  // -- per-digit segment sampling -------------------------------------

  _Glyph _decodeCell(
    Uint8List ink,
    int w,
    _Cell cell,
    _Band band, {
    required int digitWidth,
  }) {
    final cellWidth = cell.width;

    // A very narrow cell is a 1 (only segments b+c lit).
    if (cellWidth < digitWidth * oneWidthRatio) {
      return const _Glyph('1', true);
    }

    final on = _sampleSegments(ink, w, cell, band);
    final key = _patternKey(on);
    final value = kSegmentTable[key];
    if (value != null) return _Glyph(value, true);
    return const _Glyph('?', false);
  }

  /// `true` when [cell] is a decimal point rather than a digit: it is
  /// markedly narrower than a digit, and its ink sits in the bottom
  /// fifth of the band. (A "1" is narrow too, but its ink runs the
  /// full height of the band — the height test separates them.)
  bool _isDecimalCell(
    Uint8List ink,
    int w,
    _Cell cell,
    _Band band, {
    required int digitWidth,
  }) {
    if (cell.width > digitWidth * 0.5) return false;
    final topCut = band.start + (band.height * 0.55).round();
    var topInk = 0;
    var bottomInk = 0;
    for (var x = cell.start; x <= cell.end; x++) {
      for (var y = band.start; y <= band.end; y++) {
        if (ink[y * w + x] != 1) continue;
        if (y < topCut) {
          topInk++;
        } else {
          bottomInk++;
        }
      }
    }
    // A "1" has lots of ink up high; a "." has essentially none.
    return bottomInk > 0 && topInk <= bottomInk * 0.25;
  }

  /// Samples the seven canonical segment regions of a digit cell.
  /// Layout (standard 7-seg):
  ///
  ///     aaaa
  ///    f    b
  ///    f    b
  ///     gggg
  ///    e    c
  ///    e    c
  ///     dddd
  List<bool> _sampleSegments(
    Uint8List ink,
    int w,
    _Cell cell,
    _Band band,
  ) {
    final x0 = cell.start;
    final cw = cell.width;
    final ch = band.height;
    final yTop = band.start;

    double frac(double rx0, double ry0, double rx1, double ry1) {
      final ax0 = x0 + (rx0 * cw).round();
      final ax1 = x0 + (rx1 * cw).round();
      final ay0 = yTop + (ry0 * ch).round();
      final ay1 = yTop + (ry1 * ch).round();
      var inkCount = 0;
      var total = 0;
      for (var y = ay0; y < ay1; y++) {
        for (var x = ax0; x < ax1; x++) {
          total++;
          if (ink[y * w + x] == 1) inkCount++;
        }
      }
      return total == 0 ? 0 : inkCount / total;
    }

    // Segment sampling windows (fractions of the cell box). Each window
    // is centred on the stroke and kept narrow so an adjacent lit
    // segment doesn't bleed in.
    final a = frac(0.20, 0.00, 0.80, 0.18);
    final b = frac(0.70, 0.08, 1.00, 0.48);
    final c = frac(0.70, 0.52, 1.00, 0.92);
    final d = frac(0.20, 0.82, 0.80, 1.00);
    final e = frac(0.00, 0.52, 0.30, 0.92);
    final f = frac(0.00, 0.08, 0.30, 0.48);
    final g = frac(0.20, 0.41, 0.80, 0.59);

    bool onSeg(double v) => v >= segmentOnThreshold;
    return [onSeg(a), onSeg(b), onSeg(c), onSeg(d), onSeg(e), onSeg(f), onSeg(g)];
  }

  String _patternKey(List<bool> on) =>
      on.map((b) => b ? '1' : '0').join();
}

/// A horizontal band of rows that contains digits.
class _Band {
  final int start;
  final int end;
  const _Band(this.start, this.end);
  int get height => end - start + 1;
}

/// A vertical slice of the band: either a digit cell or an empty gap.
class _Cell {
  final int start;
  final int end;
  final int bandStart;
  final int bandEnd;
  final bool isGap;
  bool hasLowInk;

  _Cell(this.start, this.end, this.bandStart, this.bandEnd)
      : isGap = false,
        hasLowInk = false;

  _Cell.gap(this.start, this.end)
      : bandStart = 0,
        bandEnd = 0,
        isGap = true,
        hasLowInk = false;

  int get width => end - start + 1;
}

class _Glyph {
  final String value;
  final bool matched;
  const _Glyph(this.value, this.matched);
}
