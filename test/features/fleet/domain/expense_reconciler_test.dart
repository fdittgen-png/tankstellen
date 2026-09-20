// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/expense_reconciler.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';

/// #4215 (F5) — the reconciler: does the receipt add up, have we seen
/// it before, and did the employee already log this fill-up?
///
/// The tolerance and the duplicate rule are both mutation-checked: each
/// has a pair of cases either side of its boundary, so widening or
/// narrowing the rule by one step turns one of them red.
void main() {
  const reconciler = ExpenseReconciler();
  final at = DateTime.utc(2026, 3, 11, 14, 30);

  ExtractedReceiptFields fields({
    double? litres = 50.0,
    double? pricePerLitre = 1.70,
    double? total = 85.00,
    String currency = 'EUR',
    DateTime? occurredAt,
    bool dated = true,
    String? stationName = 'Aral Köln',
  }) =>
      ExtractedReceiptFields(
        stationName: stationName,
        occurredAt: dated ? (occurredAt ?? at) : null,
        litres: litres,
        pricePerLitre: pricePerLitre,
        total: total == null ? null : Money(amount: total, currency: currency),
      );

  Expense expense(ExtractedReceiptFields f,
          {String id = 'e1', String? documentId}) =>
      Expense(
        id: id,
        orgId: 'org-1',
        userId: 'user-1',
        extracted: f,
        confirmed: f,
        documentId: documentId,
        importSource: ExpenseImportSource.ocrPhoto,
      );

  // #4215 — the reconciler matches on plain values, not on `FillUp`.
  // Importing the fill_ups barrel here would be harmless in a test, but
  // constructing the real entity would hide that the production type is
  // no longer reachable from fleet (see FillUpMatchCandidate's doc: the
  // fleet feature must stay a leaf so `fill_ups -> fleet` cannot close
  // a cycle).
  FillUpMatchCandidate fillUp({
    String id = 'f1',
    double liters = 50.0,
    DateTime? date,
    String? stationName = 'Aral Köln',
  }) =>
      FillUpMatchCandidate(
        id: id,
        date: date ?? at,
        liters: liters,
        stationName: stationName,
      );

  group('arithmetic', () {
    test('litres × price ≈ total reconciles', () {
      expect(reconciler.checkArithmetic(fields()),
          ExpenseArithmetic.reconciled);
      expect(reconciler.statusForIntake(fields()), ExpenseStatus.draft);
    });

    test('a mismatch moves the receipt to review instead of accepting it',
        () {
      final f = fields(total: 95.00);
      expect(reconciler.checkArithmetic(f), ExpenseArithmetic.mismatch);
      expect(reconciler.statusForIntake(f), ExpenseStatus.needsReview);
    });

    test('a missing number is "incomplete", NOT "agrees" — and still '
        'needs review', () {
      final f = fields(total: null);
      expect(reconciler.checkArithmetic(f), ExpenseArithmetic.incomplete);
      expect(reconciler.statusForIntake(f), ExpenseStatus.needsReview);
    });

    test('a reconciled receipt with no date still needs review — nothing '
        'past draft, and draft needs a when', () {
      final f = fields(dated: false);
      expect(reconciler.statusForIntake(f), ExpenseStatus.needsReview);
    });

    test('MUTATION CHECK — the EUR tolerance is exactly 2 minor units '
        'plus the per-litre rounding, and one cent either side flips it',
        () {
      // 50 L × 1.700 = 85.000; tolerance = 2×0.01 + 50×0.0005 = 0.045.
      expect(ExpenseReconciler.toleranceFor(fields()), closeTo(0.045, 1e-9));
      expect(reconciler.checkArithmetic(fields(total: 85.04)),
          ExpenseArithmetic.reconciled,
          reason: 'a 4-cent gap over 50 L is printing, not a misread');
      expect(reconciler.checkArithmetic(fields(total: 85.05)),
          ExpenseArithmetic.mismatch,
          reason: 'a 5-cent gap is past the rounding budget — widening the '
              'tolerance must fail here');
    });

    test('MUTATION CHECK — the tolerance is CURRENCY-aware: the same '
        'absolute gap passes in CZK and fails in EUR', () {
      final czk = fields(
          litres: 50, pricePerLitre: 38.9, total: 1946.5, currency: 'CZK');
      expect(reconciler.checkArithmetic(czk), ExpenseArithmetic.reconciled,
          reason: 'Czech forecourts print to the whole koruna');
      final eur = fields(litres: 50, pricePerLitre: 38.9, total: 1946.5);
      expect(reconciler.checkArithmetic(eur), ExpenseArithmetic.mismatch,
          reason: 'the same 1.50 gap in euros is a misread — a '
              'currency-blind tolerance would pass both');
    });
  });

  group('fill-up matching', () {
    test('an existing fill-up is attached, never duplicated', () {
      final result = reconciler.intake(expense(fields()),
          fillUps: [fillUp(id: 'fill-7')]);
      expect(result.outcome, ExpenseIntakeOutcome.attachedToFillUp);
      expect(result.expense.fillUpId, 'fill-7');
      expect(result.expense.isAttachedToFillUp, isTrue);
    });

    test('no candidate in the window → a new expense with no fill-up', () {
      final result = reconciler.intake(expense(fields()),
          fillUps: [fillUp(date: at.add(const Duration(days: 3)))]);
      expect(result.outcome, ExpenseIntakeOutcome.created);
      expect(result.expense.fillUpId, isNull);
    });

    test('litres must agree: half a litre matches, two litres do not', () {
      expect(reconciler.findFillUpMatch(fields(), [fillUp(liters: 50.4)]),
          isNotNull);
      expect(reconciler.findFillUpMatch(fields(), [fillUp(liters: 52.0)]),
          isNull);
    });

    test('a named station that disagrees blocks the match; an unnamed one '
        'does not', () {
      expect(
          reconciler
              .findFillUpMatch(fields(), [fillUp(stationName: 'Shell Kiel')]),
          isNull);
      expect(reconciler.findFillUpMatch(fields(), [fillUp(stationName: null)]),
          isNotNull,
          reason: 'most fill-ups are logged with litres and price only');
    });

    test('the closest fill-up in time wins when several qualify', () {
      final match = reconciler.findFillUpMatch(fields(), [
        fillUp(id: 'far', date: at.add(const Duration(hours: 6))),
        fillUp(id: 'near', date: at.add(const Duration(minutes: 4))),
      ]);
      expect(match?.id, 'near');
    });
  });

  group('duplicates', () {
    test('the same document hash attaches to the existing expense', () {
      final stored = expense(fields(), id: 'kept');
      final result = reconciler.intake(
        expense(fields(), id: 'new', documentId: 'doc-2'),
        existing: [(expense: stored, documentSha256: 'abc123')],
        documentSha256: 'abc123',
      );
      expect(result.outcome, ExpenseIntakeOutcome.duplicate);
      expect(result.expense.id, 'kept');
      expect(result.expense.documentId, 'doc-2',
          reason: 'the kept expense had no document, so it adopts this one');
    });

    test('an existing document is never replaced behind the employee', () {
      final stored = expense(fields(), id: 'kept', documentId: 'doc-1');
      final result = reconciler.intake(
        expense(fields(), id: 'new', documentId: 'doc-2'),
        existing: [(expense: stored, documentSha256: 'abc123')],
        documentSha256: 'abc123',
      );
      expect(result.expense.documentId, 'doc-1');
    });

    test('the same purchase photographed twice — different hashes, one '
        'expense', () {
      final stored = expense(fields(), id: 'kept');
      final result = reconciler.intake(
        expense(fields(), id: 'new'),
        existing: [(expense: stored, documentSha256: 'hash-a')],
        documentSha256: 'hash-b',
      );
      expect(result.outcome, ExpenseIntakeOutcome.duplicate);
      expect(result.expense.id, 'kept');
    });

    test('MUTATION CHECK — the field duplicate rule is exact: one cent or '
        'one extra litre makes it a different purchase', () {
      final stored = expense(fields(), id: 'kept');
      final existing = [(expense: stored, documentSha256: 'hash-a')];
      expect(
          reconciler.intake(expense(fields(total: 85.01), id: 'new'),
              existing: existing, documentSha256: 'hash-b').outcome,
          ExpenseIntakeOutcome.duplicate,
          reason: 'one minor unit apart is the same printed total');
      expect(
          reconciler.intake(expense(fields(litres: 51.0), id: 'new'),
              existing: existing, documentSha256: 'hash-b').outcome,
          ExpenseIntakeOutcome.created,
          reason: 'a litre apart is a different fill');
    });

    test('another organisation never matches, whatever the fields say', () {
      final other = expense(fields(), id: 'kept')
          .copyWith(orgId: 'org-2');
      final result = reconciler.intake(
        expense(fields(), id: 'new'),
        existing: [(expense: other, documentSha256: null)],
      );
      expect(result.outcome, ExpenseIntakeOutcome.created);
    });

    test('a duplicate is settled BEFORE a fill-up match, so re-scanning '
        'cannot rewrite the attachment', () {
      final stored = expense(fields(), id: 'kept').copyWith(fillUpId: 'old');
      final result = reconciler.intake(
        expense(fields(), id: 'new'),
        existing: [(expense: stored, documentSha256: 'hash-a')],
        fillUps: [fillUp(id: 'other-fill')],
        documentSha256: 'hash-a',
      );
      expect(result.expense.fillUpId, 'old');
    });
  });

  test('an intake never produces a status past draft', () {
    for (final f in [fields(), fields(total: 95), fields(total: null)]) {
      final status = reconciler.intake(expense(f)).expense.status;
      expect(
          status, anyOf(ExpenseStatus.draft, ExpenseStatus.needsReview),
          reason: 'ADR 0025: receipt presence never sets anything past '
              'draft');
    }
  });
}
