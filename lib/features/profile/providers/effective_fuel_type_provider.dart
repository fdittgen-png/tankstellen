import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import 'profile_provider.dart';

part 'effective_fuel_type_provider.g.dart';

/// Resolves the **effective** fuel type the app should use, based on
/// the vehicle-vs-direct contract described in #694/#700/#706.
///
/// Priority:
///   1. If a default vehicle is configured and matches a stored
///      vehicle:
///      - EV vehicle → [FuelType.electric]
///      - Combustion vehicle → vehicle's preferredFuelType parsed via
///        [FuelType.fromString]; fall back to profile's
///        `preferredFuelType` if the vehicle has no fuel set
///      - Hybrid vehicle → profile's `hybridFuelChoice` when set,
///        otherwise the vehicle's own combustion fuel (pre-#706
///        profiles keep the ICE side by default).
///   2. Otherwise the profile's own `preferredFuelType` wins.
///
/// Every picker in the app (search chips, station filters,
/// consumption log) should read from this provider so a change to
/// the profile, the vehicle, or the hybrid choice propagates in
/// one place.
@Riverpod(keepAlive: true)
FuelType effectiveFuelType(Ref ref) {
  final profile = ref.watch(activeProfileProvider);
  final vehicles = ref.watch(vehicleProfileListProvider);
  final defaultVehicleId = profile?.defaultVehicleId;

  if (defaultVehicleId != null) {
    final match =
        vehicles.where((v) => v.id == defaultVehicleId).firstOrNull;
    if (match != null) {
      final derived = _fuelForVehicle(
        match,
        hybridChoice: profile?.hybridFuelChoice,
      );
      if (derived != null) return derived;
    }
  }

  return profile?.preferredFuelType ?? FuelType.e10;
}

/// Resolve a vehicle (plus an optional profile-level hybrid choice)
/// into a single [FuelType], or null when the vehicle carries no
/// usable fuel info.
FuelType? _fuelForVehicle(
  VehicleProfile v, {
  FuelType? hybridChoice,
}) {
  switch (v.type) {
    case VehicleType.ev:
      return FuelType.electric;
    case VehicleType.combustion:
      final raw = v.preferredFuelType;
      if (raw == null || raw.trim().isEmpty) return null;
      return FuelType.fromString(raw);
    case VehicleType.hybrid:
      if (hybridChoice != null) return hybridChoice;
      final raw = v.preferredFuelType;
      if (raw == null || raw.trim().isEmpty) return null;
      return FuelType.fromString(raw);
  }
}
