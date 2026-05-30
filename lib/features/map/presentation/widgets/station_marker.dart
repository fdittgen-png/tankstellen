// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_gradient.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Compact marker dimensions — small enough to fit dozens on screen
/// while keeping the price legible.
const double kStationMarkerWidth = 50;
const double kStationMarkerHeight = 24;

/// Wider marker used when a fallback-fuel label is prepended (#2400) so
/// the short fuel code (`E10`, `Diesel`, …) plus the price both fit
/// without the [FittedBox] crushing the price too small to read.
const double kStationMarkerWideWidth = 74;

/// Maximum characters for the brand label before truncation (used in
/// the tap-to-reveal tooltip).
const _maxBrandLength = 14;

/// Utility class for building station markers on the map.
class StationMarkerBuilder {
  StationMarkerBuilder._();

  /// Build a compact [Marker] for a station, colored by relative price.
  ///
  /// The marker shows the price in bold inside a color-coded rounded
  /// badge (green = cheap, orange = mid, red = expensive). Tapping opens
  /// the station detail page; long-press reveals the brand name as a
  /// tooltip.
  ///
  /// #2400 — the displayed price comes from [bestDisplayPrice]: the
  /// selected [fuel] when present, otherwise the first available fallback
  /// fuel. When the shown fuel differs from [fuel] (e.g. a diesel-only
  /// station while the user has E10 selected), a small fuel-code dot +
  /// label is prepended so the price is never silently mislabelled —
  /// mirroring `AllPricesStationCard`. `'--'` now appears ONLY for a
  /// station with no usable price for any fuel.
  ///
  /// When [pastel] is true, the marker uses muted/pastel colors for
  /// non-selected stations so that selected ones stand out.
  static Marker build(
    BuildContext context,
    Station station,
    FuelType fuel,
    double minPrice,
    double maxPrice, {
    bool pastel = false,
  }) {
    final resolved = bestDisplayPrice(station, fuel);
    final price = resolved?.price;
    final isFallback = resolved != null && resolved.shownFuel != fuel;
    final baseColor = priceColor(price, minPrice, maxPrice);
    final color = pastel ? _toPastel(baseColor) : baseColor;
    final brand = truncateBrand(station.displayName, maxLength: _maxBrandLength);
    final fallbackLabel =
        isFallback ? shortFuelLabel(resolved.shownFuel) : '';

    // Accessibility (#566): TalkBack/VoiceOver read this as "Brand, price
    // EUR per litre, double-tap to view details" — otherwise the marker is
    // an opaque gesture target with no announced role or content. When a
    // fallback fuel is shown, the announced label names it so the price is
    // never ambiguous.
    final priceLabel = price != null
        ? (isFallback
            ? '$fallbackLabel ${PriceFormatter.formatPrice(price)}'
            : PriceFormatter.formatPrice(price))
        : 'price unavailable';
    final semanticLabel = '$brand, $priceLabel';

    final priceText = price != null
        ? PriceFormatter.formatPriceCompact(price)
        : '--'; // i18n-ignore: language-neutral no-price placeholder

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: isFallback ? kStationMarkerWideWidth : kStationMarkerWidth,
      height: kStationMarkerHeight,
      // #1772 — isolate each marker's raster so an animation or rebuild
      // on one marker (e.g. the selected-station pastel swap) does not
      // repaint the entire marker layer.
      child: RepaintBoundary(
        child: Semantics(
        label: semanticLabel,
        button: true,
        child: GestureDetector(
        onTap: () => GoRouter.of(context).push('/station/${station.id}'),
        child: Tooltip(
          message: brand,
          waitDuration: const Duration(milliseconds: 300),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: pastel ? 0.5 : 0.92),
              borderRadius: BorderRadius.circular(6),
              border: pastel
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1,
                    ),
              boxShadow: pastel
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fallback fuel dot + code (mirrors AllPricesStationCard)
                  // so a price for a fuel other than the selected one is
                  // never shown unlabelled.
                  if (isFallback) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pastel ? Colors.black26 : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      fallbackLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        height: 1.0,
                        color: pastel ? Colors.black38 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    priceText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.0,
                      color: pastel ? Colors.black38 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }

  /// Green (cheapest) -> Yellow -> Orange -> Red (most expensive).
  /// #2196 \u2014 thin wrapper over the shared [priceGradientColor]; kept
  /// public because tests assert its boundary colours directly.
  static const _priceStops = [
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
  ];

  static Color priceColor(double? price, double minPrice, double maxPrice) =>
      priceGradientColor(
        price,
        minPrice,
        maxPrice,
        stops: _priceStops,
        nullColor: Colors.grey,
        flatColor: Colors.green,
      );

  /// Convert a vivid color to a pastel/muted variant.
  static Color _toPastel(Color color) {
    // Blend with white at 60% to create pastel
    return Color.lerp(color, Colors.white, 0.6)!;
  }
}
