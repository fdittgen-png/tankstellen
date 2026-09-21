// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The org directory an employee's device holds (#4212, ADR 0025): the
/// organisation, its vehicles, the assignments RLS let the caller see,
/// and the policy row — plus when it was fetched, which is what D4's
/// freshness is judged from.
///
/// Plain value types with explicit JSON codecs (no codegen) — they are
/// persisted into the encrypted `fleet_directory` box and exported
/// under `local/fleet_directory.json`. Nothing here carries a location;
/// nothing here carries another person's name (an assignment names a
/// `user_id`, and RLS returns only the caller's own unless they are a
/// manager).
library;

/// One `fleet_vehicles` row.
class FleetVehicleRow {
  const FleetVehicleRow({
    required this.id,
    required this.orgId,
    required this.fleetCode,
    required this.displayName,
    this.plateMasked,
    this.data = const {},
  });

  final String id;
  final String orgId;
  final String fleetCode;
  final String displayName;
  final String? plateMasked;
  final Map<String, dynamic> data;

  static FleetVehicleRow? fromJson(Map<String, dynamic> row) {
    final id = row['id'];
    final orgId = row['org_id'];
    final code = row['fleet_code'];
    final name = row['display_name'];
    if (id is! String || orgId is! String || code is! String || name is! String) {
      return null;
    }
    final data = row['data'];
    return FleetVehicleRow(
      id: id,
      orgId: orgId,
      fleetCode: code,
      displayName: name,
      plateMasked: row['plate_masked'] as String?,
      data: data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'fleet_code': fleetCode,
        'display_name': displayName,
        'plate_masked': plateMasked,
        'data': data,
      };
}

/// One `vehicle_assignments` row — effective-dated; an ended one keeps
/// its history (ADR 0025 D7).
class FleetAssignmentRow {
  const FleetAssignmentRow({
    required this.id,
    required this.orgId,
    required this.fleetVehicleId,
    required this.userId,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final String orgId;
  final String fleetVehicleId;
  final String userId;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  /// No end stamped yet.
  bool get isOpen => effectiveTo == null;

  /// Whether the assignment covers [at] — the rule a fill-up's
  /// attribution reads (F4).
  bool isActiveAt(DateTime at) {
    final t = at.toUtc();
    if (t.isBefore(effectiveFrom)) return false;
    final end = effectiveTo;
    return end == null || t.isBefore(end);
  }

  static FleetAssignmentRow? fromJson(Map<String, dynamic> row) {
    final id = row['id'];
    final orgId = row['org_id'];
    final vehicle = row['fleet_vehicle_id'];
    final user = row['user_id'];
    final from = _utc(row['effective_from']);
    if (id is! String ||
        orgId is! String ||
        vehicle is! String ||
        user is! String ||
        from == null) {
      return null;
    }
    return FleetAssignmentRow(
      id: id,
      orgId: orgId,
      fleetVehicleId: vehicle,
      userId: user,
      effectiveFrom: from,
      effectiveTo: _utc(row['effective_to']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'org_id': orgId,
        'fleet_vehicle_id': fleetVehicleId,
        'user_id': userId,
        'effective_from': effectiveFrom.toUtc().toIso8601String(),
        'effective_to': effectiveTo?.toUtc().toIso8601String(),
      };
}

/// The whole directory of one org as this device last saw it.
class FleetDirectory {
  const FleetDirectory({
    required this.orgId,
    required this.orgName,
    required this.vehicles,
    required this.assignments,
    required this.policy,
    required this.fetchedAt,
  });

  final String orgId;
  final String orgName;
  final List<FleetVehicleRow> vehicles;
  final List<FleetAssignmentRow> assignments;

  /// `fleet_policies.data` — thresholds and retention (ADR 0025 D9).
  final Map<String, dynamic> policy;

  /// When the pull that produced this ran — UTC, from the injected
  /// clock, so the freshness judgement is testable.
  final DateTime fetchedAt;

  /// The assignments of [userId] that are open right now.
  List<FleetAssignmentRow> openAssignmentsOf(String userId) => [
        for (final a in assignments)
          if (a.userId == userId && a.isOpen) a,
      ];

  static FleetDirectory? fromJson(Map<String, dynamic> json) {
    final orgId = json['org_id'];
    final orgName = json['org_name'];
    final fetchedAt = _utc(json['fetched_at']);
    if (orgId is! String || orgName is! String || fetchedAt == null) {
      return null;
    }
    final vehicles = json['vehicles'];
    final assignments = json['assignments'];
    final policy = json['policy'];
    return FleetDirectory(
      orgId: orgId,
      orgName: orgName,
      vehicles: [
        if (vehicles is List)
          for (final v in vehicles)
            if (v is Map)
              ?FleetVehicleRow.fromJson(Map<String, dynamic>.from(v)),
      ],
      assignments: [
        if (assignments is List)
          for (final a in assignments)
            if (a is Map)
              ?FleetAssignmentRow.fromJson(Map<String, dynamic>.from(a)),
      ],
      policy: policy is Map ? Map<String, dynamic>.from(policy) : const {},
      fetchedAt: fetchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'org_id': orgId,
        'org_name': orgName,
        'vehicles': [for (final v in vehicles) v.toJson()],
        'assignments': [for (final a in assignments) a.toJson()],
        'policy': policy,
        'fetched_at': fetchedAt.toUtc().toIso8601String(),
      };
}

/// A TIMESTAMPTZ / ISO-8601 value as UTC, or null when absent or
/// unreadable — an unreadable stamp must not decode as *some* time.
DateTime? _utc(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
