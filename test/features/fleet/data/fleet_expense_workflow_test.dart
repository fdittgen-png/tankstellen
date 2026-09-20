// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/data/fleet_expense_workflow.dart';
import 'package:tankstellen/features/fleet/data/fleet_review_transport.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/expense_state_machine.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';

import '../../../helpers/silence_error_logger.dart';
import 'fake_fleet_review_transport.dart';

/// #4215 (F7) — the state machine driven across the RPC boundary.
///
/// Two claims, and the second is the interesting one:
///
///  1. `submit` is local: the employee's own row moves without the
///     network, and the ordinary sync carries it.
///  2. `decide` is server-FIRST: a decision the server did not record
///     must not appear on the device. Every refusal path — offline,
///     forbidden, not-submitted, a token the server did not echo —
///     therefore leaves the expense exactly as it was.
void main() {
  silenceErrorLoggerSpool();

  final pinned = DateTime.utc(2026, 3, 11, 14, 30);
  final machine = ExpenseStateMachine(clock: FixedClock(pinned));

  const fields = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    litres: 50,
    pricePerLitre: 1.7,
    total: Money(amount: 85, currency: 'EUR'),
  );

  Expense expense({
    String id = 'e1',
    ExpenseStatus status = ExpenseStatus.draft,
  }) =>
      Expense(
        id: id,
        orgId: 'org-1',
        userId: 'employee-1',
        extracted: fields,
        confirmed: fields,
        importSource: ExpenseImportSource.ocrPhoto,
        status: status,
      );

  Map<String, dynamic> row(Expense e) => {
        'id': e.id,
        'user_id': e.userId,
        'org_id': e.orgId,
        'status': switch (e.status) {
          ExpenseStatus.draft => 'draft',
          ExpenseStatus.needsReview => 'needs_review',
          ExpenseStatus.submitted => 'submitted',
          ExpenseStatus.approved => 'approved',
          ExpenseStatus.rejected => 'rejected',
          ExpenseStatus.exported => 'exported',
          ExpenseStatus.archived => 'archived',
        },
        'data': e.toJson(),
        'updated_at': pinned.toIso8601String(),
      };

  FleetExpenseWorkflow workflow(FakeFleetReviewTransport fake) =>
      FleetExpenseWorkflow(stateMachine: machine, transport: fake);

  group('submit — the employee hands it over', () {
    test('needsReview → submitted, stamped with who and when', () {
      final result = workflow(FakeFleetReviewTransport())
          .submit(expense(status: ExpenseStatus.needsReview),
              byUserId: 'employee-1');
      expect(result.isAccepted, isTrue);
      expect(result.expense!.status, ExpenseStatus.submitted);
      expect(result.expense!.history.single.at, pinned);
      expect(result.expense!.history.single.byUserId, 'employee-1');
    });

    test('a one-tap confirm walks draft → needsReview → submitted, and '
        'records BOTH moves — the shortcut edge still does not exist', () {
      final result = workflow(FakeFleetReviewTransport())
          .confirmAndSubmit(expense(), byUserId: 'employee-1');
      expect(result.expense!.status, ExpenseStatus.submitted);
      expect(
        result.expense!.history.map((h) => (h.from, h.to)),
        [
          (ExpenseStatus.draft, ExpenseStatus.needsReview),
          (ExpenseStatus.needsReview, ExpenseStatus.submitted),
        ],
      );
      expect(machine.canTransition(ExpenseStatus.draft,
          ExpenseStatus.submitted), isFalse,
          reason: 'the convenience must not have widened the graph');
    });

    test('confirming an already-submitted expense changes nothing', () {
      final result = workflow(FakeFleetReviewTransport()).confirmAndSubmit(
          expense(status: ExpenseStatus.submitted),
          byUserId: 'employee-1');
      expect(result.isAccepted, isFalse);
      expect(result.failure, FleetWorkflowFailure.noChange);
    });

    test('submit needs no transport at all — an offline submit is a '
        'submit', () {
      const offline = FleetExpenseWorkflow(
        stateMachine: ExpenseStateMachine(clock: SystemClock()),
      );
      final result = offline.submit(expense(status: ExpenseStatus.needsReview),
          byUserId: 'employee-1');
      expect(result.isAccepted, isTrue);
    });
  });

  group('decide — server first', () {
    test('approves through the RPC and then moves locally', () async {
      final submitted = expense(status: ExpenseStatus.submitted);
      final fake = FakeFleetReviewTransport(rows: [row(submitted)]);

      final result = await workflow(fake).decide(submitted,
          decision: FleetReviewDecision.approved, byUserId: 'manager-1');

      expect(fake.reviewCalls.single.expenseId, 'e1');
      expect(fake.reviewCalls.single.ownerUserId, 'employee-1');
      expect(fake.reviewCalls.single.decision, FleetReviewDecision.approved);
      expect(result.expense!.status, ExpenseStatus.approved);
      expect(result.expense!.history.single.byUserId, 'manager-1');
    });

    test('rejects, and a rejection is not terminal — it can go back to '
        'needsReview', () async {
      final submitted = expense(status: ExpenseStatus.submitted);
      final fake = FakeFleetReviewTransport(rows: [row(submitted)]);

      final rejected = await workflow(fake).decide(submitted,
          decision: FleetReviewDecision.rejected,
          byUserId: 'manager-1',
          reason: 'missing_vat_line');

      expect(rejected.expense!.status, ExpenseStatus.rejected);
      expect(rejected.expense!.history.single.reason, 'missing_vat_line');
      expect(
          machine.canTransition(
              ExpenseStatus.rejected, ExpenseStatus.needsReview),
          isTrue);
    });

    test('a draft is never sent to the RPC at all — the graph refuses '
        'it before the wire does', () async {
      final fake = FakeFleetReviewTransport(rows: [row(expense())]);

      final result = await workflow(fake).decide(expense(),
          decision: FleetReviewDecision.approved, byUserId: 'manager-1');

      expect(result.failure, FleetWorkflowFailure.illegalTransition);
      expect(fake.reviewCalls, isEmpty);
    });

    test('a server refusal leaves the expense UNCHANGED — an approval '
        'the company never made must not show as made', () async {
      final submitted = expense(status: ExpenseStatus.submitted);
      final fake = FakeFleetReviewTransport(rows: [row(submitted)])
        ..isManager = false;

      final result = await workflow(fake).decide(submitted,
          decision: FleetReviewDecision.approved, byUserId: 'employee-2');

      expect(result.isAccepted, isFalse);
      expect(result.failure, FleetWorkflowFailure.serverRefused);
      expect(result.expense, isNull);
    });

    test('an offline wire is a refusal, not a local approval', () async {
      final submitted = expense(status: ExpenseStatus.submitted);
      final fake = FakeFleetReviewTransport(rows: [row(submitted)])
        ..failure = Exception('offline');

      final result = await workflow(fake).decide(submitted,
          decision: FleetReviewDecision.approved, byUserId: 'manager-1');

      expect(result.failure, FleetWorkflowFailure.serverRefused);
    });

    test('no transport and no session is notConnected, not a silent '
        'success', () async {
      const disconnected = FleetExpenseWorkflow(
        stateMachine: ExpenseStateMachine(clock: SystemClock()),
      );
      final result = await disconnected.decide(
          expense(status: ExpenseStatus.submitted),
          decision: FleetReviewDecision.approved,
          byUserId: 'manager-1');
      expect(result.failure, FleetWorkflowFailure.notConnected);
    });
  });

  group('the review queue — a draft never reaches a manager surface', () {
    test('the fake server already withholds drafts (the policy)',
        () async {
      final fake = FakeFleetReviewTransport(rows: [
        row(expense(id: 'e-draft')),
        row(expense(id: 'e-sent', status: ExpenseStatus.submitted)),
      ]);

      final queue = await workflow(fake).reviewQueue('org-1');

      expect(queue.map((e) => e.id), ['e-sent']);
    });

    test('and the CLIENT drops one anyway when a broken server leaks it',
        () async {
      final fake = FakeFleetReviewTransport(
        rows: [
          row(expense(id: 'e-draft')),
          row(expense(id: 'e-sent', status: ExpenseStatus.submitted)),
        ],
        leakDrafts: true,
      );

      final queue = await workflow(fake).reviewQueue('org-1');

      expect(queue.map((e) => e.id), ['e-sent'],
          reason: 'the policy is the enforcement; this is the belt');
    });

    test('another org\'s rows are not in the queue', () async {
      final foreign = row(expense(id: 'e-other',
          status: ExpenseStatus.submitted))
        ..['org_id'] = 'org-2';
      final fake = FakeFleetReviewTransport(rows: [
        foreign,
        row(expense(id: 'e-sent', status: ExpenseStatus.submitted)),
      ]);

      final queue = await workflow(fake).reviewQueue('org-1');

      expect(queue.map((e) => e.id), ['e-sent']);
    });

    test('the COLUMN wins over a stale blob — the RPC writes the column, '
        'so a manager never sees a decision that has been superseded',
        () {
      final stale = expense(id: 'e-stale', status: ExpenseStatus.submitted);
      final decoded = decodeReviewQueue([
        {...row(stale), 'status': 'approved'},
      ]);
      expect(decoded.single.status, ExpenseStatus.approved);
    });

    test('an undecodable row is skipped, and an unknown status is too',
        () {
      final decoded = decodeReviewQueue([
        {'id': 'e-bad', 'status': 'submitted', 'data': 'not-an-object'},
        {'id': 'e-future', 'status': 'quantum', 'data': <String, dynamic>{}},
        row(expense(id: 'e-ok', status: ExpenseStatus.submitted)),
      ]);
      expect(decoded.map((e) => e.id), ['e-ok']);
    });

    test('a wire fault yields an empty queue, never a partial one',
        () async {
      final fake = FakeFleetReviewTransport(rows: [
        row(expense(id: 'e-sent', status: ExpenseStatus.submitted)),
      ])
        ..failure = Exception('offline');
      expect(await workflow(fake).reviewQueue('org-1'), isEmpty);
    });
  });
}
