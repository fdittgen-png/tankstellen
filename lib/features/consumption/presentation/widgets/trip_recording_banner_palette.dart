// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/contrast_utils.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/cold_start_baselines.dart';
import '../../providers/trip_recording_phase.dart';

/// Background + foreground colour pair for the trip-recording PiP tile.
///
/// Extracted from `trip_recording_banner.dart` (#2382) to keep that file
/// under the 400-line cap (#1680); the palette resolution is a distinct,
/// context-free concern.
class BannerPalette {
  final Color background;
  final Color foreground;
  const BannerPalette({required this.background, required this.foreground});
}

/// Fuel-type-coloured palette for the approach overlay (#2382). The
/// background is [FuelColors.forType]; the foreground is whichever of
/// black / white wins the WCAG contrast against it, so the huge price
/// figure stays legible on every fuel hue (each tone is muted/dark, so
/// white wins in practice, but the check keeps the choice principled).
BannerPalette approachOverlayPalette(FuelType fuelType) {
  final background = FuelColors.forType(fuelType);
  final onWhite = ContrastUtils.contrastRatio(Colors.white, background);
  final onBlack = ContrastUtils.contrastRatio(Colors.black, background);
  return BannerPalette(
    background: background,
    foreground: onWhite >= onBlack ? Colors.white : Colors.black,
  );
}

/// Driving-band palette for the PiP tile. Paused always wins — the UI
/// should reflect "not recording" over any stale consumption signal.
BannerPalette bandPalette(
  BuildContext context,
  ConsumptionBand band,
  TripRecordingPhase phase,
) {
  if (phase == TripRecordingPhase.paused) {
    return BannerPalette(
      background: Theme.of(context).colorScheme.surfaceContainerHighest,
      foreground: Theme.of(context).colorScheme.onSurface,
    );
  }
  switch (band) {
    case ConsumptionBand.eco:
      return BannerPalette(
          background: DarkModeColors.success(context),
          foreground: Colors.white);
    case ConsumptionBand.normal:
      return BannerPalette(
        background: Theme.of(context).colorScheme.primary,
        foreground: Theme.of(context).colorScheme.onPrimary,
      );
    case ConsumptionBand.heavy:
      return BannerPalette(
          background: DarkModeColors.warning(context),
          foreground: Colors.black);
    case ConsumptionBand.veryHeavy:
      return BannerPalette(
          background: DarkModeColors.error(context),
          foreground: Colors.white);
    case ConsumptionBand.transient:
      return BannerPalette(
          background: Colors.teal.shade400, foreground: Colors.white);
  }
}
