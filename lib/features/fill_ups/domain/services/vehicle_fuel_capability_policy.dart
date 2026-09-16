// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';

/// The approvals a [VehicleProfile] can honestly vouch for (#4278).
///
/// Nothing persists a `VehicleFuelCapability` yet, so this reads the only
/// facts the profile holds — the configured fuel, the multi-fuel
/// declaration and the powertrain — and never widens them by the
/// "physically fits the filler neck" family (#713), which is exactly the
/// mapping #4274 forbids as an approval basis:
///
///  * no vehicle, an EV, or no / unparseable configured fuel →
///    [VehicleFuelCapability.unknown];
///  * E85 configured AND declared multi-fuel → the flex-fuel petrol grades
///    (a flex-fuel car is built for E0–E85; the declaration says it
///    alternates);
///  * a petrol grade other than E85 declared multi-fuel → the E5-class and
///    E10 grades, never E85 — "I may fill different fuels" says nothing
///    about ethanol above 10 %;
///  * anything else → the configured grade alone.
///
/// Grades outside the approval stay "not confirmed", which the surface
/// states as such rather than as a refusal.
VehicleFuelCapability vehicleFuelCapabilityOf(VehicleProfile? vehicle) {
  if (vehicle == null || vehicle.type == VehicleType.ev) {
    return const VehicleFuelCapability.unknown();
  }
  final preferred = configuredGradeOf(vehicle);
  if (preferred == null || !preferred.isLiquid) {
    return const VehicleFuelCapability.unknown();
  }
  if (vehicle.multiFuelCapable && preferred == FuelGrade.e85) {
    return VehicleFuelCapability(
      approvedGrades: const [
        FuelGrade.e5,
        FuelGrade.e10,
        FuelGrade.e98,
        FuelGrade.e85,
      ],
      provenance: kCapabilityProvenanceFlexFuel,
    );
  }
  if (vehicle.multiFuelCapable && _petrolBelowE85.contains(preferred)) {
    return VehicleFuelCapability(
      approvedGrades: _petrolBelowE85,
      provenance: kCapabilityProvenanceMultiFuelPetrol,
    );
  }
  return VehicleFuelCapability(
    approvedGrades: [preferred],
    provenance: kCapabilityProvenanceConfiguredFuel,
  );
}

/// Provenance of a capability read from the configured fuel alone.
const String kCapabilityProvenanceConfiguredFuel = 'vehicle-profile:fuel';

/// Provenance of an E85 vehicle declared multi-fuel.
const String kCapabilityProvenanceFlexFuel = 'vehicle-profile:flex-fuel';

/// Provenance of a non-E85 petrol vehicle declared multi-fuel.
const String kCapabilityProvenanceMultiFuelPetrol =
    'vehicle-profile:multi-fuel-petrol';

const List<FuelGrade> _petrolBelowE85 = [
  FuelGrade.e5,
  FuelGrade.e10,
  FuelGrade.e98,
];

/// The vehicle's configured fuel as a commercial grade, or null when none
/// is configured (or it names no real grade).
FuelGrade? configuredGradeOf(VehicleProfile vehicle) {
  final raw = vehicle.preferredFuelType;
  if (raw == null || raw.isEmpty) return null;
  final grade = FuelGrade.fromKey(raw);
  return grade == FuelGrade.unknown || grade == FuelGrade.wildcard
      ? null
      : grade;
}

/// Whether [vehicle] burns liquid fuel — the only vehicles the Fuel & Tank
/// surface has anything to say about. A combustion or hybrid vehicle with
/// no configured fuel still qualifies: its blend is still tracked.
bool burnsLiquidFuel(VehicleProfile? vehicle) {
  if (vehicle == null || vehicle.type == VehicleType.ev) return false;
  final grade = configuredGradeOf(vehicle);
  return grade == null || grade.isLiquid;
}

/// The liquid grades worth pricing for [vehicle]: the ones that physically
/// fit its filler neck (#713). This is NOT an approval — the decision
/// excludes whatever the capability does not approve, and says why.
List<FuelGrade> priceableGradesOf(VehicleProfile? vehicle) {
  final preferred = vehicle == null ? null : configuredGradeOf(vehicle);
  final family = preferred == null
      ? FuelType.values
      : compatibleFuelsFor(FuelType.fromString(preferred.key));
  return [
    for (final fuel in family)
      if (FuelGrade.fromKey(fuel.apiValue) case final g when g.isLiquid) g,
  ]..sort((a, b) => a.index.compareTo(b.index));
}
