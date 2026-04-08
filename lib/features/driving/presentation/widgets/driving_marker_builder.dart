import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Builds oversized station markers for driving mode.
///
/// Markers are 2x normal size with high-contrast colors and large price text.
/// Brand names are hidden — only brand logo + price are shown.
class DrivingMarkerBuilder {
  DrivingMarkerBuilder._();

  /// Build a large [Marker] for driving mode, colored by relative price.
  static Marker build(
    Station station,
    FuelType fuel,
    double minPrice,
    double maxPrice, {
    required VoidCallback onTap,
  }) {
    final price = station.priceFor(fuel);
    final color = _priceColor(price, minPrice, maxPrice);

    return Marker(
      point: LatLng(station.lat, station.lng),
      width: 120,
      height: 56,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
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
                price != null
                    ? PriceFormatter.formatPriceCompact(price)
                    : '--',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              Text(
                station.displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
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

  /// High-contrast price colors for driving mode.
  /// Bright green (cheapest) -> yellow -> red (most expensive).
  static Color _priceColor(double? price, double minPrice, double maxPrice) {
    if (price == null) return Colors.grey.shade400;
    if (maxPrice <= minPrice) return const Color(0xFF4CAF50);
    final t = ((price - minPrice) / (maxPrice - minPrice)).clamp(0.0, 1.0);
    if (t < 0.33) {
      return Color.lerp(
        const Color(0xFF4CAF50),
        const Color(0xFFFFEB3B),
        t / 0.33,
      )!;
    } else if (t < 0.66) {
      return Color.lerp(
        const Color(0xFFFFEB3B),
        const Color(0xFFFF9800),
        (t - 0.33) / 0.33,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFFF9800),
        const Color(0xFFF44336),
        (t - 0.66) / 0.34,
      )!;
    }
  }
}
