// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/time/app_clock.dart';
import 'expense.dart';
import 'expense_fields.dart';

/// Why a requested move was refused (#4215). Machine-readable codes,
/// not user-facing text — the UI renders its own message from ARB.
enum ExpenseTransitionRejection {
  /// The graph has no edge from the current status to the requested
  /// one. `draft → approved` is the canonical example.
  illegalTransition,

  /// Source and target are the same; nothing to record.
  noChange,
}

/// The outcome of asking for a state change: either the new expense,
/// or the reason it did not happen.
///
/// A refusal is a value, not an exception. An approval workflow that
/// throws on an illegal move pushes the decision into whichever `catch`
/// is nearest; returning it keeps the decision at the call site.
class ExpenseTransitionResult {
  const ExpenseTransitionResult.accepted(Expense this.expense)
      : rejection = null;

  const ExpenseTransitionResult.rejected(this.rejection) : expense = null;

  /// The expense with its new status and one more history entry, or
  /// null when the move was refused.
  final Expense? expense;

  /// Why it was refused, or null when it was not.
  final ExpenseTransitionRejection? rejection;

  bool get isAccepted => expense != null;
}

/// The only legal way an [Expense] changes status (#4215, ADR 0025).
///
/// ```
/// draft → needsReview → submitted → approved → exported → archived
///                            ↘ rejected ↗ (back to needsReview)
/// ```
///
/// The graph is deliberately narrow, and the narrowness is the feature:
///
///  * **`draft → approved` does not exist.** Neither does any other
///    shortcut past the employee or past the company. A receipt being
///    readable, authentic, and perfectly reconciled still says nothing
///    about reimbursement — ADR 0025's accounting-state boundary is
///    enforced here or nowhere.
///  * **Rejection is not terminal.** `rejected → needsReview` is the
///    one loop, so a refused claim can be fixed and resubmitted
///    without a second document.
///  * **Every move is stamped** with who asked and when, from an
///    INJECTED clock. The audit trail of an approval workflow cannot
///    depend on the wall clock of whichever device ran the code.
///
/// Nothing in this class advances a status on its own. Status changes
/// because somebody asked; [transition] is the only door.
class ExpenseStateMachine {
  const ExpenseStateMachine({required this.clock});

  /// The injected clock every history entry is stamped from.
  final AppClock clock;

  /// The edges of the graph above. A status with an empty set is
  /// terminal.
  static const Map<ExpenseStatus, Set<ExpenseStatus>> legalTransitions = {
    ExpenseStatus.draft: {ExpenseStatus.needsReview},
    ExpenseStatus.needsReview: {ExpenseStatus.submitted},
    ExpenseStatus.submitted: {ExpenseStatus.approved, ExpenseStatus.rejected},
    ExpenseStatus.approved: {ExpenseStatus.exported},
    ExpenseStatus.rejected: {ExpenseStatus.needsReview},
    ExpenseStatus.exported: {ExpenseStatus.archived},
    ExpenseStatus.archived: <ExpenseStatus>{},
  };

  /// Whether the graph has an edge [from] → [to].
  bool canTransition(ExpenseStatus from, ExpenseStatus to) =>
      legalTransitions[from]?.contains(to) ?? false;

  /// Move [expense] to [to] on behalf of [byUserId], or say why not.
  ExpenseTransitionResult transition(
    Expense expense, {
    required ExpenseStatus to,
    required String byUserId,
    String? reason,
  }) {
    final from = expense.status;
    if (from == to) {
      return const ExpenseTransitionResult.rejected(
          ExpenseTransitionRejection.noChange);
    }
    if (!canTransition(from, to)) {
      return const ExpenseTransitionResult.rejected(
          ExpenseTransitionRejection.illegalTransition);
    }
    final entry = ExpenseTransition(
      from: from,
      to: to,
      at: clock.now().toUtc(),
      byUserId: byUserId,
      reason: reason,
    );
    return ExpenseTransitionResult.accepted(
      expense.copyWith(
        status: to,
        history: [...expense.history, entry],
      ),
    );
  }

  /// Record the employee's answer on [expense] without moving it.
  ///
  /// [confirmed] replaces `confirmed`; [extracted] is untouched, and
  /// every field that differs is appended to `corrections` with who
  /// and when. The two halves of #4215's "user correction persists
  /// separately from OCR output" are this method's whole job — which
  /// is why it does not also change the status. Confirming a value and
  /// submitting a claim are two decisions.
  Expense recordCorrections(
    Expense expense, {
    required ExtractedReceiptFields confirmed,
    required String byUserId,
  }) {
    final at = clock.now().toUtc();
    final changes = <FieldCorrection>[
      for (final field in _diffFields(expense.confirmed, confirmed))
        FieldCorrection(
          field: field.name,
          before: field.before,
          after: field.after,
          correctedAt: at,
          correctedBy: byUserId,
        ),
    ];
    if (changes.isEmpty) return expense;
    return expense.copyWith(
      confirmed: confirmed,
      corrections: [...expense.corrections, ...changes],
    );
  }

  /// Field-by-field difference, rendered as strings so one uniform
  /// history shape covers every field type.
  static List<({String name, String? before, String? after})> _diffFields(
    ExtractedReceiptFields before,
    ExtractedReceiptFields after,
  ) {
    final beforeJson = before.toJson();
    final afterJson = after.toJson();
    final names = {...beforeJson.keys, ...afterJson.keys}.toList()..sort();
    return [
      for (final name in names)
        if (_render(beforeJson[name]) != _render(afterJson[name]))
          (
            name: name,
            before: _render(beforeJson[name]),
            after: _render(afterJson[name]),
          ),
    ];
  }

  static String? _render(Object? value) => value?.toString();
}
