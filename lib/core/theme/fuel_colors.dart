import 'package:flutter/material.dart';
import '../../features/search/domain/entities/fuel_type.dart';

/// Distinct colors for each fuel type, for use in charts, badges, and map markers.
class FuelColors {
  FuelColors._();

  static Color forType(FuelType type) => switch (type) {
    FuelTypeE5()     => const Color(0xFF4CAF50),  // Green
    FuelTypeE10()    => const Color(0xFF2196F3),  // Blue
    FuelTypeE98()    => const Color(0xFF9C27B0),  // Purple
    FuelTypeDiesel() => const Color(0xFFFF9800),  // Orange
    FuelTypeDieselPremium() => const Color(0xFFFF5722), // Deep Orange
    FuelTypeE85()    => const Color(0xFF8BC34A),  // Light Green
    FuelTypeLpg()    => const Color(0xFF00BCD4),  // Cyan
    FuelTypeCng()    => const Color(0xFF607D8B),  // Blue Grey
    FuelTypeHydrogen() => const Color(0xFF03A9F4), // Light Blue
    FuelTypeElectric() => const Color(0xFF009688), // Teal
    FuelTypeAll()    => const Color(0xFF757575),  // Grey
  };

  /// Lighter variant for backgrounds/fills
  static Color forTypeLight(FuelType type) => forType(type).withValues(alpha: 0.15);
}
