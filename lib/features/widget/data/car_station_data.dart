// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:ui' show Color;

import '../../../core/country/country_config.dart';
import '../../../core/theme/price_band_colors.dart';
import '../../../core/utils/price_tier.dart';
import '../../../core/utils/station_extensions.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';

/// Android Auto v1 — pure serializer for the car Search / Radar station lists.
///
/// v1 reuses the existing home-widget SharedPreferences pipeline rather than a
/// headless FlutterEngine (that live bridge is deferred to the v2 rewrite,
/// #2947). The Flutter app writes the latest search result list under
/// `car_search_json` and the latest radar result list under `car_radar_json`
/// into the same `HomeWidgetPreferences` file the home-widget reads, and the
/// native `SearchScreen` / `RadarScreen` (`androidx.car.app`
/// `PlaceListMapTemplate`) read those keys back to render a list + map.
///
/// Keeping the encoding in a standalone class (no Flutter or platform-channel
/// dependency) lets a pure Dart test prove the JSON contract the Kotlin side
/// depends on: `id`, `name`/`brand`, `lat`, `lng`, the formatted selected-fuel
/// price, a cheap→expensive band + color, distance, and the language-neutral
/// fuel label.
///
/// Each entry shape (consumed by the Kotlin car screens):
/// ```json
/// {
///   "id": "abc",
///   "name": "Aral Hauptstr. 1",
///   "brand": "Aral",
///   "lat": 52.5, "lng": 13.4,
///   "price": 1.799,            // double?  — null when the fuel is unpriced
///   "priceText": "1.799",      // formatted (3 dp) or "" when unpriced
///   "fuelLabel": "E10",        // language-neutral pump code
///   "band": "cheap",           // cheap|aboveAverage|expensive|unknown
///   "bandColor": 4282621761,   // 0xAARRGGBB int — cheap→expensive ramp colour
///   "distanceKm": 1.2,
///   "currency": "€"
/// }
/// ```
class CarStationData {
  CarStationData._();

  /// SharedPreferences key holding the latest in-app search result list.
  // i18n-ignore: SharedPreferences key, not user-facing text.
  static const String searchKey = 'car_search_json';

  /// SharedPreferences key holding the latest in-app radar result list.
  // i18n-ignore: SharedPreferences key, not user-facing text.
  static const String radarKey = 'car_radar_json';

  /// Max stations encoded for the car list. The Android Auto host caps a
  /// `PlaceListMapTemplate` item list, and a driver should only ever see a
  /// short, scan-at-a-glance list — keep it tight.
  static const int maxStations = 12;

  /// Serialize [stations] to the car JSON contract, colouring each entry on
  /// the shared cheap→expensive [PriceBandColors] ramp relative to the
  /// min/max of the selected-fuel price across the rendered set.
  ///
  /// [fuel] is the user's selected fuel — its price drives the band/colour and
  /// its language-neutral [shortFuelLabel] is attached for the row subtitle.
  /// Stations are taken in caller order (already distance-sorted by the search
  /// / radar paths), capped at [maxStations].
  static String encode(List<Station> stations, FuelType fuel) {
    final capped = stations.take(maxStations).toList(growable: false);

    // Min/max of the selected-fuel price across the rendered set, so the
    // cheap→expensive ramp is relative to what the driver actually sees —
    // identical normalization to the map markers (priceTierOf / gradient).
    double? minPrice;
    double? maxPrice;
    for (final s in capped) {
      final p = s.priceFor(fuel);
      if (p == null) continue;
      minPrice = (minPrice == null || p < minPrice) ? p : minPrice;
      maxPrice = (maxPrice == null || p > maxPrice) ? p : maxPrice;
    }

    final rows = capped
        .map((s) => _row(s, fuel, minPrice ?? 0, maxPrice ?? 0))
        .toList(growable: false);
    return jsonEncode(rows);
  }

  static Map<String, dynamic> _row(
    Station station,
    FuelType fuel,
    double minPrice,
    double maxPrice,
  ) {
    final price = station.priceFor(fuel);
    final tier = priceTierOf(price, minPrice, maxPrice);
    final currency = Countries.countryForStation(
          id: station.id,
          lat: station.lat,
          lng: station.lng,
        )?.currencySymbol ??
        '';

    return <String, dynamic>{
      'id': station.id,
      'name': station.displayName,
      'brand': station.brand,
      'lat': station.lat,
      'lng': station.lng,
      'price': price,
      'priceText': price != null ? price.toStringAsFixed(3) : '',
      'fuelLabel': shortFuelLabel(fuel),
      'band': _bandName(tier),
      // 0xAARRGGBB int the Kotlin side reads directly into a CarColor.
      'bandColor': _bandColor(tier),
      'distanceKm': double.parse(station.dist.toStringAsFixed(1)),
      'currency': currency,
    };
  }

  /// Stable band name the Kotlin side maps to a `CarColor`. Mirrors the
  /// [PriceTier] enum: the middle tier reports `aboveAverage` (the orange
  /// ramp stop the markers paint for the 33–66 % band).
  static String _bandName(PriceTier tier) => switch (tier) {
        PriceTier.cheap => 'cheap',
        PriceTier.average => 'aboveAverage',
        PriceTier.expensive => 'expensive',
        PriceTier.unknown => 'unknown',
      };

  /// The cheap→expensive ramp colour for [tier] as an `0xAARRGGBB` int,
  /// reusing the canonical [PriceBandColors] ramp shared with the map
  /// markers and legend (#2492).
  static int _bandColor(PriceTier tier) => switch (tier) {
        PriceTier.cheap => _argb(PriceBandColors.cheap),
        PriceTier.average => _argb(PriceBandColors.aboveAverage),
        PriceTier.expensive => _argb(PriceBandColors.expensive),
        // No price → neutral grey the renderer shows as a plain marker.
        PriceTier.unknown => 0xFF9E9E9E,
      };

  static int _argb(Color color) {
    int channel(double v) => (v * 255.0).round() & 0xff;
    return (channel(color.a) << 24) |
        (channel(color.r) << 16) |
        (channel(color.g) << 8) |
        channel(color.b);
  }
}
