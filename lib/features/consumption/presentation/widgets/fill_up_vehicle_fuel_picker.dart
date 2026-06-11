// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/fuel_type_dropdown.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../domain/add_fill_up_fuel_resolver.dart';

/// Fuel picker constrained to the vehicle's compatible fuels (#713).
///
/// A petrol car gets [e10, e5, e98, e85]; a diesel car gets
/// [diesel, dieselPremium]; EV / LPG / CNG / H₂ vehicles pick from
/// their single applicable fuel only. The initial value is the one
/// resolved by [AddFillUpFuelResolver.resolveDefaultFuel] — profile
/// preference when compatible, else the vehicle's own fuel — so the
/// form always loads with the most likely choice but still lets the
/// user override it for this specific fill-up (e.g. a flex-fuel
/// E85 car tanking regular SP95 this week).
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC.
class FillUpVehicleFuelPicker extends StatelessWidget {
  final List<VehicleProfile> vehicles;
  final String vehicleId;
  final FuelType fuelType;
  final ValueChanged<FuelType> onChanged;
  final VoidCallback onOpenVehicle;

  const FillUpVehicleFuelPicker({
    super.key,
    required this.vehicles,
    required this.vehicleId,
    required this.fuelType,
    required this.onChanged,
    required this.onOpenVehicle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vehicle = vehicles.firstWhere((v) => v.id == vehicleId);
    final vehicleFuel =
        AddFillUpFuelResolver.fuelForVehicle(vehicle) ?? FuelType.e10;
    final compatible = compatibleFuelsFor(vehicleFuel);
    final value =
        compatible.contains(fuelType) ? fuelType : compatible.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FuelTypeDropdown(
                value: value,
                options: compatible,
                prefixIcon: const Icon(Icons.local_gas_station),
                labelText: '${l?.fuelType ?? 'Fuel type'} • ${vehicle.name}',
                onChanged: onChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: l?.vehicleEditTitle ?? 'Edit vehicle',
              onPressed: onOpenVehicle,
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        // #2886 — a multi-fuel vehicle gets a prominent hint reminding
        // the user to log the fuel they ACTUALLY pumped this tank, since
        // the per-fuel €/km comparison depends on that being accurate.
        if (vehicle.multiFuelCapable) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l?.fillUpMultiFuelHint ??
                      'This vehicle can use different fuels — log the one '
                          'you actually pumped',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
