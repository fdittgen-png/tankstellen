// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/price_band_colors.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import 'station_marker.dart';

/// The big, driver-legible DRIVING-mode marker (#3002, Epic #2997).
///
/// A real CONTENT variant of the station marker, not a size scale: the
/// driving map shows few stations, read at a glance from the driver's
/// seat, so it carries the brand, a price-tier icon and a LARGE price on
/// a ramp-coloured card.
///
/// It deliberately keeps its saturated fill while #4093 turned the
/// ordinary pill neutral. The two are answering different questions: a
/// map of twenty options wants the price readable and the ranking
/// subordinate, while a driver at speed wants a shape they can classify
/// without reading at all. Quiet is right for comparison; loud is right
/// for a glance at 100 km/h.
///
/// Its own library since #4093 — `station_marker.dart` reached the
/// 400-line cap when the neutral card landed, and the driving variant is
/// the part of it that shares the least with the rest.
/// Maximum characters for the brand label on the driving card before it
/// is truncated. Wider than the tooltip cap on the ordinary pill because
/// this card paints the brand on a 150 dp-wide surface.
const _maxDrivingBrandLength = 16;

abstract final class DrivingMarkerCard {
  /// Build the card. #3002, Epic #2997: the brand
  /// on top (truncated), then a price-tier icon + a LARGE price, on a
  /// [PriceBandColors.ramp]-coloured pill with a white outline + drop shadow so
  /// it reads against the map tiles at a glance. Folds the old bespoke
  /// `DrivingMarkerBuilder` (its own `_drivingStops` palette) onto the ONE
  /// shared ramp every other map already uses.
  ///
  /// Keeps the same wrapping contract as the default marker — a
  /// [RepaintBoundary] (#1772) + a labelled [Semantics] button (#566) — and the
  /// driving caller's [onTap] (open the `DrivingStationSheet`); it never falls
  /// back to a GoRouter push (the driving map has no detail route).
  static Marker build(
    BuildContext context,
    Station station,
    double? price,
    double minPrice,
    double maxPrice,
    Color color,
    String semanticLabel,
    String priceText, {
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final brand =
        truncateBrand(station.displayName, maxLength: _maxDrivingBrandLength);
    final tier = priceTierOf(price, minPrice, maxPrice);

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: kDrivingMarkerWidth,
      height: kDrivingMarkerHeight,
      child: RepaintBoundary(
        child: Semantics(
          label: semanticLabel,
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: AppRadius.lg,
                // A selected driving card rings in brand-primary; otherwise the
                // high-contrast white outline keeps it legible over tiles.
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  width: selected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brand,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (tier != PriceTier.unknown)
                        Icon(
                          iconForPriceTier(tier),
                          size: 14,
                          color: Colors.black87,
                        ),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The price marker: a light, neutral card whose CONTENT is the price
  /// and whose only colour is a semantic accent bar (#4093, epic #4087).
  ///
  /// Before this the whole bubble was filled with the price-band colour,
  /// green through red. Twenty of those over a map read as an alarm
  /// state, the map's own colours had to fight through them, and the
  /// price — the number a driver is there for — was painted on a
  /// saturated ground it barely survived. The colour was also doing all
  /// the work: a user who cannot separate green from red got nothing
  /// from it at all.
  ///
  /// Now the band lives in a 3 dp bar down the leading edge, the card is
  /// `surface` with a hairline `outlineVariant`, and the price is
  /// `onSurface` at full contrast. The same information, in the order a
  /// reader needs it: the number first, its ranking as a modifier.
  ///
  /// #2939 — [ringColor] (the selected-station case) replaces the
  /// hairline with a thicker brand-primary ring so the chosen marker
  /// stands out from its neighbours.
  ///
  /// #2973 — [flashPrice] (selected case only) wraps the price text in an
  /// [AnimatedPriceText] so the chosen station's marker flashes when its
  /// price changes. Null on every non-selected bubble → no flash, so the
  /// animation can never run across the whole marker layer.
}
