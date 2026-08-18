// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '_pump_label_table.dart';
import 'ocr_geometry.dart';
import 'pump_ocr_config.dart';
import 'recognized_text_block.dart';

/// The direction the 7-segment LCD value sits relative to its printed label
/// on the pump (#3397). On a Tokheim vertical display the digits are directly
/// ABOVE each "PRIX" / "VOLUME" / "PRIX DU LITRE" label.
enum ValueAnchorDirection {
  above,
  below,
  left,
  right;

  static ValueAnchorDirection fromJson(Object? raw) {
    switch (raw) {
      case 'below':
        return ValueAnchorDirection.below;
      case 'left':
        return ValueAnchorDirection.left;
      case 'right':
        return ValueAnchorDirection.right;
      case 'above':
      default:
        return ValueAnchorDirection.above;
    }
  }
}

/// How to place a 7-segment value ROI relative to the label box ML Kit
/// located for that field (#3397 / Epic #2823).
///
/// The fixed template ROIs assumed the user framed the display canonically;
/// on a hand-held photo the LCD lands at a different position/scale and the
/// fixed rectangle samples the wrong pixels. ML Kit DOES reliably read the
/// printed labels (with boxes), so the value ROI is derived from its label's
/// box instead — wherever the label landed, the value ROI follows.
///
/// The multipliers are deliberately GENEROUS: the [SevenSegmentRecognizer]
/// row/column-segments WITHIN the ROI, so the ROI only has to CONTAIN the
/// digits (with margin), not bound them tightly. That tolerance is what makes
/// label anchoring robust without pixel-perfect per-pump tuning.
class OcrValueAnchor {
  /// Where the value sits relative to its label.
  final ValueAnchorDirection direction;

  /// Separation between the label edge and the value ROI, as a fraction of
  /// the label's extent along [direction].
  final double gap;

  /// Value ROI width ÷ label width.
  final double widthFactor;

  /// Value ROI height ÷ label height.
  final double heightFactor;

  const OcrValueAnchor({
    this.direction = ValueAnchorDirection.above,
    this.gap = 0.15,
    this.widthFactor = 1.4,
    this.heightFactor = 2.4,
  });

  /// Parse a `{direction, gap, widthFactor, heightFactor}` map. Returns null
  /// (anchoring disabled → fixed template ROIs) when the key is absent, so
  /// every template without it is byte-for-byte unchanged.
  static OcrValueAnchor? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double f(Object? v, double dflt) =>
        v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? dflt : dflt);
    return OcrValueAnchor(
      direction: ValueAnchorDirection.fromJson(raw['direction']),
      gap: f(raw['gap'], 0.15),
      widthFactor: f(raw['widthFactor'], 1.4),
      heightFactor: f(raw['heightFactor'], 2.4),
    );
  }
}

/// The field ROIs to feed the recognizer, plus which of them were
/// label-anchored (vs. left at the fixed template fallback) — recorded on the
/// trace so a field export answers "did the recognizer aim at the digits".
class AnchoredFieldSpec {
  final OcrPumpFieldSpec fields;
  final Set<PumpField> anchored;
  const AnchoredFieldSpec(this.fields, this.anchored);

  int get anchoredCount => anchored.length;
}

/// Derive the 7-segment value ROIs from the labels ML Kit located, instead of
/// the fixed template rectangles (#3397, the missing core of Epic #2823).
///
/// For each field: find the heaviest-classified, largest matching label block
/// ("PRIX DU LITRE" outranks bare "PRIX" via [classifyPumpLabel]'s weights),
/// then place the value ROI relative to that label per [anchor]. A field whose
/// label ML Kit did not find keeps its fixed [template] ROI, so the result is
/// never worse than today.
///
/// [blocks] boxes and the recognizer frame share pixel coordinates (both are
/// `cropToRoi(bakeOrientation(decode), roi)` with no resize), so block boxes
/// are normalised by [frameWidth]/[frameHeight] into the 0..1 ROI space.
AnchoredFieldSpec resolveLabelAnchoredFields({
  required OcrPumpFieldSpec template,
  required List<RecognizedTextBlock> blocks,
  required int frameWidth,
  required int frameHeight,
  required OcrValueAnchor anchor,
}) {
  if (frameWidth <= 0 || frameHeight <= 0 || blocks.isEmpty) {
    return AnchoredFieldSpec(template, const {});
  }

  // Best (largest-area) label block per field.
  final labelBoxes = <PumpField, OcrBox>{};
  for (final b in blocks) {
    final field = classifyPumpLabel(b.text);
    if (field == null) continue;
    final prev = labelBoxes[field];
    final area = b.box.width * b.box.height;
    if (prev == null || area > prev.width * prev.height) {
      labelBoxes[field] = b.box;
    }
  }

  final anchored = <PumpField>{};
  OcrNormalizedRect pick(PumpField field, OcrNormalizedRect fallback) {
    final label = labelBoxes[field];
    if (label == null) return fallback;
    final roi = _valueRoiFromLabel(label, frameWidth, frameHeight, anchor);
    if (roi == null) return fallback;
    anchored.add(field);
    return roi;
  }

  return AnchoredFieldSpec(
    OcrPumpFieldSpec(
      total: pick(PumpField.total, template.total),
      volume: pick(PumpField.volume, template.volume),
      pricePerLitre: pick(PumpField.pricePerLitre, template.pricePerLitre),
      displayLabels: template.displayLabels,
    ),
    anchored,
  );
}

/// Place a value ROI relative to a (pixel-space) [label] box per [anchor],
/// returning a normalised 0..1 rect clamped to the frame, or null when it
/// collapses to a degenerate sliver (the caller then keeps the fixed ROI).
OcrNormalizedRect? _valueRoiFromLabel(
  OcrBox label,
  int frameWidth,
  int frameHeight,
  OcrValueAnchor anchor,
) {
  // Normalise the label box to 0..1.
  final lLeft = label.left / frameWidth;
  final lTop = label.top / frameHeight;
  final lW = label.width / frameWidth;
  final lH = label.height / frameHeight;
  if (lW <= 0 || lH <= 0) return null;
  final lCx = lLeft + lW / 2;
  final lCy = lTop + lH / 2;

  final w = lW * anchor.widthFactor;
  final h = lH * anchor.heightFactor;
  double cx;
  double cy;
  switch (anchor.direction) {
    case ValueAnchorDirection.above:
      cx = lCx;
      cy = lTop - anchor.gap * lH - h / 2;
    case ValueAnchorDirection.below:
      cx = lCx;
      cy = (lTop + lH) + anchor.gap * lH + h / 2;
    case ValueAnchorDirection.left:
      cy = lCy;
      cx = lLeft - anchor.gap * lW - w / 2;
    case ValueAnchorDirection.right:
      cy = lCy;
      cx = (lLeft + lW) + anchor.gap * lW + w / 2;
  }

  final left = (cx - w / 2).clamp(0.0, 1.0);
  final top = (cy - h / 2).clamp(0.0, 1.0);
  final right = (cx + w / 2).clamp(0.0, 1.0);
  final bottom = (cy + h / 2).clamp(0.0, 1.0);
  final cw = right - left;
  final ch = bottom - top;
  // A useful ROI must retain real area after clamping.
  if (cw < 0.03 || ch < 0.03) return null;
  return OcrNormalizedRect(left: left, top: top, width: cw, height: ch);
}
