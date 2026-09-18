// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sync/fleet/fleet_transport.dart';
import 'package:tankstellen/core/sync/sync_transport.dart' show JsonRow;

/// One recorded [FakeFleetTransport.rpc] call.
class FleetRpcCall {
  final String fn;
  final Map<String, dynamic> params;
  FleetRpcCall(this.fn, this.params);
}

/// In-memory [FleetTransport] for unit tests (#4212), modelled on
/// `FakeSyncTransport` (#3122): canned rows per table, a per-operation
/// failure flag, recorded RPC calls.
///
/// It models what RLS would answer, not what the table holds: a test
/// puts into [tables] exactly the rows the caller may see. It enforces
/// the transport's closed table set the same way the production one
/// does, so a test cannot read a non-fleet table through it either.
class FakeFleetTransport implements FleetTransport {
  @override
  String userId;

  @override
  String? backendUrl;

  /// table name → the rows RLS would let this caller see.
  final Map<String, List<JsonRow>> tables;

  final Map<String, dynamic> rpcResults;
  final Map<String, Object> rpcErrors;
  final List<FleetRpcCall> rpcCalls = [];

  bool failSelects = false;

  /// Every (table, filter) pair selected, in order.
  final List<String> selects = [];

  FakeFleetTransport({
    this.userId = 'user-1',
    this.backendUrl = 'https://fleet.example.supabase.co',
    Map<String, List<JsonRow>>? tables,
    Map<String, dynamic>? rpcResults,
    Map<String, Object>? rpcErrors,
  })  : tables = tables ?? {},
        rpcResults = rpcResults ?? {},
        rpcErrors = rpcErrors ?? {};

  @override
  Future<List<JsonRow>> selectOrg(
    String table,
    String columns, {
    required String orgId,
  }) async {
    if (!FleetTables.all.contains(table)) {
      throw ArgumentError.value(table, 'table', 'not a fleet table');
    }
    selects.add('$table@org=$orgId');
    if (failSelects) throw Exception('FakeFleetTransport: select offline');
    final orgColumn = table == FleetTables.organizations ? 'id' : 'org_id';
    return [
      for (final row in tables[table] ?? const <JsonRow>[])
        if (row[orgColumn] == orgId) Map<String, dynamic>.of(row),
    ];
  }

  @override
  Future<List<JsonRow>> selectOwn(String table, String columns) async {
    if (!FleetTables.userLinked.contains(table)) {
      throw ArgumentError.value(table, 'table', 'not a user-linked table');
    }
    selects.add('$table@own');
    if (failSelects) throw Exception('FakeFleetTransport: select offline');
    return [
      for (final row in tables[table] ?? const <JsonRow>[])
        if (row['user_id'] == userId) Map<String, dynamic>.of(row),
    ];
  }

  @override
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) {
    rpcCalls.add(FleetRpcCall(fn, params));
    final error = rpcErrors[fn];
    if (error != null) return Future<dynamic>.error(error);
    return Future<dynamic>.value(rpcResults[fn]);
  }
}
