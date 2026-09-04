// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/vehicle_profile.dart';
import '../entities/fill_up.dart';

/// Which fills belong to the active vehicle (#3945).
///
/// A fill's `vehicleId` is null when it was logged before vehicle profiles
/// existed, or when the picker was left blank. Whose is it?
///
/// * **One vehicle profile** — it can only be that car's. Excluding those
///   fills (the #3934 rule) made single-vehicle users lose their whole
///   pre-profile history from the per-fuel comparison and the all-prices
///   table, so they are attributed to the active vehicle.
/// * **Two or more profiles** — ambiguous; an unassigned fill of the other
///   car must never move this car's number. Excluded, as before.
///
/// No active [vehicle] ⇒ every fill (nothing to scope on).
List<FillUp> scopeFillUpsToVehicle(
  List<FillUp> fills, {
  required VehicleProfile? vehicle,
  required int vehicleCount,
}) {
  if (vehicle == null) return fills;
  final claimUnassigned = vehicleCount <= 1;
  return fills
      .where(
        (f) =>
            f.vehicleId == vehicle.id ||
            (claimUnassigned && f.vehicleId == null),
      )
      .toList(growable: false);
}
