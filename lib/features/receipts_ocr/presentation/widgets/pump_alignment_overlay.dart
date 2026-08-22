// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../data/ocr/ocr_geometry.dart';
import '../../data/ocr/pump_ocr_config.dart';

/// Guided alignment overlay drawn on the pump-display camera preview
/// (#2276).
///
/// Extends [PumpDisplayReticle]'s simple white box with:
///
/// - **Orientation-aware frame** — wide strip for horizontal pump
///   displays; narrow column for vertical stacked layouts.
/// - **Per-field guide slots** — labelled sub-rectangles inside the
///   frame; labels come from the JSON config's `displayLabels` map
///   (e.g. "PRIX", "VOLUME", "PRIX DU LITRE") so they are never
///   hard-coded here. A generic slot number is shown when the config
///   has no label for a field.
/// - **Glare / alignment tint** — the frame border turns amber when
///   [isOverGlared] is true and stays white when the frame is clean.
///
/// Wrapped in [IgnorePointer] so taps fall through to the shutter.
class PumpAlignmentOverlay extends StatelessWidget {
  /// Fraction of the preview's shorter axis the frame spans.
  static const double widthFactor = 0.86;

  /// Aspect ratio for a horizontal three-value strip.
  static const double horizontalAspect = 16 / 5;

  /// Aspect ratio for a vertical stacked display.
  static const double verticalAspect = 5 / 16;

  /// Whether the framed region is over-glared.  When `true` the border
  /// colour switches to amber to reinforce the text warning.
  final bool isOverGlared;

  /// The current display orientation, set by the user toggle.
  final OcrDisplayOrientation orientation;

  /// Per-field spec from the active brand template, or `null` when no
  /// template matched (overlay still draws the outer frame).
  final OcrPumpFieldSpec? fieldSpec;

  const PumpAlignmentOverlay({
    super.key,
    this.isOverGlared = false,
    this.orientation = OcrDisplayOrientation.horizontal,
    this.fieldSpec,
  });

  /// The centred frame in normalised `0..1` coordinates for [orientation]
  /// and the given [previewAspectRatio] (`width / height`). Used by the
  /// camera screen to crop the captured photo to the visible guide rect.
  static OcrNormalizedRect normalizedRect(
    double previewAspectRatio,
    OcrDisplayOrientation orientation,
  ) {
    if (previewAspectRatio <= 0) return OcrNormalizedRect.full;
    final isVertical = orientation == OcrDisplayOrientation.vertical;
    final w = widthFactor.clamp(0.0, 1.0);
    final targetAspect =
        isVertical ? verticalAspect : horizontalAspect;
    // For vertical: the frame is narrower (use widthFactor of preview
    // SHORT axis which, on a portrait phone, is the width).
    if (isVertical) {
      // Frame width = widthFactor * 0.55 (keep it narrower than the
      // horizontal strip so it actually resembles a column).
      final fw = (w * 0.55).clamp(0.0, 1.0);
      final fh = (fw * previewAspectRatio / targetAspect).clamp(0.0, 1.0);
      return OcrNormalizedRect(
        left: (1 - fw) / 2,
        top: (1 - fh) / 2,
        width: fw,
        height: fh,
      );
    }
    // Horizontal: same calculation as PumpDisplayReticle.normalizedRect.
    final h = (w * previewAspectRatio / targetAspect).clamp(0.0, 1.0);
    return OcrNormalizedRect(
      left: (1 - w) / 2,
      top: (1 - h) / 2,
      width: w,
      height: h,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isOverGlared ? Colors.amber : Colors.white;
    return IgnorePointer(
      child: CustomPaint(
        painter: _AlignmentPainter(
          borderColor: borderColor,
          orientation: orientation,
          fieldSpec: fieldSpec,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws the framing rectangle and per-field guide slots.
class _AlignmentPainter extends CustomPainter {
  final Color borderColor;
  final OcrDisplayOrientation orientation;
  final OcrPumpFieldSpec? fieldSpec;

  const _AlignmentPainter({
    required this.borderColor,
    required this.orientation,
    this.fieldSpec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isVertical = orientation == OcrDisplayOrientation.vertical;
    final frameRect = _frameRect(size, isVertical);

    // Dark vignette outside the guide frame.
    _paintVignette(canvas, size, frameRect);

    // Outer frame border.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final rrect = RRect.fromRectAndRadius(frameRect, const Radius.circular(12));
    canvas.drawRRect(rrect, borderPaint);

    // Corner brackets (inner highlight).
    _paintCornerBrackets(canvas, frameRect, borderColor);

    // Per-field guide slots (when a brand template is loaded).
    final spec = fieldSpec;
    if (spec != null) {
      _paintFieldSlot(canvas, size, frameRect, spec.total,
          spec.displayLabels['total'], 1, isVertical);
      _paintFieldSlot(canvas, size, frameRect, spec.volume,
          spec.displayLabels['volume'], 2, isVertical);
      _paintFieldSlot(canvas, size, frameRect, spec.pricePerLitre,
          spec.displayLabels['pricePerLitre'], 3, isVertical);
    }
  }

  Rect _frameRect(Size size, bool isVertical) {
    final w = size.width;
    final h = size.height;
    if (isVertical) {
      final fw = w * PumpAlignmentOverlay.widthFactor * 0.55;
      final fh = fw * (1 / PumpAlignmentOverlay.verticalAspect);
      final left = (w - fw) / 2;
      final top = (h - fh) / 2;
      return Rect.fromLTWH(left, top, fw, fh.clamp(0, h));
    }
    final fw = w * PumpAlignmentOverlay.widthFactor;
    final aspect = w / h;
    final fh = (fw * aspect / PumpAlignmentOverlay.horizontalAspect)
        .clamp(0.0, h);
    final left = (w - fw) / 2;
    final top = (h - fh) / 2;
    return Rect.fromLTWH(left, top, fw, fh);
  }

  void _paintVignette(Canvas canvas, Size size, Rect frameRect) {
    final vigPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    // Top strip.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, frameRect.top), vigPaint);
    // Bottom strip.
    canvas.drawRect(
        Rect.fromLTWH(0, frameRect.bottom, size.width,
            size.height - frameRect.bottom),
        vigPaint);
    // Left strip.
    canvas.drawRect(
        Rect.fromLTWH(0, frameRect.top, frameRect.left, frameRect.height),
        vigPaint);
    // Right strip.
    canvas.drawRect(
        Rect.fromLTWH(frameRect.right, frameRect.top,
            size.width - frameRect.right, frameRect.height),
        vigPaint);
  }

  void _paintCornerBrackets(Canvas canvas, Rect rect, Color color) {
    final bracketLen = (rect.shortestSide * 0.15).clamp(12.0, 28.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Each entry: (anchor, arm1, arm2).
    final corners = <(Offset, Offset, Offset)>[
      (rect.topLeft,
          Offset(rect.left + bracketLen, rect.top),
          Offset(rect.left, rect.top + bracketLen)),
      (rect.topRight,
          Offset(rect.right - bracketLen, rect.top),
          Offset(rect.right, rect.top + bracketLen)),
      (rect.bottomLeft,
          Offset(rect.left + bracketLen, rect.bottom),
          Offset(rect.left, rect.bottom - bracketLen)),
      (rect.bottomRight,
          Offset(rect.right - bracketLen, rect.bottom),
          Offset(rect.right, rect.bottom - bracketLen)),
    ];
    for (final (anchor, arm1, arm2) in corners) {
      canvas.drawLine(anchor, arm1, paint);
      canvas.drawLine(anchor, arm2, paint);
    }
  }

  void _paintFieldSlot(
    Canvas canvas,
    Size size,
    Rect frameRect,
    OcrNormalizedRect slotNorm,
    String? label,
    int slotIndex,
    bool isVertical,
  ) {
    // The slot rect is normalised relative to the full preview.
    final slotRect = Rect.fromLTWH(
      slotNorm.left * size.width,
      slotNorm.top * size.height,
      slotNorm.width * size.width,
      slotNorm.height * size.height,
    );

    // Skip slots that fall entirely outside the frame guide.
    if (!frameRect.overlaps(slotRect)) return;

    final slotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawRect(slotRect, slotPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(slotRect, strokePaint);

    // Label — data from JSON config (pump display text) or slot number.
    final displayLabel = label ?? '#$slotIndex';
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: (slotRect.height * 0.45).clamp(9.0, 14.0),
      fontWeight: FontWeight.w600,
    );
    final tp = TextPainter(
      text: TextSpan(text: displayLabel, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: slotRect.width - 4);
    tp.paint(
      canvas,
      Offset(
        slotRect.left + 3,
        slotRect.top + (slotRect.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _AlignmentPainter old) =>
      old.borderColor != borderColor ||
      old.orientation != orientation ||
      old.fieldSpec != fieldSpec;
}
