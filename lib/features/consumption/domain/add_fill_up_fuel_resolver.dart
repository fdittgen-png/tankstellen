import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';

/// Pure helpers that map a [VehicleProfile] to its preferred [FuelType],
/// pick the initial vehicle on the Add-Fill-up form, and resolve which
/// fuel the form should land on by default. Pulled out of
/// `add_fill_up_screen.dart` (#563 extraction) so the policy is
/// unit-testable and a future change (e.g. a per-station preferred
/// fuel) only touches the helper.
///
/// Mirrors `charging_log_readout.dart` / `charging_log_validators.dart`
/// pattern PR #1156 set on master for the Add-Charging-Log form.
class AddFillUpFuelResolver {
  AddFillUpFuelResolver._();

  /// Resolve the vehicle's fuel type (#698). EV → electric; combustion
  /// → the stored preferredFuelType parsed back to the typed enum.
  /// Returns `null` when the vehicle has no fuel configured.
  static FuelType? fuelForVehicle(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }

  /// Default-fuel policy (#713):
  ///   1. [preFill] (from receipt scan / station context) if it is
  ///      compatible with the vehicle.
  ///   2. [profilePreferred] if compatible — honours "suggest by
  ///      default the one in the profile" for flex-fuel vehicles.
  ///   3. The vehicle's own preferred fuel as the fallback.
  ///   4. [FuelType.e10] as the global last-resort default (when the
  ///      vehicle has nothing configured).
  static FuelType resolveDefaultFuel({
    required VehicleProfile vehicle,
    FuelType? profilePreferred,
    FuelType? preFill,
  }) {
    final vehicleFuel = fuelForVehicle(vehicle) ?? FuelType.e10;
    final compatible = compatibleFuelsFor(vehicleFuel);
    if (preFill != null && compatible.contains(preFill)) return preFill;
    if (profilePreferred != null && compatible.contains(profilePreferred)) {
      return profilePreferred;
    }
    return vehicleFuel;
  }

  /// Pick the initial vehicle id for the Add-Fill-up form (#713):
  ///   1. The profile's `defaultVehicleId` if it exists in [vehicles].
  ///   2. The currently-active vehicle's id if it exists in [vehicles].
  ///   3. The first vehicle in the list (vehicle is mandatory).
  ///
  /// Returns `null` only when [vehicles] is empty — the screen reacts
  /// to that by routing to the "Add a vehicle first" CTA.
  static String? pickInitialVehicleId({
    required List<VehicleProfile> vehicles,
    String? profileDefaultId,
    String? activeVehicleId,
  }) {
    if (vehicles.isEmpty) return null;
    if (profileDefaultId != null &&
        vehicles.any((v) => v.id == profileDefaultId)) {
      return profileDefaultId;
    }
    if (activeVehicleId != null &&
        vehicles.any((v) => v.id == activeVehicleId)) {
      return activeVehicleId;
    }
    return vehicles.first.id;
  }
}
