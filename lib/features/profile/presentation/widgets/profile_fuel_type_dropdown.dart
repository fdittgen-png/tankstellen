import 'package:flutter/material.dart';

import '../../../../core/widgets/fuel_type_dropdown.dart';
import '../../../../features/search/domain/entities/fuel_type.dart';

/// Thin wrapper preserved for widget-test compatibility. All real rendering
/// now lives in [FuelTypeDropdown] so every surface (profile, vehicle,
/// fill-up) shares the same labels (#713).
class ProfileFuelTypeDropdown extends StatelessWidget {
  final FuelType value;
  final ValueChanged<FuelType> onChanged;

  const ProfileFuelTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) =>
      FuelTypeDropdown(value: value, onChanged: onChanged);
}
