// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/sync/entity_sync.dart';
import '../../../core/sync/sync_isolate_decode.dart';
import '../../../core/sync/sync_row_ops.dart';
import '../../../core/sync/sync_transport.dart';
import '../domain/expense.dart';

/// #3451 — top-level PURE `compute()` entrypoint (no Hive, plugins or
/// logging, so it can run on a worker isolate). Behaviour mirrors
/// [SyncRowOps.jsonbDataDecoder]: a missing or corrupt `data` blob maps
/// to `null` and is skipped by the merge.
List<Expense?> decodeFleetExpenseRows(List<Map<String, dynamic>> rows) => [
      for (final row in rows) _decodeExpenseRow(row),
    ];

Expense? _decodeExpenseRow(Map<String, dynamic> row) {
  final data = row['data'];
  if (data is! Map<String, dynamic>) return null;
  try {
    return Expense.fromJson(data);
  } catch (_) {
    return null;
  }
}

/// The `status` value the SERVER column carries for [status] (#4215).
///
/// Two vocabularies on purpose. The blob keeps the Dart enum's
/// `camelCase` spelling because `Expense.toJson` owns it; the COLUMN is
/// snake_case because it is what an RLS policy, an RPC and a future
/// SQL report read — `status <> 'draft'` has to be legible in the
/// policy that enforces it. Keeping the two apart means a rename of the
/// Dart enum cannot silently change a policy predicate.
String expenseStatusColumn(ExpenseStatus status) => switch (status) {
      ExpenseStatus.draft => 'draft',
      ExpenseStatus.needsReview => 'needs_review',
      ExpenseStatus.submitted => 'submitted',
      ExpenseStatus.approved => 'approved',
      ExpenseStatus.rejected => 'rejected',
      ExpenseStatus.exported => 'exported',
      ExpenseStatus.archived => 'archived',
    };

/// The status a server `status` column value names, or `null` when this
/// build does not know it — a newer server vocabulary must not throw on
/// an older client.
ExpenseStatus? expenseStatusFromColumn(String? column) => switch (column) {
      'draft' => ExpenseStatus.draft,
      'needs_review' => ExpenseStatus.needsReview,
      'submitted' => ExpenseStatus.submitted,
      'approved' => ExpenseStatus.approved,
      'rejected' => ExpenseStatus.rejected,
      'exported' => ExpenseStatus.exported,
      'archived' => ExpenseStatus.archived,
      _ => null,
    };

/// The moment [expense] last changed, as the device saw it — the
/// last-write-wins stamp (#3122).
///
/// [Expense] has no `updatedAt` field, and giving it one would be a
/// second source of truth next to the history it already keeps. The
/// stamp is therefore DERIVED from the record's own audit trail: the
/// latest state transition, the latest correction, or — for an expense
/// that has neither yet — the moment its vehicle attribution was
/// frozen. `null` when none of the three exists, which
/// `SyncHelper.lwwSplit` reads as "no opinion" and leaves alone.
DateTime? expenseChangedAt(Expense expense) {
  DateTime? latest;
  void consider(DateTime? candidate) {
    if (candidate == null) return;
    final utc = candidate.toUtc();
    if (latest == null || utc.isAfter(latest!)) latest = utc;
  }

  for (final entry in expense.history) {
    consider(entry.at);
  }
  for (final correction in expense.corrections) {
    consider(correction.correctedAt);
  }
  consider(expense.fleetAttribution?.capturedAt);
  return latest;
}

/// Bidirectional sync of this employee's fleet expenses (#4215).
///
/// A thin codec config over the shared [EntitySync] engine, exactly
/// like `FillUpsSync` — and that it fits at all is the point of ADR
/// 0025's tenancy split. The five #4212 tables belong to the
/// ORGANISATION, so they are pull-only behind `FleetTransport`; an
/// expense belongs to the EMPLOYEE, whose rows the engine's whole
/// contract ("the caller owns every row it writes") already describes.
/// No new engine, no new transport, no new merge rules.
///
/// The row carries the [Expense] as a JSONB blob plus four explicit
/// columns the SERVER needs and the client never reads back:
/// `org_id` (tenancy), `status` (the manager's `status <> 'draft'`
/// policy predicate), `fleet_vehicle_id` and `fill_up_id` (the joins a
/// report will need). The blob stays the single source of truth for
/// everything else.
///
/// **No document bytes.** `Expense` cannot hold an image — only a
/// `documentId` — so an expense syncs, exports and logs without a
/// receipt photo riding along (ADR 0025 "what never leaves the
/// device"). The bytes live in the private bucket
/// `FleetDocumentStore` owns.
class FleetExpensesSync {
  FleetExpensesSync._();

  /// The Supabase table name, in one place.
  static const String table = 'fleet_expenses';

  static final _sync = EntitySync<Expense>(
    table: table,
    logName: 'FleetExpensesSync',
    idColumn: 'id',
    selectColumns: 'id, org_id, status, data, updated_at',
    onConflict: 'user_id,id',
    idOf: (e) => e.id,
    localStamp: expenseChangedAt,
    encode: (e, userId) => {
      'id': e.id,
      'user_id': userId,
      'org_id': e.orgId,
      'fleet_vehicle_id': e.fleetAttribution?.fleetVehicleId,
      'fill_up_id': e.fillUpId,
      'status': expenseStatusColumn(e.status),
      // #3125 — forensic origin stamps ride INSIDE the blob
      // (sync-transparent: decode ignores unknown keys).
      'data': {...e.toJson(), ...SyncRowOps.forensicStamps()},
      'updated_at': SyncRowOps.lwwStamp(expenseChangedAt(e)),
    },
    decode: SyncRowOps.jsonbDataDecoder(
      Expense.fromJson,
      where: 'FleetExpensesSync.merge decode failed',
    ),
    decodeBatch: (rows) => BatchDecode.run(rows, decodeFleetExpenseRows),
  );

  /// Merge [local] with the caller's `fleet_expenses` rows. Returns the
  /// union, fresher side winning for ids present on both (#3122).
  /// Unauthenticated and failure paths return the input unchanged;
  /// [transport] is injectable for tests.
  static Future<List<Expense>> merge(
    List<Expense> local, {
    SyncTransport? transport,
  }) =>
      _sync.merge(local, transport: transport);

  /// Remove one expense from the server, tombstone-first
  /// (#3078/#3123). Silent on failure — the local delete already
  /// happened.
  static Future<void> delete(String expenseId, {SyncTransport? transport}) =>
      _sync.delete(expenseId, transport: transport);
}
