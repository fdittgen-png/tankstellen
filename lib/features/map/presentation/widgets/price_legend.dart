// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/price_band_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// The map's price legend — one line, one encoding (#3949, Epic #3947):
///
/// ```
/// cheap  ●━━━━━━━━●  expensive
/// ```
///
/// The bar IS the legend: it draws the canonical [PriceBandColors.ramp]
/// the markers paint with (#2492), so its two rounded ends are the cheap
/// and expensive colours themselves and the two words name them. Nothing
/// else — the pre-#3949 legend repeated the same information three ways
/// (three swatch dots, three tier arrows and the bar), so a glance found
/// nine symbols for one idea. The colour-blind reading of the ramp, the
/// ↓ – ↑ tier arrow, stays where it does its job: on each marker and on
/// each results card, beside the number it qualifies.
class PriceLegend extends StatelessWidget {
  const PriceLegend({super.key});

  /// Width of the gradient bar between the two labels.
  static const double barWidth = 56;

  @override
  Widget build(BuildContext context) {
    final overlayBg = DarkModeColors.mapOverlay(context);
    final shadowColor = DarkModeColors.mapOverlayShadow(context);
    final l10n = AppLocalizations.of(context);
    final labelStyle = AppText.label(context).copyWith(
      color: DarkModeColors.mapOverlayIcon(context),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md + Spacing.xs,
        vertical: Spacing.sm + Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: overlayBg,
        borderRadius: AppRadius.md,
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              l10n.cheap,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: barWidth,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
            decoration: BoxDecoration(
              // The full 4-stop ramp the markers use, not a 3-stop
              // approximation, so the bar matches the bubbles exactly.
              gradient: const LinearGradient(colors: PriceBandColors.ramp),
              borderRadius: AppRadius.sm,
            ),
          ),
          Flexible(
            child: Text(
              l10n.expensive,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular zoom/location control button for the map.
class ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const ZoomButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.md,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DarkModeColors.mapOverlay(context),
            borderRadius: AppRadius.md,
          ),
          child: Icon(
            icon,
            size: 20,
            color: DarkModeColors.mapOverlayIcon(context),
          ),
        ),
      ),
    );
  }
}
