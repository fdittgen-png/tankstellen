// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import 'proximity_fill_bar.dart';

/// The huge-price PiP layout for the Fuel Station Radar (#2084 / #2601 /
/// #2661). Extracted from `trip_recording_pip_view.dart` so that file stays
/// under the 400-line cap once the radar/polling variant + proximity bar
/// landed.
///
/// Renders, top to bottom: the huge price for the driver's fuel type, the
/// fuel label, the station name (→ brand fallback), a distance caption, and
/// the corporate-green [ProximityFillBar]. The whole tile is tap-to-navigate
/// (`NavigationUtils.openInMaps`, #2601) and is scaled down uniformly by one
/// outer `FittedBox(scaleDown)` so the bottom line never clips the small 2:1
/// tile (#2620).
///
/// Two callers, identical visual, only the distance unit + radius differ:
///
/// - **in-radius** (`ApproachInRadius`/`ApproachLeaving`) → metres caption;
/// - **radar/polling** (the nearest priced candidate while still
///   approaching, #2661) → kilometres caption.
class TripRecordingPipPriceLayout extends StatelessWidget {
  final Station station;
  final FuelType fuel;
  final Color backgroundColor;
  final Color foregroundColor;

  /// Distance to the station in metres (drives the caption + the fill bar).
  /// Null hides the caption (the fill bar collapses too).
  final double? distanceMeters;

  /// When true the caption reads in kilometres (the radar/polling variant,
  /// #2661); when false it reads in metres (the in-radius variant, #2084).
  final bool kmCaption;

  /// Radar radius in metres (`profile.approachRadiusKm * 1000`) — the
  /// proximity fill bar's "indicated radius". Null collapses the bar.
  final double? radiusMeters;

  const TripRecordingPipPriceLayout({
    super.key,
    required this.station,
    required this.fuel,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.distanceMeters,
    required this.kmCaption,
    required this.radiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final price = station.priceFor(fuel);
    final priceText = price != null ? PriceFormatter.formatPrice(price) : '—';
    final fuelLabel = fuel.displayName;
    final distance = distanceMeters;

    final String? distanceText = distance == null
        ? null
        : kmCaption
            ? (l?.fuelStationRadarDistanceKm(
                    (distance / 1000.0).toStringAsFixed(1)) ??
                '${(distance / 1000.0).toStringAsFixed(1)} km')
            : (l?.approachStationDistance(distance.toStringAsFixed(0)) ??
                '${distance.toStringAsFixed(0)} m');

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          priceText,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
            fontSize: 56,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          fuelLabel,
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          station.name.isNotEmpty ? station.name : station.brand,
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (distanceText != null) ...[
          const SizedBox(height: 2),
          Text(
            distanceText,
            style: TextStyle(
              color: foregroundColor.withValues(alpha: 0.85),
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );

    // #2808 — the proximity bar is a full-bleed band at the BOTTOM of the
    // tile, OUTSIDE the scaleDown so it isn't shrunk to a hairline. It spans
    // the complete PiP width (`width: infinity`, bounded by the tile) and is
    // taller (10 pt) so the "getting close" signal is glanceable.
    final Widget? proximityBand = (distance != null && radiusMeters != null)
        ? SizedBox(
            width: double.infinity,
            child: ProximityFillBar(
              distanceMeters: distance,
              radiusMeters: radiusMeters,
              height: 10,
              onColor: foregroundColor,
            ),
          )
        : null;

    // #2601 — tap to navigate to the station in the user's maps app. #2620 —
    // one outer FittedBox(scaleDown) shrinks the price stack so it never
    // bleeds past the small 2:1 tile; the proximity band sits below it at the
    // tile's full width (#2808).
    return Tooltip(
      message: l?.navigate ?? 'Navigate',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => NavigationUtils.openInMaps(
          station.lat,
          station.lng,
          label: station.navLabel,
        ),
        child: Material(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: content),
                    ),
                  ),
                ),
                ?proximityBand,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
