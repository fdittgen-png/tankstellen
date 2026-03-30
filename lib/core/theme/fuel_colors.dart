import 'package:flutter/material.dart';
import '../../features/search/domain/entities/fuel_type.dart';

/// Distinct colors for each fuel type, for use in charts, badges, and map markers.
class FuelColors {
  FuelColors._();

  static Color forType(FuelType type) => switch (type) {
    FuelType.e5     => const Color(0xFF4CAF50),  // Green
    FuelType.e10    => const Color(0xFF2196F3),  // Blue
    FuelType.e98    => const Color(0xFF9C27B0),  // Purple
    FuelType.diesel => const Color(0xFFFF9800),  // Orange
    FuelType.dieselPremium => const Color(0xFFFF5722), // Deep Orange
    FuelType.e85    => const Color(0xFF8BC34A),  // Light Green
    FuelType.lpg    => const Color(0xFF00BCD4),  // Cyan
    FuelType.cng    => const Color(0xFF607D8B),  // Blue Grey
    FuelType.hydrogen => const Color(0xFF03A9F4), // Light Blue
    FuelType.electric => const Color(0xFF009688), // Teal
    FuelType.all    => const Color(0xFF757575),  // Grey
  };

  /// Lighter variant for backgrounds/fills
  static Color forTypeLight(FuelType type) => forType(type).withValues(alpha: 0.15);
}
