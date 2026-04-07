import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/price_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Utility class for building station markers on the map.
class StationMarkerBuilder {
  StationMarkerBuilder._();

  /// Build a [Marker] for a station, colored by relative price.
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
    final brand = station.displayName;
    final tier = priceTierOf(price, minPrice, maxPrice);

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: 100,
      height: 44,
      child: GestureDetector(
        onTap: () => GoRouter.of(context).push('/station/${station.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: pastel ? 0.5 : 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: pastel
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tier != PriceTier.unknown)
                    Icon(
                      iconForPriceTier(tier),
                      size: 12,
                      color: pastel ? Colors.black38 : Colors.black87,
                    ),
                  Text(
                    price != null
                        ? PriceFormatter.formatPriceCompact(price)
                        : '--',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: pastel ? Colors.black38 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                brand,
                style: TextStyle(
                  fontSize: 9,
                  color: pastel ? Colors.black26 : Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
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
}
