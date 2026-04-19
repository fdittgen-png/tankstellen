import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import 'profile_provider.dart';

part 'effective_fuel_type_provider.g.dart';

/// Resolves the **effective** fuel type the app should use, based on the
/// vehicle-vs-direct contract described in #694/#705.
///
/// Priority:
///   1. If a default vehicle is configured and matches a stored vehicle:
///      - EV vehicle → [FuelType.electric]
///      - Combustion vehicle → vehicle's preferredFuelType parsed via
///        [FuelType.fromString]; fall back to profile's `preferredFuelType`
///        if the vehicle has no fuel set
///      - Hybrid vehicle → not handled here; #704 will add
///        `hybridFuelChoice` and route through it.
///   2. Otherwise the profile's own `preferredFuelType` wins.
///
/// Every picker in the app (search chips, station filters, consumption
/// log) should read from this provider so a change to the profile or
/// the vehicle propagates in one place.
@Riverpod(keepAlive: true)
FuelType effectiveFuelType(Ref ref) {
  final profile = ref.watch(activeProfileProvider);
  final vehicles = ref.watch(vehicleProfileListProvider);
  final defaultVehicleId = profile?.defaultVehicleId;

  if (defaultVehicleId != null) {
    final match =
        vehicles.where((v) => v.id == defaultVehicleId).firstOrNull;
    if (match != null) {
      final derived = _fuelForVehicle(match);
      if (derived != null) return derived;
    }
  }

  return profile?.preferredFuelType ?? FuelType.e10;
}

/// EV → electric. Combustion → parsed preferredFuelType.
/// Hybrid falls through to null (use profile default until #704 ships
/// `hybridFuelChoice`).
FuelType? _fuelForVehicle(VehicleProfile v) {
  switch (v.type) {
    case VehicleType.ev:
      return FuelType.electric;
    case VehicleType.combustion:
      final raw = v.preferredFuelType;
      if (raw == null || raw.trim().isEmpty) return null;
      return FuelType.fromString(raw);
    case VehicleType.hybrid:
      return null;
  }
}
