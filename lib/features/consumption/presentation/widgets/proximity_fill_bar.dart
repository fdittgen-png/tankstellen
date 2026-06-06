// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/radar_closeness.dart';
import '../../../../l10n/app_localizations.dart';

/// Corporate-green, battery-style proximity FILL BAR for the Fuel Station
/// Radar card + PiP price layouts (#2661).
///
/// The fill encodes how close the driver is to the radar station against an
/// ABSOLUTE, fixed scale ([radiusMeters]) — fuller = closer (#2984):
///
/// ```
/// fill = clamp(1 - distanceMeters / radiusMeters, 0, 1)
/// ```
///
/// 100% (full) at the station, 0% (empty) at / beyond the radar radius edge.
/// The fill grows as the driver nears — a glanceable "battery charging"
/// metaphor — and animates over ~300 ms so the change is visible rather than
/// snapping. The fill is a green→blue-violet gradient
/// ([DarkModeColors.brandGreen] → [DarkModeColors.proximityAccent], #2808) so
/// it reads as two colours with its leading edge in the accent hue — kept
/// consistent even when the host tile wears a fuel hue, so the proximity
/// signal always reads as "getting close".
///
/// Paint-only: distance + radius come in as params (the PiP is paint-only and
/// the card threads them from `activeProfileProvider`). When [radiusMeters]
/// is null or non-positive the bar collapses to a zero-size box so callers
/// can render it unconditionally.
class ProximityFillBar extends StatelessWidget {
  /// Distance from the driver to the radar station, in metres.
  final double distanceMeters;

  /// The ABSOLUTE scale in metres the fill divides against — fixed per surface,
  /// never derived from the result set (#2984). The trip card + PiP pass the
  /// approach radius (`profile.approachRadiusKm * 1000`); the search list passes
  /// `min(searchRadius, kRadarClosenessScaleCapMeters)`. The fill hits 0% here
  /// and 100% at the station.
  final double? radiusMeters;

  /// Bar height — thinner in the dense PiP price column, taller on the card.
  final double height;

  /// Colour the fill / track wins its contrast against — defaults to the
  /// ambient `onSurface`. On a fuel-hued PiP tile the caller passes the tile
  /// foreground so the track reads on the coloured background.
  final Color? onColor;

  const ProximityFillBar({
    super.key,
    required this.distanceMeters,
    required this.radiusMeters,
    this.height = 6,
    this.onColor,
  });

  /// The clamped fill fraction (0..1). 1 at the station, 0 at/beyond radius.
  ///
  /// Delegates to [RadarCloseness.fillFor] — the single source of truth shared
  /// by all three radar surfaces (list card, PiP, trip card) so they can never
  /// desync (#2956). Kept as a static here for the existing call sites/tests.
  static double fillFor(double distanceMeters, double radiusMeters) =>
      RadarCloseness.fillFor(distanceMeters, radiusMeters);

  @override
  Widget build(BuildContext context) {
    final radius = radiusMeters;
    if (radius == null || radius <= 0) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final fill = fillFor(distanceMeters, radius);
    final green = DarkModeColors.brandGreen(context);
    final accent = DarkModeColors.proximityAccent(context);
    final track = (onColor ?? Theme.of(context).colorScheme.onSurface)
        .withValues(alpha: 0.2);
    final percent = (fill * 100).round();

    return Semantics(
      label: l?.fuelStationRadarProximity(percent) ?? 'Proximity $percent%',
      value: '$percent%',
      child: ClipRRect(
        borderRadius: AppRadius.sm,
        child: Container(
          height: height,
          color: track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fill),
            // #2972 — reduced-motion guard: snap the fill to its end-state
            // with a zero-duration "animation" instead of the 300 ms ease,
            // so a motion-sensitive user gets the same fill with no movement.
            duration: AppMotion.enabled(context)
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            curve: Curves.easeOut,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [green, accent]),
                  borderRadius: AppRadius.sm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
