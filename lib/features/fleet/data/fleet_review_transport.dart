// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/supabase_client.dart';
import '../../../core/sync/sync_transport.dart'
    show JsonRow, SyncFencedException;
import '../domain/expense.dart';
import 'fleet_expenses_sync.dart';

/// What a manager may do to somebody else's expense — the whole list
/// (#4215, ADR 0025 D7).
enum FleetReviewDecision {
  approved,
  rejected;

  /// The token the `fleet_review_expense` RPC accepts. Deliberately the
  /// same spelling as the `status` column, so the wire vocabulary and
  /// the policy predicate cannot drift apart.
  String get token => name;

  /// The status a successful decision leaves the expense in.
  ExpenseStatus get status => this == FleetReviewDecision.approved
      ? ExpenseStatus.approved
      : ExpenseStatus.rejected;
}

/// The manager's read-and-review seam over the org's server data
/// (#4215; widened for the dashboard by #4216).
///
/// Separate from `SyncTransport` on purpose: that seam is scoped to
/// `user_id = auth.uid()` by construction ("a fake can't model
/// cross-user reads the real backend would reject"), and a review queue
/// is precisely a cross-user read. It is also separate from
/// `FleetTransport` (#4212), whose closed table set is the five
/// org-owned tables and whose contract is pull-only.
///
/// Every operation is RLS- and RPC-gated server-side; this interface
/// exists so the workflow above it is testable without a live session,
/// and so production has exactly one place that names the table.
///
/// #4216 widened it rather than adding a fourth seam. The dashboard's
/// read is the same KIND of call as the review queue — a manager
/// reading across an organisation's users, audited server-side — and
/// splitting it off would have left two fakes that could disagree
/// about what a manager is allowed to see.
abstract class FleetReviewTransport {
  /// The authenticated caller.
  String get userId;

  /// The org's expenses a manager may act on.
  ///
  /// The `status <> 'draft'` filter is stated here AS WELL as in the
  /// RLS policy, and the duplication is deliberate: the policy is what
  /// makes a draft unreachable, this filter is what makes the intent
  /// legible at the call site. If they ever disagree the server wins,
  /// which is the right way round.
  Future<List<JsonRow>> selectReviewQueue(String orgId);

  /// `fleet_review_expense(p_id, p_user, p_decision)` — the only write
  /// path onto another employee's expense. Returns the decision token
  /// the server applied.
  Future<String> reviewExpense({
    required String expenseId,
    required String ownerUserId,
    required FleetReviewDecision decision,
  });

  /// `fleet_period_metrics(p_org, p_from, p_to)` — the aggregate-first
  /// manager read (#4216).
  ///
  /// There is no client-side alternative to this call and there must
  /// not be one: the suppression threshold, the role check and the
  /// audit row all live inside the SECURITY DEFINER body, so a
  /// dashboard that assembled the same figures from a table read would
  /// be a dashboard with none of the three.
  Future<List<JsonRow>> selectPeriodMetrics({
    required String orgId,
    required DateTime from,
    required DateTime to,
  });

  /// `fleet_log_export(p_org, p_kind)` — the audit row an export
  /// leaves behind (ADR 0025 D5.4). Returns whether the server
  /// recorded it; an export the trail did not record is an export the
  /// caller must not make.
  Future<bool> logExport({required String orgId, required String kind});
}

/// The production [FleetReviewTransport] over the live
/// [TankSyncClient].
class SupabaseFleetReviewTransport implements FleetReviewTransport {
  SupabaseFleetReviewTransport._(this._client, this.userId);

  final SupabaseClient _client;

  @override
  final String userId;

  /// The transport for the current session, or `null` when the client
  /// is not initialised / nobody is signed in.
  static FleetReviewTransport? currentOrNull() {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    return SupabaseFleetReviewTransport._(client, userId);
  }

  @override
  Future<List<JsonRow>> selectReviewQueue(String orgId) async {
    _fence();
    final rows = await _client
        .from(FleetExpensesSync.table)
        .select('id, user_id, org_id, fleet_vehicle_id, status, data, '
            'updated_at')
        .eq('org_id', orgId)
        .neq('status', expenseStatusColumn(ExpenseStatus.draft));
    return List<JsonRow>.from(rows);
  }

  @override
  Future<String> reviewExpense({
    required String expenseId,
    required String ownerUserId,
    required FleetReviewDecision decision,
  }) async {
    _fence();
    final result = await _client.rpc<dynamic>(
      'fleet_review_expense',
      params: {
        'p_id': expenseId,
        'p_user': ownerUserId,
        'p_decision': decision.token,
      },
    );
    return '$result';
  }

  @override
  Future<List<JsonRow>> selectPeriodMetrics({
    required String orgId,
    required DateTime from,
    required DateTime to,
  }) async {
    _fence();
    final rows = await _client.rpc<dynamic>(
      'fleet_period_metrics',
      params: {
        'p_org': orgId,
        // UTC on the wire, always (#2478's rule for every synced
        // timestamp): a period boundary in local time would move the
        // report by an hour twice a year.
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      },
    );
    return [
      for (final row in rows as List<dynamic>)
        Map<String, dynamic>.from(row as Map),
    ];
  }

  @override
  Future<bool> logExport({
    required String orgId,
    required String kind,
  }) async {
    _fence();
    final result = await _client.rpc<dynamic>(
      'fleet_log_export',
      params: {'p_org': orgId, 'p_kind': kind},
    );
    return result == true;
  }

  /// #4337 — refuse to touch a client that is no longer the live one.
  void _fence() {
    if (!identical(TankSyncClient.client, _client)) {
      throw const SyncFencedException();
    }
  }
}
