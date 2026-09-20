// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/sync/sync_transport.dart' show JsonRow;
import '../domain/expense.dart';
import '../domain/expense_state_machine.dart';
import 'fleet_expenses_sync.dart';
import 'fleet_review_transport.dart';

/// Why a workflow step did not happen (#4215). Machine-readable codes,
/// not user-facing text — the UI renders its own wording from ARB.
enum FleetWorkflowFailure {
  /// The device's [ExpenseStateMachine] refused the move (the classic
  /// being `draft → approved`, which does not exist).
  illegalTransition,

  /// Nothing to do: the expense is already in the requested state.
  noChange,

  /// No signed-in session, or no transport for it.
  notConnected,

  /// The server refused or could not be reached. The expense is
  /// UNCHANGED locally — a decision the server did not record must not
  /// show as recorded on the device.
  serverRefused,
}

/// The outcome of a workflow step: the new expense, or why not.
class FleetWorkflowResult {
  const FleetWorkflowResult.accepted(Expense this.expense) : failure = null;

  const FleetWorkflowResult.refused(this.failure) : expense = null;

  /// The expense with its new status and one more history entry.
  final Expense? expense;

  /// Why the step was refused, or null when it was not.
  final FleetWorkflowFailure? failure;

  bool get isAccepted => expense != null;
}

/// The two moves that cross the client/server boundary (#4215).
///
/// [ExpenseStateMachine] owns the graph and the history stamping;
/// [FleetReviewTransport] owns the wire. This class owns the ORDER, and
/// the order is the whole reason it exists:
///
///  * **Submitting** is the employee's own row, so the state machine
///    moves first and the ordinary `EntitySync` upload carries the new
///    status on the next merge. Nothing needs the network to be up.
///  * **Deciding** is somebody else's row, so the RPC goes FIRST and
///    the local transition happens only after the server has said
///    which decision it recorded. A manager whose network dropped must
///    not see an approval the company never made — `serverRefused`
///    leaves the expense exactly as it was.
///
/// The server re-checks the same rule the state machine applies
/// (`submitted →` and nothing else), so neither side is trusting the
/// other: they agree, and a disagreement fails closed.
class FleetExpenseWorkflow {
  const FleetExpenseWorkflow({
    required this.stateMachine,
    this.transport,
  });

  /// The graph and the history stamping — injected with its clock.
  final ExpenseStateMachine stateMachine;

  /// The wire. `null` resolves
  /// [SupabaseFleetReviewTransport.currentOrNull] at call time, so
  /// production passes nothing and a test injects a fake.
  final FleetReviewTransport? transport;

  /// The employee hands [expense] to the company:
  /// `needsReview → submitted`, stamped with who and when.
  ///
  /// Local only by design. The row is the employee's own, so the next
  /// `FleetExpensesSync.merge` uploads it through the ordinary
  /// last-write-wins path; an offline submit is a submit.
  FleetWorkflowResult submit(Expense expense, {required String byUserId}) =>
      _localMove(expense, to: ExpenseStatus.submitted, byUserId: byUserId);

  /// The employee's ONE tap on a reconciled receipt: confirm, then
  /// submit.
  ///
  /// `draft → submitted` is not an edge of the graph, and this does not
  /// add one — it walks `draft → needsReview → submitted`, so the
  /// history records both moves and the state machine stays the only
  /// place that knows the shape. #4215 asks for a single action when
  /// the arithmetic reconciles; it does not ask for a shortcut past
  /// the states, and the two are not the same thing.
  FleetWorkflowResult confirmAndSubmit(
    Expense expense, {
    required String byUserId,
  }) {
    var current = expense;
    if (current.status == ExpenseStatus.draft) {
      final reviewed = _localMove(current,
          to: ExpenseStatus.needsReview, byUserId: byUserId);
      final next = reviewed.expense;
      if (next == null) return reviewed;
      current = next;
    }
    return _localMove(current,
        to: ExpenseStatus.submitted, byUserId: byUserId);
  }

  /// The manager approves or rejects [expense], server first.
  ///
  /// Returns [FleetWorkflowFailure.serverRefused] for every wire-level
  /// outcome — an RPC exception, a decision token the server did not
  /// echo back — and leaves the expense untouched. The RPC's own
  /// snake_case error tokens (`forbidden`, `not_submitted`,
  /// `expense_not_found`) are logged, never shown: the UI renders its
  /// own message from ARB.
  Future<FleetWorkflowResult> decide(
    Expense expense, {
    required FleetReviewDecision decision,
    required String byUserId,
    String? reason,
  }) async {
    final wire = transport ?? SupabaseFleetReviewTransport.currentOrNull();
    if (wire == null) {
      return const FleetWorkflowResult.refused(
          FleetWorkflowFailure.notConnected);
    }
    // Ask the graph BEFORE the wire: an illegal move should not reach
    // the server at all, and the refusal reads the same either way.
    if (!stateMachine.canTransition(expense.status, decision.status)) {
      return FleetWorkflowResult.refused(expense.status == decision.status
          ? FleetWorkflowFailure.noChange
          : FleetWorkflowFailure.illegalTransition);
    }
    final String applied;
    try {
      applied = await wire.reviewExpense(
        expenseId: expense.id,
        ownerUserId: expense.userId,
        decision: decision,
      );
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: {
        'where': 'FleetExpenseWorkflow.decide refused',
        'decision': decision.token,
      });
      return const FleetWorkflowResult.refused(
          FleetWorkflowFailure.serverRefused);
    }
    if (applied != decision.token) {
      log.warn('FleetExpenseWorkflow.decide: server applied "$applied"',
          tag: 'sync', layer: ErrorLayer.sync);
      return const FleetWorkflowResult.refused(
          FleetWorkflowFailure.serverRefused);
    }
    return _localMove(expense,
        to: decision.status, byUserId: byUserId, reason: reason);
  }

  /// The manager's queue for [orgId], newest first — every expense the
  /// server is willing to show them, which by policy excludes drafts.
  ///
  /// Returns an empty list when unconnected or on a wire fault: a
  /// manager surface shows "nothing to review" plus its own offline
  /// state, never a half-filled queue that looks complete.
  Future<List<Expense>> reviewQueue(String orgId) async {
    final wire = transport ?? SupabaseFleetReviewTransport.currentOrNull();
    if (wire == null) return const [];
    final List<JsonRow> rows;
    try {
      rows = await wire.selectReviewQueue(orgId);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync,
          context: const {'where': 'FleetExpenseWorkflow.reviewQueue failed'});
      return const [];
    }
    return decodeReviewQueue(rows);
  }

  FleetWorkflowResult _localMove(
    Expense expense, {
    required ExpenseStatus to,
    required String byUserId,
    String? reason,
  }) {
    final moved = stateMachine.transition(expense,
        to: to, byUserId: byUserId, reason: reason);
    final next = moved.expense;
    if (next == null) {
      return FleetWorkflowResult.refused(
        moved.rejection == ExpenseTransitionRejection.noChange
            ? FleetWorkflowFailure.noChange
            : FleetWorkflowFailure.illegalTransition,
      );
    }
    return FleetWorkflowResult.accepted(next);
  }
}

/// Decode a review-queue payload, dropping anything that is not
/// reviewable (#4215).
///
/// Three filters, and each one is a promise the UI relies on:
///
///  * a row whose `data` blob this build cannot read is skipped rather
///    than shown half-decoded;
///  * a row whose `status` COLUMN says `draft` is dropped even if it
///    somehow arrived — the policy is the enforcement, this is the
///    belt: a draft is never rendered on a manager surface;
///  * the blob's own status is realigned to the column, because the
///    column is what the review RPC and the policy act on. A blob
///    that lags behind an RPC-applied decision would otherwise show
///    the manager a stale state.
List<Expense> decodeReviewQueue(List<JsonRow> rows) {
  final out = <Expense>[];
  for (final row in rows) {
    final data = row['data'];
    if (data is! Map<String, dynamic>) continue;
    final status = expenseStatusFromColumn(row['status'] as String?);
    if (status == null || status == ExpenseStatus.draft) continue;
    final Expense decoded;
    try {
      decoded = Expense.fromJson(data);
    } catch (e, st) {
      log.warn('decodeReviewQueue: undecodable row skipped',
          tag: 'sync', error: e, stack: st, layer: ErrorLayer.sync);
      continue;
    }
    out.add(decoded.status == status
        ? decoded
        : decoded.copyWith(status: status));
  }
  return out;
}
