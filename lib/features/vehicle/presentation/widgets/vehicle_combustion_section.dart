import 'package:flutter/material.dart';

import '../../../../core/widgets/fuel_type_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';

/// Combustion-engine portion of the [EditVehicleScreen] form. Owns the tank
/// capacity and preferred fuel inputs.
///
/// The preferred-fuel picker uses the shared [NullableFuelTypeDropdown] so
/// every surface (profile, vehicle, fill-up) shows the same polished labels
/// (#713). Electric and the synthetic "all" sentinel are excluded — EV
/// fuel is configured via the EV section.
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

  static const List<FuelType> _combustionFuels = [
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final raw = fuelTypeController.text.trim();
    final parsed = raw.isEmpty ? null : FuelType.fromString(raw);
    final currentValue =
        (parsed != null && _combustionFuels.contains(parsed)) ? parsed : null;
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
        NullableFuelTypeDropdown(
          value: currentValue,
          labelText: l?.vehiclePreferredFuelLabel ?? 'Preferred fuel',
          prefixIcon: const Icon(Icons.local_gas_station),
          options: _combustionFuels,
          onChanged: (v) {
            // Store the canonical apiValue (lower-case) so existing
            // call sites that read the string continue to work.
            fuelTypeController.text = v?.apiValue ?? '';
          },
        ),
      ],
    );
  }
}
