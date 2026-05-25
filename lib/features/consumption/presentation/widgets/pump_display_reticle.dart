// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Framing reticle drawn over the pump-display camera preview (#1868).
///
/// A centred, wide rounded-rectangle frame the user lines the
/// three-number pump readout up inside, so the captured photo holds
/// just the display — not the metrology stickers, pump logos and
/// card-reader text the OCR parser would otherwise have to strip.
///
/// Purely decorative — wrapped in [IgnorePointer] so taps fall through
/// to the capture button beneath it.
class PumpDisplayReticle extends StatelessWidget {
  const PumpDisplayReticle({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.86,
          child: AspectRatio(
            // A pump readout is a wide three-number strip.
            aspectRatio: 16 / 5,
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
