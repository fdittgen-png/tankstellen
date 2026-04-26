import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../consumption/providers/consumption_providers.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/vehicle_profile.dart';
import '../../providers/vehicle_providers.dart';

/// Cross-cutting actions the edit-vehicle screen runs against
/// Riverpod providers: default-profile sync, volumetric-efficiency
/// reset, latest-odometer lookup. Gathering them here keeps the
/// screen focused on form composition.
extension VehicleSaveActions on WidgetRef {
  /// #710 — auto-set [profile] as the active profile's default and
  /// sync its preferredFuelType when (a) no default is set, or
  /// (b) editing the already-default vehicle. Silently swallows
  /// errors (with a debugPrint) because the primary save has
  /// already succeeded by the time we hit this path.
  Future<void> syncActiveProfile(VehicleProfile profile) async {
    try {
      final profileRepo = read(profileRepositoryProvider);
      final activeProfile = read(activeProfileProvider);
      if (activeProfile == null) return;
      final shouldBecomeDefault = activeProfile.defaultVehicleId == null ||
          activeProfile.defaultVehicleId == profile.id;
      if (!shouldBecomeDefault) return;
      final derived = deriveFuelTypeFromVehicle(profile);
      final updated = activeProfile.copyWith(
        defaultVehicleId: profile.id,
        preferredFuelType: derived ?? activeProfile.preferredFuelType,
      );
      await profileRepo.updateProfile(updated);
      read(activeProfileProvider.notifier).refresh();
    } catch (e, st) {
      debugPrint('EditVehicleScreen: profile sync failed: $e\n$st');
    }
  }

  /// #815 — reset the learned η_v for [vehicleId] back to the
  /// default (0.85) and clear the sample counter.
  Future<void> resetVolumetricEfficiency(String vehicleId) async {
    try {
      final list = read(vehicleProfileListProvider);
      final existing = list.where((v) => v.id == vehicleId).firstOrNull;
      if (existing == null) return;
      final cleared = existing.copyWith(
        volumetricEfficiency: 0.85,
        volumetricEfficiencySamples: 0,
      );
      await read(vehicleProfileListProvider.notifier).save(cleared);
    } catch (e, st) {
      debugPrint('EditVehicleScreen: VE reset failed: $e\n$st');
    }
  }

  /// #584 — latest odometer reading logged for [vehicleId]. Returns
  /// null when no fill-ups exist so the reminder section can prompt
  /// the user for a manual entry.
  double? latestOdometerKm(String vehicleId) {
    try {
      final fillUps = watch(fillUpListProvider);
      final forVehicle = fillUps.where((f) => f.vehicleId == vehicleId);
      if (forVehicle.isEmpty) return null;
      final latest =
          forVehicle.reduce((a, b) => a.odometerKm > b.odometerKm ? a : b);
      return latest.odometerKm;
    } catch (e, st) {
      debugPrint('EditVehicleScreen: odometer lookup failed: $e\n$st');
      return null;
    }
  }
}

/// #710 — translate a vehicle's type + stored preferredFuelType into
/// the canonical [FuelType]. EV → electric; combustion parses via
/// [FuelType.fromString]. Hybrid keeps the combustion fuel until
/// #704 ships `hybridFuelChoice`.
FuelType? deriveFuelTypeFromVehicle(VehicleProfile v) {
  if (v.type == VehicleType.ev) return FuelType.electric;
  final raw = v.preferredFuelType;
  if (raw == null || raw.trim().isEmpty) return null;
  return FuelType.fromString(raw);
}
