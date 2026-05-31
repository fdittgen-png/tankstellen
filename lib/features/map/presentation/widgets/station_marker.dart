// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/price_band_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_gradient.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Compact marker dimensions — small enough to fit dozens on screen
/// while keeping the price legible.
const double kStationMarkerWidth = 50;
const double kStationMarkerHeight = 24;

/// A small price-less dot used for lower-ranked stations so a bounded
/// nearby-search result set stays fully visible (#2510) without the full
/// price bubbles overlapping into an illegible pile. The top-ranked
/// stations (cheapest / closest per the active sort) keep the full price
/// label; the rest render as these dots — still tappable, still coloured
/// by their price band, never hidden behind a count cluster.
const double kStationDotSize = 14;

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
  /// #2510 — the displayed price is STRICTLY the user's selected [fuel]
  /// price (`station.priceFor(fuel)`), mirroring the search LIST card
  /// (`StationCard._displayPrice`). A station that has no price for the
  /// selected fuel renders the language-neutral `'--'` placeholder — it
  /// no longer silently falls back to E10 / another fuel, which made the
  /// map read "E10 2,099" on an E85 search while the list showed the E85
  /// price (reverting the #2400 fallback chain that caused the divergence).
  /// The price-band colour is computed from that same selected-fuel price.
  ///
  /// When [pastel] is true, the marker uses muted/pastel colors for
  /// non-selected stations so that selected ones stand out.
  ///
  /// When [compact] is true, the marker renders as a small coloured dot
  /// (no price text) — used for lower-ranked stations so a bounded result
  /// set stays fully visible without the full bubbles overlapping (#2510).
  static Marker build(
    BuildContext context,
    Station station,
    FuelType fuel,
    double minPrice,
    double maxPrice, {
    bool pastel = false,
    bool compact = false,
  }) {
    // #2510 — strict selected-fuel price, exactly like the list card. No
    // fallback to another fuel: a station lacking the selected fuel shows
    // "--", it must never be re-labelled with E10's price.
    final price = station.priceFor(fuel);
    final baseColor = priceColor(price, minPrice, maxPrice);
    final color = pastel ? _toPastel(baseColor) : baseColor;
    final brand = truncateBrand(station.displayName, maxLength: _maxBrandLength);

    // Accessibility (#566): TalkBack/VoiceOver read this as "Brand, price
    // EUR per litre, double-tap to view details" — otherwise the marker is
    // an opaque gesture target with no announced role or content.
    final priceLabel =
        price != null ? PriceFormatter.formatPrice(price) : 'price unavailable';
    final semanticLabel = '$brand, $priceLabel';

    final priceText = price != null
        ? PriceFormatter.formatPriceCompact(price)
        : '--'; // i18n-ignore: language-neutral no-price placeholder

    final Widget badge = compact
        ? _dot(color, pastel)
        : _priceBubble(color, pastel, priceText);

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: compact ? kStationDotSize : kStationMarkerWidth,
      height: compact ? kStationDotSize : kStationMarkerHeight,
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
              child: badge,
            ),
          ),
        ),
      ),
    );
  }

  /// The full colour-coded price bubble shown for emphasized stations.
  static Widget _priceBubble(Color color, bool pastel, String priceText) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: pastel ? 0.5 : 0.92),
        borderRadius: BorderRadius.circular(6),
        border: pastel
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
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
        child: Text(
          priceText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            height: 1.0,
            color: pastel ? Colors.black38 : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// A small price-less dot for a de-emphasized (lower-ranked) station —
  /// keeps it visible + tappable without a label that would overlap its
  /// neighbours (#2510).
  static Widget _dot(Color color, bool pastel) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: pastel ? 0.5 : 0.92),
        shape: BoxShape.circle,
        border: pastel
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
        boxShadow: pastel
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
    );
  }

  /// Green (cheapest) -> Amber -> Orange -> Red (most expensive).
  /// #2196 — thin wrapper over the shared [priceGradientColor].
  /// #2492 — the stops now come from the ONE canonical
  /// [PriceBandColors.ramp], shared with [PriceLegend] so the legend
  /// describes exactly what the markers paint. The old pure
  /// `Colors.yellow` (`#FFEB00`) was near-invisible on the white-bordered
  /// bubbles; it is replaced by the ramp's saturated amber.
  static const _priceStops = PriceBandColors.ramp;

  static Color priceColor(double? price, double minPrice, double maxPrice) =>
      priceGradientColor(
        price,
        minPrice,
        maxPrice,
        stops: _priceStops,
        nullColor: Colors.grey,
        flatColor: PriceBandColors.cheap,
      );

  /// Convert a vivid color to a pastel/muted variant.
  static Color _toPastel(Color color) {
    // Blend with white at 60% to create pastel
    return Color.lerp(color, Colors.white, 0.6)!;
  }
}
