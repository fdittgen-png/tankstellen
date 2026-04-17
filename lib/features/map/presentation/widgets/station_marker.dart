import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Compact marker dimensions — small enough to fit dozens on screen
/// while keeping the price legible.
const double kStationMarkerWidth = 50;
const double kStationMarkerHeight = 24;

/// Maximum characters for the brand label before truncation (used in
/// the tap-to-reveal tooltip).
const _maxBrandLength = 14;

/// Utility class for building station markers on the map.
class StationMarkerBuilder {
  StationMarkerBuilder._();

  /// Build a compact [Marker] for a station, colored by relative price.
  ///
  /// The marker shows only the price in bold inside a color-coded rounded
  /// badge (green = cheap, orange = mid, red = expensive). Tapping opens
  /// the station detail page; long-press reveals the brand name as a
  /// tooltip.
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
    final price = priceForFuelType(station, fuel);
    final baseColor = priceColor(price, minPrice, maxPrice);
    final color = pastel ? _toPastel(baseColor) : baseColor;
    final brand = _truncateBrand(station.displayName);

    // Accessibility (#566): TalkBack/VoiceOver read this as "Brand, price
    // EUR per litre, double-tap to view details" — otherwise the marker is
    // an opaque gesture target with no announced role or content.
    final priceLabel = price != null
        ? PriceFormatter.formatPrice(price)
        : 'price unavailable';
    final semanticLabel = '$brand, $priceLabel';

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: kStationMarkerWidth,
      height: kStationMarkerHeight,
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
              child: Text(
                price != null
                    ? PriceFormatter.formatPriceCompact(price)
                    : '--',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.0,
                  color: pastel ? Colors.black38 : Colors.black87,
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
  static Color priceColor(double? price, double minPrice, double maxPrice) {
    if (price == null) return Colors.grey;
    if (maxPrice <= minPrice) return Colors.green;
    final t = ((price - minPrice) / (maxPrice - minPrice)).clamp(0.0, 1.0);
    if (t < 0.33) {
      return Color.lerp(Colors.green, Colors.yellow, t / 0.33)!;
    } else if (t < 0.66) {
      return Color.lerp(Colors.yellow, Colors.orange, (t - 0.33) / 0.33)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (t - 0.66) / 0.34)!;
    }
  }

  /// Convert a vivid color to a pastel/muted variant.
  static Color _toPastel(Color color) {
    // Blend with white at 60% to create pastel
    return Color.lerp(color, Colors.white, 0.6)!;
  }

  /// Truncate brand name if longer than [_maxBrandLength].
  static String _truncateBrand(String brand) {
    if (brand.length <= _maxBrandLength) return brand;
    return '${brand.substring(0, _maxBrandLength - 1)}\u2026';
  }
}
