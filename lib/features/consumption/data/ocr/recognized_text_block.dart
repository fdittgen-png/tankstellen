// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

/// An axis-aligned bounding box for a recognized OCR fragment, expressed
/// in source-image pixel coordinates (#2478).
///
/// PURE Dart — deliberately no `dart:ui`, `package:flutter` or
/// `google_mlkit_*` import — so the label-anchored extractor that
/// consumes it is unit-testable in plain `dart test` without a platform
/// channel. The thin adapter in `receipt_scan_service.dart` maps ML Kit's
/// `Rect` into this shape; everything downstream speaks only [OcrBox].
@immutable
class OcrBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Centre X of the box.
  double get cx => (left + right) / 2;

  /// Centre Y of the box.
  double get cy => (top + bottom) / 2;

  double get width => right - left;
  double get height => bottom - top;

  /// Rotates this box 90° clockwise inside an image of height [imageHeight]
  /// — the `(x, y) → (H − y, x)` mapping. Used to prove the label-anchored
  /// extractor is rotation-invariant (#2478): a tilted pump display must
  /// read the same triple as an upright one because the extractor only
  /// reasons about *relative* label↔value geometry, never absolute pixels.
  OcrBox rotate90(double imageHeight) {
    // Each corner (x, y) maps to (H − y, x). The clockwise turn swaps
    // which corners are the new extremes, so recompute min/max.
    final nx1 = imageHeight - bottom;
    final nx2 = imageHeight - top;
    final ny1 = left;
    final ny2 = right;
    return OcrBox(
      left: nx1 < nx2 ? nx1 : nx2,
      right: nx1 < nx2 ? nx2 : nx1,
      top: ny1 < ny2 ? ny1 : ny2,
      bottom: ny1 < ny2 ? ny2 : ny1,
    );
  }

  @override
  String toString() => 'OcrBox($left, $top, $right, $bottom)';
}

/// A single recognized text fragment plus its geometry (#2478).
///
/// Maps one ML Kit `TextBlock` (or, when a block spans the whole readout
/// strip, one `TextLine`) into a geometry-bearing token the label-anchored
/// extractor can reason over. The flat `recognized.text` string that the
/// old pipeline kept discards exactly this geometry — which is why a bare
/// `PRIX` regex could not tell which number sat *under* which label.
@immutable
class RecognizedTextBlock {
  final String text;
  final OcrBox box;

  const RecognizedTextBlock({required this.text, required this.box});

  /// Returns a copy with [box] rotated 90° clockwise (see [OcrBox.rotate90]).
  RecognizedTextBlock rotate90(double imageHeight) =>
      RecognizedTextBlock(text: text, box: box.rotate90(imageHeight));

  @override
  String toString() => 'RecognizedTextBlock("$text", $box)';
}
