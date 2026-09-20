// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The company asset an employee drives (#4213, Epic #4211, ADR 0025).
///
/// Deliberately NOT a flavour of `VehicleProfile`: the personal profile
/// is the driver's own record of a car (calibration, adapter pairing,
/// tank curve) and lives on the device; a [FleetVehicle] is the
/// employer's asset identity and lives in `fleet_vehicles`. The two are
/// linked by [localVehicleProfileId] — one nullable pointer — so a
/// handover swaps the fleet identity without rewriting the driver's
/// calibration history, and an employee with no local profile for the
/// car they were handed this morning still has a fleet vehicle to log
/// against.
///
/// Plain value type with an explicit JSON codec, like every other type
/// under `lib/core/sync/fleet/` — it is persisted inside a fill-up's
/// JSONB blob, where a freezed/codegen dependency would buy nothing.
library;

import '../../../core/sync/fleet/fleet_directory.dart';

/// One fleet vehicle, as the employee's device knows it.
class FleetVehicle {
  const FleetVehicle({
    required this.fleetVehicleId,
    required this.orgId,
    required this.fleetCode,
    required this.displayName,
    this.plateMasked,
    this.localVehicleProfileId,
  });

  /// `fleet_vehicles.id` — the stable company-asset identity. This, not
  /// a plate and not an adapter MAC, is what a fill-up records.
  final String fleetVehicleId;

  /// The owning organisation. Carried on the vehicle so a cached
  /// directory from another org can never be rendered under this one.
  final String orgId;

  /// The short human handle the fleet uses on keys and paperwork
  /// ("VAN-12"). The first thing an employee searches by.
  final String fleetCode;

  /// Make/model as the fleet maintains it ("VW Caddy 2.0 TDI").
  final String displayName;

  /// Registration, masked by the server to whatever the deployment's
  /// policy allows (ADR 0025 D8). Null when policy shows no plate at
  /// all — never reconstructed from anything else.
  final String? plateMasked;

  /// The driver's own `VehicleProfile.id` for this car, when they have
  /// one. Device-local: it is not part of the org directory.
  final String? localVehicleProfileId;

  /// Whether [query] matches this vehicle's fleet code, model name or
  /// plate *fragment* (#4213: "search by fleet code, model or allowed
  /// registration fragment"). Case- and space-insensitive, substring —
  /// a driver typing `12` finds `VAN-12` and `B-XY 1234`.
  bool matches(String query) {
    final q = _normalise(query);
    if (q.isEmpty) return true;
    return _normalise(fleetCode).contains(q) ||
        _normalise(displayName).contains(q) ||
        _normalise(plateMasked ?? '').contains(q);
  }

  FleetVehicle withLocalProfile(String? localVehicleProfileId) => FleetVehicle(
        fleetVehicleId: fleetVehicleId,
        orgId: orgId,
        fleetCode: fleetCode,
        displayName: displayName,
        plateMasked: plateMasked,
        localVehicleProfileId: localVehicleProfileId,
      );

  /// The directory row as a domain vehicle. [localVehicleProfileId] is
  /// the device's own mapping — the row never carries it.
  static FleetVehicle fromRow(
    FleetVehicleRow row, {
    String? localVehicleProfileId,
  }) =>
      FleetVehicle(
        fleetVehicleId: row.id,
        orgId: row.orgId,
        fleetCode: row.fleetCode,
        displayName: row.displayName,
        plateMasked: row.plateMasked,
        localVehicleProfileId: localVehicleProfileId,
      );

  /// Null when the blob is missing the identity fields — a half-read
  /// vehicle must not decode as *some* vehicle.
  static FleetVehicle? fromJson(Map<String, dynamic> json) {
    final id = json['fleet_vehicle_id'];
    final orgId = json['org_id'];
    final code = json['fleet_code'];
    final name = json['display_name'];
    if (id is! String || orgId is! String || code is! String ||
        name is! String) {
      return null;
    }
    return FleetVehicle(
      fleetVehicleId: id,
      orgId: orgId,
      fleetCode: code,
      displayName: name,
      plateMasked: json['plate_masked'] as String?,
      localVehicleProfileId: json['local_vehicle_profile_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fleet_vehicle_id': fleetVehicleId,
        'org_id': orgId,
        'fleet_code': fleetCode,
        'display_name': displayName,
        'plate_masked': plateMasked,
        'local_vehicle_profile_id': localVehicleProfileId,
      };

  @override
  bool operator ==(Object other) =>
      other is FleetVehicle &&
      other.fleetVehicleId == fleetVehicleId &&
      other.orgId == orgId &&
      other.fleetCode == fleetCode &&
      other.displayName == displayName &&
      other.plateMasked == plateMasked &&
      other.localVehicleProfileId == localVehicleProfileId;

  @override
  int get hashCode => Object.hash(fleetVehicleId, orgId, fleetCode,
      displayName, plateMasked, localVehicleProfileId);

  @override
  String toString() => 'FleetVehicle($fleetCode, $fleetVehicleId)';
}

String _normalise(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[\s\-_.]'), '');
