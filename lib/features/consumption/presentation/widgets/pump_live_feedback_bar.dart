// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/ocr/ocr_geometry.dart';

/// Thin feedback strip shown beneath the alignment overlay (#2276, #2477).
///
/// Renders one of four states in priority order:
///
///  1. **Rotate-to-landscape** (red, highest priority, #2477) — the
///     phone is held portrait. The wide pump display only fills the
///     frame (large, upright digits) when the phone is sideways, so
///     this message overrides every other state and the parent screen
///     disables the shutter until the user rotates.
///  2. **Glare warning** (amber) — the framed region is too bright /
///     washed out; the user is asked to re-angle.
///  3. **Align hint** (semi-transparent dark pill) — steady-state
///     instruction to line the display inside the frame.
///  4. Nothing — once a capture is in progress the bar is hidden so
///     the shutter button has the user's full attention.
///
/// This widget is purely presentational — it emits no events.  The
/// parent camera screen owns the live luminance sampling + native
/// orientation read and passes [isOverGlared] / [isPortrait] down.
class PumpLiveFeedbackBar extends StatelessWidget {
  /// `true` when the sampled ROI is over-glared.
  final bool isOverGlared;

  /// `true` when the device is held in portrait. Takes priority over
  /// every other state: the bar shows the rotate-to-landscape prompt
  /// and the parent screen disables the shutter (#2477).
  final bool isPortrait;

  /// Whether a capture is currently in progress (hides the bar while
  /// the user waits for the shutter so the spinner is unobstructed).
  final bool isCapturing;

  const PumpLiveFeedbackBar({
    super.key,
    required this.isOverGlared,
    this.isPortrait = false,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCapturing) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    final String text;
    final Color bg;
    final Color textColor;
    final IconData icon;
    if (isPortrait) {
      // Highest priority — block capture until the phone is sideways.
      text = l10n?.pumpCameraRotateToLandscape ??
          'Turn your phone sideways — the pump display is wide, so the '
              'numbers come out larger and upright';
      bg = Colors.redAccent.withValues(alpha: 0.92);
      textColor = Colors.white;
      icon = Icons.screen_rotation_outlined;
    } else if (isOverGlared) {
      text = l10n?.pumpCameraGlareWarning ??
          'Too much glare — tilt slightly to avoid reflections';
      bg = Colors.amber.withValues(alpha: 0.88);
      textColor = Colors.black87;
      icon = Icons.wb_sunny_outlined;
    } else {
      text = l10n?.pumpCameraAlignHint ??
          'Line up the display inside the frame, then capture';
      bg = Colors.black.withValues(alpha: 0.55);
      textColor = Colors.white;
      icon = Icons.center_focus_weak;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey('$isPortrait-$isOverGlared'),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classifies a sampled mean luminance value (0–255) against the
/// [GlarePolicy.standard] threshold so the camera screen can update
/// [PumpLiveFeedbackBar] cheaply without decoding a full frame.
///
/// A pixel is "bright" when its luminance ≥ 240 (near-white).  The
/// ROI is over-glared when the fraction of such pixels exceeds
/// [GlarePolicy.rejectAbove].  This cheap integer approximation matches
/// the preprocessor's [OcrImagePreprocessor.glareFraction] logic closely
/// enough for real-time guidance; the full check still runs on the
/// captured JPEG before OCR.
bool isRoiOverGlaredFromBytes(List<int> grayBytes) {
  if (grayBytes.isEmpty) return false;
  var bright = 0;
  for (final b in grayBytes) {
    if (b >= 240) bright++;
  }
  return (bright / grayBytes.length) > GlarePolicy.standard.rejectAbove;
}
