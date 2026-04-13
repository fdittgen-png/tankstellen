import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Combustion-engine portion of the [EditVehicleScreen] form. Owns the tank
/// capacity and preferred fuel inputs.
class VehicleCombustionSection extends StatelessWidget {
  final TextEditingController tankController;
  final TextEditingController fuelTypeController;
  final String? Function(String?) numberValidator;

  const VehicleCombustionSection({
    super.key,
    required this.tankController,
    required this.fuelTypeController,
    required this.numberValidator,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l?.vehicleCombustionSectionTitle ?? 'Combustion',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: tankController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l?.vehicleTankLabel ?? 'Tank capacity (L)',
          ),
          validator: numberValidator,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: fuelTypeController,
          decoration: InputDecoration(
            labelText: l?.vehiclePreferredFuelLabel ?? 'Preferred fuel',
            hintText: 'e.g. Diesel, E10',
          ),
        ),
      ],
    );
  }
}
