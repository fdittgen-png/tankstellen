// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/price_band_colors.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact price legend describing the map markers' cheap-to-expensive
/// colour ramp.
///
/// #2492 — the swatches and the gradient bar are driven by the ONE
/// canonical [PriceBandColors.ramp] that [StationMarkerBuilder] also
/// consumes, so the legend always matches what the markers paint. All
/// three tiers `priceTierOf` classifies are shown: cheap, the middle
/// "average" swatch, and expensive.
class PriceLegend extends StatelessWidget {
  const PriceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final overlayBg = DarkModeColors.mapOverlay(context);
    final shadowColor = DarkModeColors.mapOverlayShadow(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: overlayBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 4)],
      ),
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconForPriceTier(PriceTier.cheap),
                size: 12,
                color: DarkModeColors.success(context),
              ),
              _swatch(PriceBandColors.cheapTier),
              const SizedBox(width: 4),
              Text(l10n.cheap, style: const TextStyle(fontSize: 10)),
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  // The full 4-stop ramp the markers use, not a 3-stop
                  // approximation, so the bar matches the bubbles exactly.
                  gradient: LinearGradient(colors: PriceBandColors.ramp),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              // Middle "average" tier swatch + neutral dash icon (language-
              // neutral, so no new string) — mirrors PriceTier.average.
              _swatch(PriceBandColors.averageTier),
              Icon(
                iconForPriceTier(PriceTier.average),
                size: 12,
                color: DarkModeColors.warning(context),
              ),
              const SizedBox(width: 8),
              Text(l10n.expensive, style: const TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              _swatch(PriceBandColors.expensiveTier),
              Icon(
                iconForPriceTier(PriceTier.expensive),
                size: 12,
                color: DarkModeColors.error(context),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A 12dp colour dot for one price-band stop.
  static Widget _swatch(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DarkModeColors.mapOverlay(context),
            borderRadius: BorderRadius.circular(8),
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
