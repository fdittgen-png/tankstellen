// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/fuel_type_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import 'engine_power_field.dart';

/// Combustion-engine portion of the [EditVehicleScreen] form. Owns the tank
/// capacity and preferred fuel inputs.
///
/// The preferred-fuel picker uses the shared [NullableFuelTypeDropdown] so
/// every surface (profile, vehicle, fill-up) shows the same polished labels
/// (#713). Electric and the synthetic "all" sentinel are excluded — EV
/// fuel is configured via the EV section.
///
/// #2885 — when the chosen preferred fuel is in the PETROL family AND is
/// E10 or E85 (the flex-fuel grades the per-fuel €/km comparison targets),
/// a "I may fill up with different fuel types" switch is offered. It is
/// hidden for diesel / LPG / CNG / E5 / E98 / EV — a single-fuel vehicle
/// has nothing to compare. The flag drives the per-fill fuel prompt (#2886)
/// and the per-fuel efficiency card (#2887).
class VehicleCombustionSection extends StatelessWidget {
  final TextEditingController tankController;
  final TextEditingController fuelTypeController;

  /// Epic #3015 — rated engine power in kW. Pre-filled from the catalog
  /// pick, user-overridable. The PS equivalent is derived live in
  /// [EnginePowerField] and shown as the field's helper text.
  final TextEditingController powerKwController;

  final String? Function(String?) numberValidator;

  /// #2885 — current value of [VehicleProfile.multiFuelCapable]. Only
  /// surfaced (and toggleable) when [_offersMultiFuel] is true for the
  /// selected fuel.
  final bool multiFuelCapable;
  final ValueChanged<bool> onMultiFuelCapableChanged;

  /// #2885 — fired when the user changes the preferred-fuel dropdown.
  /// The owning screen `setState`s on this so the multi-fuel switch
  /// shows / hides as the fuel moves in and out of the E10 / E85 set.
  final ValueChanged<FuelType?> onFuelTypeChanged;

  const VehicleCombustionSection({
    super.key,
    required this.tankController,
    required this.fuelTypeController,
    required this.powerKwController,
    required this.numberValidator,
    required this.multiFuelCapable,
    required this.onMultiFuelCapableChanged,
    required this.onFuelTypeChanged,
  });

  /// The flex-fuel grades the multi-fuel comparison targets. E5 / E98 are
  /// intentionally excluded — a regular SP95 / SP98 car is single-fuel in
  /// practice; the E85 ↔ E10 (↔ E5) decision is the one the feature serves.
  static bool _offersMultiFuel(FuelType? fuel) =>
      fuel != null &&
      fuelCompatibilityFamily(fuel) == FuelCompatibilityFamily.petrol &&
      (fuel == FuelType.e10 || fuel == FuelType.e85);

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
        // Epic #3015 — rated engine power (kW), pre-filled from the
        // catalog pick, user-overridable. Helper text shows the live PS
        // equivalent.
        EnginePowerField(
          controller: powerKwController,
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
            // #2885 — let the owning screen rebuild so the multi-fuel
            // switch shows / hides as the selection moves in and out of
            // the E10 / E85 set.
            onFuelTypeChanged(v);
          },
        ),
        // #2885 — multi-fuel capability switch. Offered only for the
        // flex-fuel petrol grades (E10 / E85); single-fuel vehicles have
        // nothing to compare per kilometre.
        if (_offersMultiFuel(currentValue)) ...[
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('vehicle_multi_fuel_capable_switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l?.vehicleMultiFuelCapableLabel ??
                  'I may fill up with different fuel types',
            ),
            subtitle: Text(
              l?.vehicleMultiFuelCapableHelper ??
                  'Tracks which fuel is cheapest per kilometre',
            ),
            value: multiFuelCapable,
            onChanged: onMultiFuelCapableChanged,
          ),
        ],
      ],
    );
  }
}
