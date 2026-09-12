// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/price_band_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_gradient.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import 'driving_marker_card.dart';
import 'station_map_sheet.dart';

/// Compact marker dimensions — small enough to fit dozens on screen
/// while keeping the price legible.
const double kStationMarkerWidth = 50;
const double kStationMarkerHeight = 24;

/// Big, driver-legible marker dimensions for the DRIVING-mode map (#3002,
/// Epic #2997). Driving shows few stations and is read at a glance from the
/// driver's seat, so its variant is a large card carrying the brand + a
/// price-tier icon + a LARGE price — not the small price-only pill.
const double kDrivingMarkerWidth = 150;
const double kDrivingMarkerHeight = 62;

/// How a station marker is RENDERED. The default [pill] is the small
/// price-only badge (brand in a tooltip) shared by the nearby / radar / route
/// maps. [driving] is the big driver-legible card (brand + tier icon + large
/// price) — a real CONTENT variant, not a size scale — for the driving map,
/// which adopts the shared [PriceBandColors.ramp] colours but keeps glanceable
/// markers (#3002, Epic #2997).
enum StationMarkerVariant { pill, driving }

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
  ///
  /// #2631 — on a cross-border route the caller may pass [fuelResolver],
  /// which maps a station to the fuel of ITS country's profile (offline,
  /// from the station's lat/lng). The price is then taken for that
  /// resolved fuel so a Spanish station shows the E10 price an E85 driver
  /// would actually pay, instead of '--'. When [fuelResolver] is null the
  /// strict single-[fuel] behaviour (#2510) is unchanged — a station
  /// lacking that fuel still shows '--', never a within-country fallback.
  ///
  /// #2939 — the radar split map passes [onTap] to intercept the marker tap:
  /// instead of navigating to `/station/{id}`, it SELECTS the station's list
  /// row (`selectedStationProvider`) and keeps the map visible, so tapping a
  /// marker is the inverse of tapping a row. When [onTap] is null the marker
  /// keeps the default push-to-detail behaviour (the full-screen [MapScreen]
  /// and the route map). [selected] paints the pill with a brand-primary ring
  /// and forces the full price label (never a compact dot) so the chosen
  /// station's marker reads as emphasised even amid a dense pane.
  static Marker build(
    BuildContext context,
    Station station,
    FuelType fuel,
    double minPrice,
    double maxPrice, {
    bool pastel = false,
    bool compact = false,
    bool selected = false,
    VoidCallback? onTap,
    FuelType Function(Station)? fuelResolver,
    StationMarkerVariant variant = StationMarkerVariant.pill,
  }) {
    // #2510 — strict selected-fuel price, exactly like the list card. No
    // within-country fallback: a station lacking the selected fuel shows
    // "--", it must never be re-labelled with E10's price. #2631 — when a
    // cross-border resolver is supplied, the fuel is the station's OWN
    // country profile fuel; the resolution stays strict for that fuel.
    final price = station.priceFor(fuelResolver != null ? fuelResolver(station) : fuel);
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

    // #3002 (Epic #2997) — the DRIVING map renders a big driver-legible card
    // (brand + price-tier icon + large price) coloured by the SAME shared
    // [PriceBandColors.ramp] as every other map, instead of the small
    // price-only pill. It folds the old bespoke `DrivingMarkerBuilder` +
    // `_drivingStops` palette onto the one canonical ramp.
    if (variant == StationMarkerVariant.driving) {
      return DrivingMarkerCard.build(
        context,
        station,
        price,
        minPrice,
        maxPrice,
        color,
        semanticLabel,
        priceText,
        selected: selected,
        onTap: onTap,
      );
    }

    // #2939 — a selected station is ALWAYS the full pill (never a compact
    // dot) and rings in brand-primary so a list-row tap visibly emphasises
    // its marker even in a dense pane. The ring colour is resolved in a
    // [Builder] at paint time, never eagerly here: [StationMapLayers] builds
    // the markers in `initState`/`didUpdateWidget`, where `Theme.of(context)`
    // is illegal (the dependency must be registered in `build`).
    final bool showCompact = compact && !selected;
    final Widget badge = showCompact
        ? Builder(builder: (ctx) => _dot(ctx, color, pastel))
        : selected
            // #2973 — the SELECTED marker (and ONLY the selected marker) wraps
            // its price in AnimatedPriceText so a refresh that drops the
            // chosen station's price flashes on the map. Un-selected bubbles,
            // compact dots and the cluster badge stay inert — the flash never
            // runs per-frame across the whole marker layer. Reduced motion is
            // honoured inside AnimatedPriceText.
            ? Builder(
                builder: (ctx) => _priceBubble(ctx, color, pastel, priceText,
                    ringColor: Theme.of(ctx).colorScheme.primary,
                    flashPrice: price),
              )
            // #4093 — a Builder on the un-selected path too: the card's
            // surface and hairline are theme colours, and the markers are
            // built in initState/didUpdateWidget where Theme.of is
            // illegal. Resolving at paint time is the established pattern
            // here (see the selected case above).
            : Builder(
                builder: (ctx) => _priceBubble(ctx, color, pastel, priceText),
              );

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: showCompact ? kStationDotSize : kStationMarkerWidth,
      height: showCompact ? kStationDotSize : kStationMarkerHeight,
      // #1772 — isolate each marker's raster so an animation or rebuild
      // on one marker (e.g. the selected-station pastel swap) does not
      // repaint the entire marker layer.
      child: RepaintBoundary(
        child: Semantics(
          label: semanticLabel,
          button: true,
          selected: selected,
          child: GestureDetector(
            // #2939 — [onTap] lets the radar split map select the row
            // instead of opening anything.
            // #4093 — the default is no longer a push to the detail
            // screen. The map's question is "where are the good options";
            // a marker tap asks "what about that one", and answering it
            // by REPLACING the map throws away the context that made the
            // question worth asking. The sheet answers over the map, and
            // carries its own way on to the detail screen.
            onTap: onTap ??
                () => unawaited(StationMapSheet.show(
                      context,
                      station: station,
                      fuelType: fuelResolver != null
                          ? fuelResolver(station)
                          : fuel,
                    )),
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

  static Widget _priceBubble(
    BuildContext context,
    Color accent,
    bool pastel,
    String priceText, {
    Color? ringColor,
    double? flashPrice,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final Widget priceLabel = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        priceText,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          height: 1.0,
          // De-emphasized markers dim the NUMBER, not the card: a pastel
          // wash over the whole marker made the price unreadable.
          color: pastel
              ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
              : scheme.onSurface,
        ),
      ),
    );
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: pastel ? 0.75 : 0.96),
        borderRadius: BorderRadius.circular(6),
        border: ringColor != null
            ? Border.all(color: ringColor, width: 2)
            : Border.all(color: scheme.outlineVariant, width: 1),
        // One soft shadow so the card lifts off the tiles; the old marker
        // needed a hard black one to survive its own saturated fill.
        boxShadow: pastel
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The semantic accent: where this price sits on the ramp, as a
          // modifier on the number rather than a wash over it.
          Container(
            key: const Key('station_marker_accent'),
            width: 3,
            height: kStationMarkerHeight,
            color: accent.withValues(alpha: pastel ? 0.45 : 1),
          ),
          // Expanded, not bare: a FittedBox in a Row is handed unbounded
          // width, so it never scales down and the marker overflows its
          // fixed 50 dp instead.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: flashPrice == null
                  ? priceLabel
                  : AnimatedPriceText(price: flashPrice, child: priceLabel),
            ),
          ),
        ],
      ),
    );
  }

  /// A small dot for a de-emphasized (lower-ranked) station — keeps it
  /// visible and tappable without a label that would overlap its
  /// neighbours (#2510).
  ///
  /// #4093 — the dot IS its accent: with no price to carry there is
  /// nothing for a neutral card to hold, so the band colour is the fill
  /// and a hairline surface ring separates it from the tiles.
  static Widget _dot(BuildContext context, Color color, bool pastel) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: pastel ? 0.45 : 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.surface.withValues(alpha: pastel ? 0.6 : 0.9),
          width: 1.5,
        ),
      ),
    );
  }

  /// Green (cheapest) -> Amber -> Orange -> Red (most expensive).
  /// #2196 — thin wrapper over the shared [priceGradientColor].
  /// #2492 — the stops now come from the ONE canonical
  /// [PriceBandColors.ramp]. #4093 — the legend that used to describe it
  /// is gone: the marker shows the price itself, so the ramp is a
  /// modifier on a number rather than the only carrier of it. The old pure
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
