// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../logging/app_log.dart';
import '../../logging/error_logger.dart';
import 'fleet_transport.dart';

/// The three explicit roles of ADR 0025 D1 — never inferred from
/// `database_owner` or a generic admin flag.
enum FleetRole {
  employee('employee'),
  manager('manager'),
  admin('admin');

  const FleetRole(this.wireName);

  /// The `fleet_members.role` value.
  final String wireName;

  /// Null for a role this build does not know — a newer server must not
  /// decode as *some* role.
  static FleetRole? fromWireName(String? name) {
    for (final r in values) {
      if (r.wireName == name) return r;
    }
    return null;
  }

  /// May read the org roster and org-wide assignments; may call the
  /// write RPCs.
  bool get isManager => this == manager || this == admin;
}

/// The caller's own `fleet_members` row: which org, which role.
class FleetMembership {
  const FleetMembership({
    required this.orgId,
    required this.role,
    required this.active,
  });

  final String orgId;
  final FleetRole role;

  /// `status = 'active'`; a member who left keeps the row for history
  /// but no oracle answers true for them any more.
  final bool active;

  /// Decodes a server row; null when a required field is missing or
  /// the role is unknown.
  static FleetMembership? fromRow(Map<String, dynamic> row) {
    final orgId = row['org_id'];
    final role = FleetRole.fromWireName(row['role'] as String?);
    if (orgId is! String || orgId.isEmpty || role == null) return null;
    return FleetMembership(
      orgId: orgId,
      role: role,
      active: row['status'] == null || row['status'] == 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'org_id': orgId,
        'role': role.wireName,
        'status': active ? 'active' : 'left',
      };

  @override
  bool operator ==(Object other) =>
      other is FleetMembership &&
      other.orgId == orgId &&
      other.role == role &&
      other.active == active;

  @override
  int get hashCode => Object.hash(orgId, role, active);

  @override
  String toString() =>
      'FleetMembership($orgId, ${role.wireName}${active ? '' : ', left'})';
}

/// Reads the caller's fleet membership (#4212) — the one row RLS lets
/// every member see about themselves. Pull-only; joining and leaving
/// are RPCs (F8).
class FleetMembershipSync {
  FleetMembershipSync._();

  /// The caller's membership, or null when unauthenticated, in no
  /// fleet, or when the wire call failed (logged under
  /// [ErrorLayer.sync]; a fault is reported, not thrown).
  ///
  /// ADR 0025 D1 makes the row unique per user; should a later schema
  /// allow several, the first active one wins here.
  static Future<FleetMembership?> fetchOwn({FleetTransport? transport}) async {
    final t = transport ?? SupabaseFleetTransport.currentOrNull();
    if (t == null) return null;
    try {
      final rows = await t.selectOwn(FleetTables.members, 'org_id,role,status');
      FleetMembership? first;
      for (final row in rows) {
        final m = FleetMembership.fromRow(row);
        if (m == null) continue;
        if (m.active) return m;
        first ??= m;
      }
      return first;
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: const {
        'where': 'FleetMembershipSync.fetchOwn FAILED',
        'entity': FleetTables.members,
      });
      return null;
    }
  }
}
