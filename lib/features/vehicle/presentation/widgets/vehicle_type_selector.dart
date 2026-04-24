import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/vehicle_profile.dart';

/// Drivetrain toggle on the edit-vehicle form — a three-segment
/// [SegmentedButton] that flips the form between Combustion, Hybrid,
/// and Electric. Pure UI; owning state stays on the parent form.
class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;

  const VehicleTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedButton<VehicleType>(
      segments: [
        ButtonSegment(
          value: VehicleType.combustion,
          label: Text(l?.vehicleTypeCombustion ?? 'Combustion'),
          icon: const Icon(Icons.local_gas_station),
        ),
        ButtonSegment(
          value: VehicleType.hybrid,
          label: Text(l?.vehicleTypeHybrid ?? 'Hybrid'),
          icon: const Icon(Icons.directions_car_filled),
        ),
        ButtonSegment(
          value: VehicleType.ev,
          label: Text(l?.vehicleTypeEv ?? 'Electric'),
          icon: const Icon(Icons.electric_car),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}
