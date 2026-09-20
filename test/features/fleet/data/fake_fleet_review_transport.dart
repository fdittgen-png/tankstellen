// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sync/sync_transport.dart' show JsonRow;
import 'package:tankstellen/features/fleet/data/fleet_review_transport.dart';

/// One recorded `fleet_review_expense` call.
typedef ReviewCall = ({
  String expenseId,
  String ownerUserId,
  FleetReviewDecision decision,
});

/// An in-memory [FleetReviewTransport] that behaves like the SERVER,
/// not like the happy path (#4215).
///
/// It enforces the two rules the RPC enforces — the caller must be a
/// manager, and the expense must already be `submitted` — because a
/// fake that says yes to everything is how a client learns to send
/// requests the real backend rejects. The queue it serves applies the
/// policy's `status <> 'draft'` filter for the same reason: a test
/// that never sees a draft arrive cannot prove the client drops one,
/// so the [drafts] flag lets a test make the fake MISBEHAVE and check
/// that the client still refuses to render it.
class FakeFleetReviewTransport implements FleetReviewTransport {
  FakeFleetReviewTransport({
    this.userId = 'manager-1',
    this.isManager = true,
    List<JsonRow>? rows,
    this.leakDrafts = false,
  }) : rows = rows ?? [];

  @override
  String userId;

  /// Whether the caller passes the RPC's role check.
  bool isManager;

  /// The org's rows, as the table holds them (drafts included).
  final List<JsonRow> rows;

  /// When true the fake serves drafts too — modelling a server whose
  /// policy has been broken, so the client's own filter is testable.
  bool leakDrafts;

  final List<String> queueCalls = [];
  final List<ReviewCall> reviewCalls = [];

  /// When set, every call throws it — the offline / refused path.
  Exception? failure;

  @override
  Future<List<JsonRow>> selectReviewQueue(String orgId) async {
    if (failure != null) throw failure!;
    queueCalls.add(orgId);
    return [
      for (final row in rows)
        if (row['org_id'] == orgId &&
            (leakDrafts || row['status'] != 'draft'))
          Map<String, dynamic>.of(row),
    ];
  }

  @override
  Future<String> reviewExpense({
    required String expenseId,
    required String ownerUserId,
    required FleetReviewDecision decision,
  }) async {
    if (failure != null) throw failure!;
    reviewCalls.add((
      expenseId: expenseId,
      ownerUserId: ownerUserId,
      decision: decision,
    ));
    if (!isManager) throw Exception('forbidden');
    final row = rows.firstWhere(
      (r) => r['id'] == expenseId && r['user_id'] == ownerUserId,
      orElse: () => throw Exception('expense_not_found'),
    );
    if (row['status'] != 'submitted') throw Exception('not_submitted');
    row['status'] = decision.token;
    return decision.token;
  }
}
