// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../data/ocr/ocr_geometry.dart';

/// Framing reticle drawn over the pump-display camera preview (#1868).
///
/// A centred, wide rounded-rectangle frame the user lines the
/// three-number pump readout up inside, so the captured photo holds
/// just the display — not the metrology stickers, pump logos and
/// card-reader text the OCR parser would otherwise have to strip.
///
/// Purely decorative — wrapped in [IgnorePointer] so taps fall through
/// to the capture button beneath it.
///
/// #2275 — the reticle is no longer *only* decorative: the recognition
/// pipeline crops the captured frame to [normalizedRect] FIRST (so all
/// downstream work runs on the readout, not the whole frame). The frame
/// the user sees and the rect the OCR crops to are therefore guaranteed
/// to match. [widthFactor] / [aspectRatio] are the single source of
/// truth for both.
class PumpDisplayReticle extends StatelessWidget {
  /// Fraction of the preview width the reticle spans.
  static const double widthFactor = 0.86;

  /// A pump readout is a wide three-number strip.
  static const double reticleAspectRatio = 16 / 5;

  const PumpDisplayReticle({super.key});

  /// The centred reticle expressed as a `0..1` rect over a preview of
  /// the given [previewAspectRatio] (`width / height`). The OCR pipeline
  /// uses this to crop the captured photo to exactly what the user
  /// framed. Falls back to the full frame if the maths degenerates.
  static OcrNormalizedRect normalizedRect(double previewAspectRatio) {
    if (previewAspectRatio <= 0) return OcrNormalizedRect.full;
    final w = widthFactor.clamp(0.0, 1.0);
    // Height (as a fraction of the preview) the wide strip occupies:
    // reticleW_px / aspect = reticleH_px → as fractions of preview H.
    final h = (w * previewAspectRatio / reticleAspectRatio).clamp(0.0, 1.0);
    final left = (1 - w) / 2;
    final top = (1 - h) / 2;
    return OcrNormalizedRect(left: left, top: top, width: w, height: h);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: AspectRatio(
            aspectRatio: reticleAspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
