// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../data/ocr/ocr_trace_package.dart';

/// The classification colour key shared by the painter and its legend
/// (#2518). Labels are blue, numerics green, noise grey; the chosen
/// anchor pair is joined and a derived value is dashed amber.
class OcrBlockOverlayColors {
  OcrBlockOverlayColors._();

  static const label = Color(0xFF2196F3); // blue
  static const numeric = Color(0xFF4CAF50); // green
  static const noise = Color(0xFF9E9E9E); // grey
  static const anchor = Color(0xFFFFC107); // amber (chosen anchor join)
  static const derived = Color(0xFFFF9800); // amber (dashed, derived)
}

/// Draws the ML Kit block geometry of an [OcrTracePackage] over the source
/// image (#2518, Epic #2516 Child 2) — the visual companion to the steps
/// panel in the gated OCR tester.
///
/// Modelled on `pump_alignment_overlay._AlignmentPainter`: a pure
/// [CustomPainter] that maps the recorded pixel boxes into the laid-out
/// widget rect, so the caller can stack it inside an `InteractiveViewer`
/// over the captured photo and pan/zoom both together.
///
/// Each block box is tinted by its classification — labels blue, numerics
/// green, everything else grey — using the per-block `kind` recorded by
/// the trace. The chosen anchor pair (the label and the numeric the
/// binder actually picked) is joined by an amber line; a field the
/// cross-check *derived* is outlined with a dashed amber box so a recovered
/// value is visually distinct from a value read straight off the display.
///
/// Tapping is handled by the host (it hit-tests [blockRectFor]); the
/// painter only draws.
class OcrBlockOverlayPainter extends CustomPainter {
  /// The recorded trace whose `mlkit.blocks` + classification + anchors
  /// drive the overlay. Null blocks → nothing is drawn.
  final OcrTracePackage package;

  /// Pixel size of the source image the boxes were recorded against.
  /// Boxes are scaled from this into the laid-out [Size] in `paint`.
  final Size imageSize;

  /// Index of the block the user tapped, highlighted with a thicker
  /// border. Null when nothing is selected.
  final int? selectedIndex;

  const OcrBlockOverlayPainter({
    required this.package,
    required this.imageSize,
    this.selectedIndex,
  });

  /// Classification kind recorded for the block whose text equals
  /// [blockText], or `noise` when the classifier never tagged it.
  String _kindFor(String blockText) {
    for (final c in package.classification) {
      if (c.text == blockText) return c.kind;
    }
    return 'noise';
  }

  Color _colorForKind(String kind) => switch (kind) {
        'label' => OcrBlockOverlayColors.label,
        'numeric' => OcrBlockOverlayColors.numeric,
        _ => OcrBlockOverlayColors.noise,
      };

  /// Maps the recorded pixel box of block [index] into the laid-out
  /// [size]. Returns `Rect.zero` when there is no ML Kit geometry.
  Rect blockRectFor(int index, Size size) {
    final blocks = package.mlkit?.blocks ?? const [];
    if (index < 0 || index >= blocks.length) return Rect.zero;
    return _scaled(blocks[index], size);
  }

  Rect _scaled(OcrTraceBlock b, Size size) {
    final sx = imageSize.width <= 0 ? 1.0 : size.width / imageSize.width;
    final sy = imageSize.height <= 0 ? 1.0 : size.height / imageSize.height;
    return Rect.fromLTRB(b.left * sx, b.top * sy, b.right * sx, b.bottom * sy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final blocks = package.mlkit?.blocks ?? const [];
    if (blocks.isEmpty) return;

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final rect = _scaled(block, size);
      final kind = _kindFor(block.text);
      final color = _colorForKind(kind);
      final selected = i == selectedIndex;

      final fill = Paint()
        ..color = color.withValues(alpha: selected ? 0.30 : 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);

      final stroke = Paint()
        ..color = color.withValues(alpha: selected ? 1.0 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3.0 : 1.5;
      canvas.drawRect(rect, stroke);
    }

    _paintAnchorJoin(canvas, size, blocks);
    _paintDerived(canvas, size, blocks);
  }

  /// Joins each chosen label→numeric anchor pair with an amber line so the
  /// reader can see which number the binder bound to which label.
  void _paintAnchorJoin(Canvas canvas, Size size, List<OcrTraceBlock> blocks) {
    final chosen = package.anchors.where((a) => a.chosen);
    if (chosen.isEmpty) return;
    final join = Paint()
      ..color = OcrBlockOverlayColors.anchor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (final a in chosen) {
      final labelRect = _firstRectWhere(blocks, size, a.labelText);
      final numericRect = _numericRect(blocks, size, a.numericValue);
      if (labelRect == null || numericRect == null) continue;
      canvas.drawLine(labelRect.center, numericRect.center, join);
    }
  }

  /// Outlines any field the cross-check DERIVED (not read) with a dashed
  /// amber box around its numeric block, so a recovered value stands out.
  void _paintDerived(Canvas canvas, Size size, List<OcrTraceBlock> blocks) {
    final derived = package.result?.derived ?? const <String>{};
    if (derived.isEmpty) return;
    // The derived numeric value (when one ran) sits in crossCheck.computed.
    final computed = package.crossCheck?.computed;
    if (computed == null) return;
    final rect = _numericRect(blocks, size, computed);
    if (rect == null) return;
    _paintDashedRect(canvas, rect.inflate(2), OcrBlockOverlayColors.derived);
  }

  Rect? _firstRectWhere(
    List<OcrTraceBlock> blocks,
    Size size,
    String text,
  ) {
    for (final b in blocks) {
      if (b.text == text || b.text.contains(text)) return _scaled(b, size);
    }
    return null;
  }

  Rect? _numericRect(List<OcrTraceBlock> blocks, Size size, double value) {
    // Match the block whose parsed text carries the value's digits — a
    // best-effort visual hint, not a parse (the trace already parsed it).
    final needle = value.toString();
    for (final b in blocks) {
      final t = b.text.replaceAll(',', '.');
      if (t.contains(needle) || t.contains(value.toStringAsFixed(2))) {
        return _scaled(b, size);
      }
    }
    return null;
  }

  void _paintDashedRect(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    const dash = 6.0;
    const gap = 4.0;
    _dashLine(canvas, rect.topLeft, rect.topRight, dash, gap, paint);
    _dashLine(canvas, rect.topRight, rect.bottomRight, dash, gap, paint);
    _dashLine(canvas, rect.bottomRight, rect.bottomLeft, dash, gap, paint);
    _dashLine(canvas, rect.bottomLeft, rect.topLeft, dash, gap, paint);
  }

  void _dashLine(
    Canvas canvas,
    Offset a,
    Offset b,
    double dash,
    double gap,
    Paint paint,
  ) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * (drawn + dash).clamp(0.0, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant OcrBlockOverlayPainter old) =>
      old.package != package ||
      old.imageSize != imageSize ||
      old.selectedIndex != selectedIndex;
}
