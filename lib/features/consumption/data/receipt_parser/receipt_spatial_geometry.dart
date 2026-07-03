// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../ocr/recognized_text_block.dart';

/// Rotation normalization + row-alignment geometry for the spatial
/// receipt parser (#3458).
///
/// The field receipt (Pézenas E85, 2026-07-03) was photographed
/// 90°-rotated; a hand-held shot can arrive at any of the four
/// orientations. Rather than guessing the exact rotation, the parser
/// only needs the ROW axis to be horizontal:
///
///  * **90°/270° frames** — text boxes come out taller than wide.
///    Detected from the median aspect ratio of the multi-character
///    blocks and fixed by TRANSPOSING every box (`(x, y) → (y, x)`),
///    which restores horizontal rows (possibly mirrored).
///  * **180° / mirrored frames** — rows are already horizontal, just in
///    reversed order and with the value column on the other side. The
///    row pairing below is side-agnostic (nearest horizontal gap on the
///    SAME row, either side), so no further correction is needed.
///
/// Together this makes label→value pairing invariant under all four
/// 90°-multiple orientations — the receipt twin of the #2478 proof that
/// the pump extractor only reasons about relative geometry.

/// The orientation-normalized block set.
@immutable
class ReceiptFrame {
  final List<RecognizedTextBlock> blocks;

  /// `true` when the frame arrived 90°/270°-rotated and was transposed.
  final bool transposed;

  const ReceiptFrame({required this.blocks, required this.transposed});
}

/// Swaps the axes of [box] (`(x, y) → (y, x)`).
OcrBox transposeBox(OcrBox box) => OcrBox(
      left: box.top,
      top: box.left,
      right: box.bottom,
      bottom: box.right,
    );

/// Detects whether the dominant text axis is vertical (a 90°/270° frame)
/// and, if so, transposes every block so rows become horizontal again.
///
/// The signal: printed words are wider than tall in reading orientation.
/// Blocks with ≥ 4 visible characters vote with their aspect ratio; a
/// median below 1 means the text runs vertically in this frame.
ReceiptFrame normalizeReceiptOrientation(List<RecognizedTextBlock> blocks) {
  final aspects = <double>[];
  for (final b in blocks) {
    if (b.text.trim().length < 4) continue;
    final h = b.box.height;
    if (h <= 0) continue;
    aspects.add(b.box.width / h);
  }
  if (aspects.isEmpty) {
    return ReceiptFrame(blocks: blocks, transposed: false);
  }
  aspects.sort();
  final median = aspects[aspects.length ~/ 2];
  if (median >= 1.0) {
    return ReceiptFrame(blocks: blocks, transposed: false);
  }
  return ReceiptFrame(
    blocks: [
      for (final b in blocks)
        RecognizedTextBlock(text: b.text, box: transposeBox(b.box)),
    ],
    transposed: true,
  );
}

/// Fraction of the SMALLER box height shared by the vertical spans of
/// [a] and [b] — 1.0 when the smaller box lies fully inside the other's
/// row band, 0 when they don't overlap vertically.
double rowOverlapFraction(OcrBox a, OcrBox b) {
  final overlap = (a.bottom < b.bottom ? a.bottom : b.bottom) -
      (a.top > b.top ? a.top : b.top);
  if (overlap <= 0) return 0;
  final ha = a.height;
  final hb = b.height;
  final smaller = ha < hb ? ha : hb;
  if (smaller <= 0) return 0;
  return overlap / smaller;
}

/// Horizontal gap between [a] and [b] — 0 when their x-spans overlap,
/// else the distance between the facing edges. Side-agnostic so a
/// 180°-rotated frame (value column left of the labels) pairs the same.
double horizontalGap(OcrBox a, OcrBox b) {
  if (a.right < b.left) return b.left - a.right;
  if (b.right < a.left) return a.left - b.right;
  return 0;
}

/// Minimum row-overlap fraction for a value to count as sitting on a
/// label's row. Real pairs on the recorded FR receipts overlap 0.68-1.0;
/// the nearest CROSS-row value (the master mispairing) overlaps ≤ 0.15.
const double kReceiptRowOverlapMin = 0.35;
