// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_gradient.dart';
import '../../../../core/theme/price_band_colors.dart';

/// Builder for the "Clustered + cheapest-labelled" density-cluster badge
/// (#2939) shown by [MarkerClusterLayerWidget] on the radar / search split
/// map.
///
/// Each badge surfaces the CHEAPEST price among its member stations (the
/// figure a driver actually cares about) plus the member COUNT, coloured on
/// the shared cheap→expensive [PriceBandColors.ramp] so a cluster that
/// contains the bargain reads green and an all-expensive pocket reads red —
/// the same colour language as the singleton price pills and the legend.
///
/// Pulled into its own file so [StationMapLayers] stays under the 400-line
/// cap and the badge layout can be unit-tested in isolation.
class ClusterBadge {
  ClusterBadge._();

  /// Resolve the CHEAPEST price among a cluster's [markerPrices] (each the
  /// price the corresponding singleton marker would show, or null when that
  /// station has no price for the active fuel). Returns null when no member
  /// has a usable price — the badge then shows a neutral count-only chip.
  static double? cheapestOf(Iterable<double?> markerPrices) {
    double? cheapest;
    for (final p in markerPrices) {
      if (p == null || p <= 0) continue;
      if (cheapest == null || p < cheapest) cheapest = p;
    }
    return cheapest;
  }

  /// Build the badge widget for a cluster.
  ///
  /// [cheapest] is the cheapest member price (see [cheapestOf]); [count] is
  /// the number of members; [minPrice]/[maxPrice] are the overall result-set
  /// price range used to colour the badge on the ramp; [highlight] paints the
  /// badge with the brand-primary ring when the cluster contains the SELECTED
  /// station so a list-row tap visibly emphasises its (still-clustered) marker.
  static Widget build(
    BuildContext context, {
    required double? cheapest,
    required int count,
    required double minPrice,
    required double maxPrice,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final Color bandColor = priceGradientColor(
      cheapest,
      minPrice,
      maxPrice,
      stops: PriceBandColors.ramp,
      nullColor: theme.colorScheme.primaryContainer,
      flatColor: PriceBandColors.cheap,
    );
    final String priceText = cheapest != null
        ? PriceFormatter.formatPriceCompact(cheapest)
        : '--'; // i18n-ignore: language-neutral no-price placeholder

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bandColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary
              : Colors.white.withValues(alpha: 0.85),
          width: highlight ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                priceText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),
              Text(
                '×$count', // i18n-ignore: language-neutral count multiplier
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                  height: 1.1,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The on-screen pixel size of a [ClusterBadge]. flutter_map_marker_cluster
/// uses this for the badge bounds; chosen to comfortably hold a 3-decimal
/// price + the count multiplier without clipping.
const Size kClusterBadgeSize = Size(48, 38);
