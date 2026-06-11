// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sync/sync_transport.dart';

/// One recorded [FakeSyncTransport.upsert] call.
class UpsertCall {
  final String table;
  final List<JsonRow> rows;
  final String onConflict;
  UpsertCall(this.table, this.rows, this.onConflict);
}

/// One recorded [FakeSyncTransport.deleteWhere] call.
class DeleteCall {
  final String table;
  final Map<String, Object> filters;
  DeleteCall(this.table, this.filters);
}

/// In-memory [SyncTransport] for unit tests (#3122).
///
/// Serves canned rows from [tables], records every upsert/delete, and
/// applies writes back into [tables] so a second merge in the same test
/// observes the first one's effects (e.g. the #3123 journal drain).
/// Failure flags simulate a network blip per operation kind.
class FakeSyncTransport implements SyncTransport {
  @override
  String userId;

  /// table name → rows currently "on the server".
  final Map<String, List<JsonRow>> tables;

  final List<UpsertCall> upsertCalls = [];
  final List<DeleteCall> deleteCalls = [];

  bool failSelects = false;
  bool failUpserts = false;
  bool failDeletes = false;

  FakeSyncTransport({
    this.userId = 'user-1',
    Map<String, List<JsonRow>>? tables,
  }) : tables = tables ?? {};

  /// Every row upserted into [table] across all recorded calls.
  List<JsonRow> upsertedRows(String table) => [
        for (final call in upsertCalls)
          if (call.table == table) ...call.rows,
      ];

  @override
  Future<List<JsonRow>> select(
    String table,
    String columns, {
    Map<String, Object> filters = const {},
  }) async {
    if (failSelects) throw Exception('FakeSyncTransport: select offline');
    final rows = tables[table] ?? const <JsonRow>[];
    return rows
        .where((row) =>
            filters.entries.every((f) => row[f.key] == f.value))
        .map((row) => Map<String, dynamic>.of(row))
        .toList();
  }

  @override
  Future<void> upsert(
    String table,
    List<JsonRow> rows, {
    required String onConflict,
  }) async {
    if (failUpserts) throw Exception('FakeSyncTransport: upsert offline');
    upsertCalls.add(UpsertCall(table, rows, onConflict));
    final stored = tables.putIfAbsent(table, () => []);
    final keys = onConflict.split(',').map((k) => k.trim()).toList();
    for (final row in rows) {
      stored.removeWhere(
          (existing) => keys.every((k) => existing[k] == row[k]));
      stored.add(Map<String, dynamic>.of(row));
    }
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object> filters) async {
    if (failDeletes) throw Exception('FakeSyncTransport: delete offline');
    deleteCalls.add(DeleteCall(table, filters));
    tables[table]?.removeWhere(
        (row) => filters.entries.every((f) => row[f.key] == f.value));
  }
}
