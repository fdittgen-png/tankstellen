// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/expense_state_machine.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';

/// #4215 (F5) — the expense state machine and the correction history.
///
/// The graph is mutation-checked exhaustively: every one of the 49
/// (from, to) pairs is asserted against the documented edge set, so
/// adding an edge (a shortcut past the employee or past the company)
/// or removing one turns this red.
void main() {
  // A mid-month Wednesday, per the AppClock convention (#3660).
  final pinned = DateTime.utc(2026, 3, 11, 14, 30);
  final machine = ExpenseStateMachine(clock: FixedClock(pinned));

  const fields = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    litres: 50,
    pricePerLitre: 1.7,
    total: Money(amount: 85, currency: 'EUR'),
  );

  Expense expense({ExpenseStatus status = ExpenseStatus.draft}) => Expense(
        id: 'e1',
        orgId: 'org-1',
        userId: 'user-1',
        extracted: fields,
        confirmed: fields,
        importSource: ExpenseImportSource.ocrPhoto,
        status: status,
      );

  /// The graph as ADR 0025 words it, restated here so the assertion
  /// below compares the implementation against the SPEC and not
  /// against itself.
  const documented = <ExpenseStatus, Set<ExpenseStatus>>{
    ExpenseStatus.draft: {ExpenseStatus.needsReview},
    ExpenseStatus.needsReview: {ExpenseStatus.submitted},
    ExpenseStatus.submitted: {ExpenseStatus.approved, ExpenseStatus.rejected},
    ExpenseStatus.approved: {ExpenseStatus.exported},
    ExpenseStatus.rejected: {ExpenseStatus.needsReview},
    ExpenseStatus.exported: {ExpenseStatus.archived},
    ExpenseStatus.archived: <ExpenseStatus>{},
  };

  group('the graph', () {
    test('draft → approved is refused — a receipt is never an approval',
        () {
      final result = machine.transition(expense(),
          to: ExpenseStatus.approved, byUserId: 'user-1');
      expect(result.isAccepted, isFalse);
      expect(result.rejection, ExpenseTransitionRejection.illegalTransition);
      expect(result.expense, isNull);
    });

    test('MUTATION CHECK — every (from, to) pair matches the documented '
        'edge set exactly', () {
      for (final from in ExpenseStatus.values) {
        for (final to in ExpenseStatus.values) {
          expect(
            machine.canTransition(from, to),
            documented[from]!.contains(to),
            reason: '${from.name} → ${to.name} disagrees with ADR 0025',
          );
        }
      }
    });

    test('MUTATION CHECK — every illegal pair is refused by transition(), '
        'not merely by canTransition()', () {
      for (final from in ExpenseStatus.values) {
        for (final to in ExpenseStatus.values) {
          if (from == to || documented[from]!.contains(to)) continue;
          final result = machine.transition(expense(status: from),
              to: to, byUserId: 'user-1');
          expect(result.isAccepted, isFalse,
              reason: '${from.name} → ${to.name} must be refused');
        }
      }
    });

    test('a move to the same status is a no-change, not an illegal move',
        () {
      final result = machine.transition(expense(),
          to: ExpenseStatus.draft, byUserId: 'user-1');
      expect(result.rejection, ExpenseTransitionRejection.noChange);
    });

    test('the whole legal path runs, stamping who and when from the '
        'injected clock', () {
      var current = expense();
      const path = [
        ExpenseStatus.needsReview,
        ExpenseStatus.submitted,
        ExpenseStatus.approved,
        ExpenseStatus.exported,
        ExpenseStatus.archived,
      ];
      for (final to in path) {
        final result =
            machine.transition(current, to: to, byUserId: 'manager-9');
        expect(result.isAccepted, isTrue, reason: 'blocked at ${to.name}');
        current = result.expense!;
      }
      expect(current.status, ExpenseStatus.archived);
      expect(current.history, hasLength(path.length));
      expect(current.history.map((h) => h.to), path);
      expect(current.history.first.from, ExpenseStatus.draft);
      for (final entry in current.history) {
        expect(entry.at, pinned,
            reason: 'the audit trail must not read the wall clock');
        expect(entry.byUserId, 'manager-9');
      }
    });

    test('a rejected claim goes back to review and can be resubmitted', () {
      final rejected = expense(status: ExpenseStatus.rejected);
      final back = machine.transition(rejected,
          to: ExpenseStatus.needsReview,
          byUserId: 'user-1',
          reason: 'missing_vat_line');
      expect(back.isAccepted, isTrue);
      expect(back.expense!.history.single.reason, 'missing_vat_line');
      expect(
          machine
              .transition(back.expense!,
                  to: ExpenseStatus.submitted, byUserId: 'user-1')
              .isAccepted,
          isTrue);
    });
  });

  group('corrections', () {
    test('the employee\'s answer is kept SEPARATELY from the machine read, '
        'with the difference itemised', () {
      final corrected = machine.recordCorrections(
        expense(),
        confirmed: fields.copyWith(litres: 48.2),
        byUserId: 'user-1',
      );

      expect(corrected.extracted.litres, 50,
          reason: 'the OCR read must stay readable for the whole life of '
              'the expense');
      expect(corrected.confirmed.litres, 48.2);
      expect(corrected.wasCorrected, isTrue);
      expect(corrected.corrections, hasLength(1));
      final change = corrected.corrections.single;
      expect(change.field, 'litres');
      expect(change.before, '50.0');
      expect(change.after, '48.2');
      expect(change.correctedAt, pinned);
      expect(change.correctedBy, 'user-1');
    });

    test('a correction does not move the status — confirming a value and '
        'submitting a claim are two decisions', () {
      final corrected = machine.recordCorrections(expense(),
          confirmed: fields.copyWith(litres: 48.2), byUserId: 'user-1');
      expect(corrected.status, ExpenseStatus.draft);
    });

    test('correcting twice appends; nothing in the history is overwritten',
        () {
      final once = machine.recordCorrections(expense(),
          confirmed: fields.copyWith(litres: 48.2), byUserId: 'user-1');
      final twice = machine.recordCorrections(once,
          confirmed: once.confirmed.copyWith(
              total: const Money(amount: 82.0, currency: 'EUR')),
          byUserId: 'user-1');
      expect(twice.corrections.map((c) => c.field), ['litres', 'total']);
      expect(twice.extracted.litres, 50);
    });

    test('an identical answer records nothing', () {
      final same = machine.recordCorrections(expense(),
          confirmed: fields, byUserId: 'user-1');
      expect(same.corrections, isEmpty);
      expect(same.confirmed, fields);
      expect(same.wasCorrected, isFalse);
    });

    test('the history survives a state change', () {
      final corrected = machine.recordCorrections(expense(),
          confirmed: fields.copyWith(litres: 48.2), byUserId: 'user-1');
      final moved = machine.transition(corrected,
          to: ExpenseStatus.needsReview, byUserId: 'user-1');
      expect(moved.expense!.corrections, hasLength(1));
      expect(moved.expense!.extracted.litres, 50);
    });
  });
}
