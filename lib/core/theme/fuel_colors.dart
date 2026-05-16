import 'package:flutter/material.dart';
import '../../features/search/domain/entities/fuel_type.dart';

/// Distinct colors for each fuel type, for use in charts, badges, and
/// map markers.
///
/// Muted, deep tones (#1757) — each fuel keeps its own hue so charts and
/// price columns stay distinguishable, but the palette is desaturated
/// well below the old electric Material-500 colours so it sits calmly
/// next to the forest-green theme. Every tone stays dark enough to read
/// as bold price text on a light card (WCAG AA-large).
class FuelColors {
  FuelColors._();

  static Color forType(FuelType type) => switch (type) {
    FuelTypeE5()     => const Color(0xFF4F7C44),  // Muted green
    FuelTypeE10()    => const Color(0xFF3B6FA0),  // Muted slate-blue
    FuelTypeE98()    => const Color(0xFF7B4E86),  // Muted plum
    FuelTypeDiesel() => const Color(0xFFBE7C1E),  // Muted ochre
    FuelTypeDieselPremium() => const Color(0xFFB5573B), // Muted terracotta
    FuelTypeE85()    => const Color(0xFF73904A),  // Muted olive
    FuelTypeLpg()    => const Color(0xFF3C8794),  // Muted teal-cyan
    FuelTypeCng()    => const Color(0xFF5C7079),  // Muted blue-grey
    FuelTypeHydrogen() => const Color(0xFF4589AC), // Muted sky-blue
    FuelTypeElectric() => const Color(0xFF3B8079), // Muted teal
    FuelTypeAll()    => const Color(0xFF6F6F6F),  // Neutral grey
  };

  /// Lighter variant for backgrounds/fills
  static Color forTypeLight(FuelType type) => forType(type).withValues(alpha: 0.15);
}
