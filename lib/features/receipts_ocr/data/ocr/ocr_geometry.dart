// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Resolution-independent geometry for the OCR pipeline (#2275):
/// the normalized region-of-interest rectangle the camera reticle and
/// the JSON brand templates both speak, plus the glare-rejection policy.
library;

/// A rectangle expressed as fractions (`0..1`) of an image's width and
/// height. Lets the camera reticle and the JSON brand templates describe
/// a region of interest independently of the captured resolution.
class OcrNormalizedRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const OcrNormalizedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// The whole image.
  static const full =
      OcrNormalizedRect(left: 0, top: 0, width: 1, height: 1);

  double get right => left + width;
  double get bottom => top + height;

  /// Parse from a `{left,top,width,height}` JSON map. Returns `null`
  /// when any component is missing, non-numeric, or out of the `0..1`
  /// box — callers log and skip the malformed template.
  static OcrNormalizedRect? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final l = _num(raw['left']);
    final t = _num(raw['top']);
    final w = _num(raw['width']);
    final h = _num(raw['height']);
    if (l == null || t == null || w == null || h == null) return null;
    if (l < 0 || t < 0 || w <= 0 || h <= 0) return null;
    if (l + w > 1.0001 || t + h > 1.0001) return null;
    return OcrNormalizedRect(left: l, top: t, width: w, height: h);
  }

  static double? _num(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  @override
  String toString() => 'OcrNormalizedRect($left, $top, $width, $height)';
}

/// Thresholds for the over-glare auto-reject (#2275 concern 2).
class GlarePolicy {
  /// Reject (and prompt re-angle) when more than this fraction of the
  /// ROI is near-saturated white.
  final double rejectAbove;

  const GlarePolicy({this.rejectAbove = 0.35});

  static const standard = GlarePolicy();
}
