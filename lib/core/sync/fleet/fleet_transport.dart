// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client.dart';
import '../sync_transport.dart' show JsonRow, SyncFencedException;

/// The five org-scoped tables of the fleet schema (#4212, ADR 0025) —
/// a closed set, so a [FleetTransport] can never be pointed at a user
/// table by an org filter.
abstract final class FleetTables {
  static const String organizations = 'fleet_organizations';
  static const String members = 'fleet_members';
  static const String vehicles = 'fleet_vehicles';
  static const String assignments = 'vehicle_assignments';
  static const String policies = 'fleet_policies';

  /// Every fleet table.
  static const Set<String> all = {
    organizations, members, vehicles, assignments, policies,
  };

  /// The tables that carry a `user_id` and may be read as "mine".
  static const Set<String> userLinked = {members, assignments};
}

/// Wire seam for the org-scoped fleet reads and the fleet RPCs (#4212),
/// mirroring [SyncTransport] (#3122) and `TripShareTransport` (#3747):
/// production passes nothing and gets [SupabaseFleetTransport.currentOrNull];
/// tests inject a fake.
///
/// **Pull-only.** There is no upsert and no delete: every org write is
/// an RPC that re-checks role and org server-side (ADR 0025 D7), and
/// nothing fleet-owned is uploaded from the device. The transport is not
/// an [EntitySync] transport on purpose — that engine's contract is "the
/// caller owns every row it writes", and an organisation's row is not
/// the uploading employee's.
abstract class FleetTransport {
  /// The authenticated caller's user id.
  String get userId;

  /// Host of the backend this transport talks to (#4047) — part of the
  /// directory cache key together with [userId] and the org id.
  String? get backendUrl => null;

  /// `SELECT [columns] FROM [table] WHERE <org column> = [orgId]` over one
  /// of [FleetTables.all]. RLS decides which rows come back; the filter
  /// only says which org the caller is asking about.
  Future<List<JsonRow>> selectOrg(
    String table,
    String columns, {
    required String orgId,
  });

  /// `SELECT [columns] FROM [table] WHERE user_id = userId` over one of
  /// [FleetTables.userLinked].
  Future<List<JsonRow>> selectOwn(String table, String columns);

  /// `POST /rpc/[fn]` with [params]; the decoded response body.
  Future<dynamic> rpc(String fn, Map<String, dynamic> params);
}

/// The production [FleetTransport] over the live [TankSyncClient].
class SupabaseFleetTransport implements FleetTransport {
  final SupabaseClient _client;

  @override
  final String userId;

  SupabaseFleetTransport._(this._client, this.userId);

  @override
  String? get backendUrl => TankSyncClient.backendHost;

  /// The transport for the current session, or `null` when the client
  /// is not initialised / no user is signed in.
  static FleetTransport? currentOrNull() {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    return SupabaseFleetTransport._(client, userId);
  }

  /// One literal `.from()` per fleet table: the closed set is a property
  /// of the transport (it cannot read anything else), and it is what the
  /// HARD RULE #5 completeness scan keys on.
  SupabaseQueryBuilder _from(String table) => switch (table) {
        FleetTables.organizations => _client.from('fleet_organizations'),
        FleetTables.members => _client.from('fleet_members'),
        FleetTables.vehicles => _client.from('fleet_vehicles'),
        FleetTables.assignments => _client.from('vehicle_assignments'),
        FleetTables.policies => _client.from('fleet_policies'),
        _ => throw ArgumentError.value(table, 'table', 'not a fleet table'),
      };

  @override
  Future<List<JsonRow>> selectOrg(
    String table,
    String columns, {
    required String orgId,
  }) async {
    _fence();
    final orgColumn = table == FleetTables.organizations ? 'id' : 'org_id';
    final rows = await _from(table).select(columns).eq(orgColumn, orgId);
    return List<JsonRow>.from(rows);
  }

  @override
  Future<List<JsonRow>> selectOwn(String table, String columns) async {
    if (!FleetTables.userLinked.contains(table)) {
      throw ArgumentError.value(table, 'table', 'not a user-linked table');
    }
    _fence();
    final rows = await _from(table).select(columns).eq('user_id', userId);
    return List<JsonRow>.from(rows);
  }

  @override
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) {
    _fence();
    return _client.rpc<dynamic>(fn, params: params);
  }

  /// #4337 — refuse to touch a client that is no longer the live one.
  void _fence() {
    if (!identical(TankSyncClient.client, _client)) {
      throw const SyncFencedException();
    }
  }
}
