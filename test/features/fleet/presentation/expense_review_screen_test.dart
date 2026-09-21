// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/data/fleet_expense_store.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';
import 'package:tankstellen/features/fleet/presentation/screens/expense_list_screen.dart';
import 'package:tankstellen/features/fleet/presentation/screens/expense_review_screen.dart';
import 'package:tankstellen/features/fleet/presentation/widgets/expense_review_fields.dart';
import 'package:tankstellen/features/fleet/providers/fleet_expense_providers.dart';

import '../../../helpers/never_truncates.dart';
import '../../../helpers/pump_app.dart';

/// An in-memory [FleetExpenseStore] — the Hive box is not open in a
/// widget test, and a screen's rendering should not depend on one.
FleetExpenseStore _memoryStore(List<Expense> seed) {
  final rows = <String, String>{
    for (final e in seed) e.id: jsonEncode(e.toJson()),
  };
  return FleetExpenseStore(
    readAll: () => rows,
    persist: (id, json) async => rows[id] = json,
    remove: (id) async => rows.remove(id),
  );
}

/// #4215 (F7) — the review screen at 360 dp, at large text, and in a
/// non-English locale.
///
/// The screen's contract is not "it renders": it is that the employee
/// can tell, at a glance and in their own language, which fields the
/// machine is unsure about and whether one tap is enough. So the
/// assertions are about the GROUPING and the ACTION LABEL, and the
/// three viewport/locale variants exist because a claim about a
/// glance is a claim about layout.
void main() {
  final pinned = DateTime.utc(2026, 3, 11, 14, 30);

  final reconciling = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    occurredAt: pinned,
    fuelApiValue: 'diesel',
    litres: 50,
    pricePerLitre: 1.7,
    total: const Money(amount: 85, currency: 'EUR'),
    vat: const Money(amount: 13.57, currency: 'EUR'),
    vatRate: 19,
  );

  // Same receipt, one digit misread: 50 × 1.70 is 85.00, not 58.00.
  final mismatching = ExtractedReceiptFields(
    stationName: 'Aral Köln',
    occurredAt: pinned,
    fuelApiValue: 'diesel',
    litres: 50,
    pricePerLitre: 1.7,
    total: const Money(amount: 58, currency: 'EUR'),
  );

  // Nothing but a station: every number is missing.
  const sparse = ExtractedReceiptFields(stationName: 'Aral Köln');

  Expense expense(
    ExtractedReceiptFields fields, {
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
        fleetAttribution: FleetAttribution(
          orgId: 'org-1',
          fleetVehicleId: 'veh-9',
          capturedAt: pinned,
        ),
      );

  List<Object> overrides(List<Expense> seed) => [
        fleetExpenseStoreProvider.overrideWithValue(_memoryStore(seed)),
        appClockProvider.overrideWithValue(FixedClock(pinned)),
      ];

  Future<void> pumpReview(
    WidgetTester tester,
    List<Expense> seed, {
    Size size = const Size(360, 800),
    double textScale = 1,
    Locale locale = const Locale('en'),
    String id = 'e1',
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: ExpenseReviewScreen(expenseId: id),
      ),
      overrides: overrides(seed),
      locale: locale,
    );
  }

  group('the grouping', () {
    test('splits on the needsAnswer flag and keeps reading order', () {
      final grouped = groupReviewFields(const [
        (label: 'a', value: '1', needsAnswer: false),
        (label: 'b', value: null, needsAnswer: true),
        (label: 'c', value: '3', needsAnswer: false),
      ]);
      expect(grouped.needsAnswer.map((f) => f.label), ['b']);
      expect(grouped.read.map((f) => f.label), ['a', 'c']);
    });
  });

  testWidgets('a reconciled receipt offers one tap and no confirmation '
      'section at all', (tester) async {
    await pumpReview(tester, [expense(reconciling)]);

    expect(find.text('Confirm and submit'), findsOneWidget);
    expect(find.text('Needs your confirmation'), findsNothing);
    expect(find.text('Read from the document'), findsOneWidget);
    expect(find.textContaining('matches the printed total'), findsOneWidget);
  });

  testWidgets('the screen that submits says what submitting is NOT — '
      'ADR 0025\'s accounting boundary, in the UI', (tester) async {
    await pumpReview(tester, [expense(reconciling)]);

    await tester.scrollUntilVisible(
      find.textContaining('not an accounting record'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('not an accounting record'), findsOneWidget);
    // …and the action stays reachable while that notice is read,
    // because it is pinned rather than at the end of the scroll.
    expect(find.text('Confirm and submit'), findsOneWidget);
  });

  testWidgets('an arithmetic mismatch blocks the tap, says why, and '
      'flags all three numbers rather than guessing which is wrong',
      (tester) async {
    await pumpReview(tester, [expense(mismatching)]);

    expect(find.text('Confirm and submit'), findsNothing);
    expect(find.text('Confirm the highlighted fields first'), findsOneWidget);
    expect(find.text('Needs your confirmation'), findsOneWidget);
    for (final label in const ['Volume', 'Price per litre', 'Total']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('an unread field is shown as "Not read", never as a '
      'plausible zero', (tester) async {
    await pumpReview(tester, [expense(sparse)]);

    expect(find.text('Not read'), findsWidgets);
    expect(find.textContaining('cannot be checked'), findsOneWidget);
    expect(find.text('Confirm the highlighted fields first'), findsOneWidget);
  });

  testWidgets('an id this device does not hold lands on a stated empty '
      'state, not a crash', (tester) async {
    await pumpReview(tester, const [], id: 'nope');

    expect(find.text('This expense is not on this device.'), findsOneWidget);
  });

  testWidgets('an already-submitted expense cannot be submitted twice',
      (tester) async {
    await pumpReview(
        tester, [expense(reconciling, status: ExpenseStatus.submitted)]);

    expect(find.text('Already submitted'), findsOneWidget);
    final button =
        tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
  });

  testWidgets('confirming walks the state machine and persists the '
      'submitted record', (tester) async {
    final store = _memoryStore([expense(reconciling)]);
    await pumpApp(
      tester,
      const ExpenseReviewScreen(expenseId: 'e1'),
      overrides: [
        fleetExpenseStoreProvider.overrideWithValue(store),
        appClockProvider.overrideWithValue(FixedClock(pinned)),
      ],
    );

    await tester.tap(find.text('Confirm and submit'));
    await tester.pumpAndSettle();

    final saved = store.loadAll().single;
    expect(saved.status, ExpenseStatus.submitted);
    expect(saved.history.map((h) => h.to), [
      ExpenseStatus.needsReview,
      ExpenseStatus.submitted,
    ]);
    expect(saved.history.first.at, pinned);
  });

  testWidgets('at 360 dp and 2.0 text scale nothing is truncated',
      (tester) async {
    await pumpReview(tester, [expense(mismatching)], textScale: 2);

    // The body only: an AppBar title is allowed to ellipsize by design,
    // and the claim here is about the review CONTENT staying readable.
    expectNoTextTruncates(tester, within: find.byType(ListView));
  });

  testWidgets('renders in French, with no English island', (tester) async {
    await pumpReview(tester, [expense(reconciling)],
        locale: const Locale('fr'));

    expect(find.text('Vérifier ce ticket'), findsOneWidget);
    expect(find.text('Confirmer et envoyer'), findsOneWidget);
    expect(find.text('Lu sur le document'), findsOneWidget);
    expect(find.text('Confirm and submit'), findsNothing);
    expect(find.text('Read from the document'), findsNothing);
  });

  testWidgets('the list shows each expense with its status, and opens '
      'the review screen', (tester) async {
    await pumpApp(
      tester,
      const ExpenseListScreen(),
      overrides: overrides([
        expense(reconciling, id: 'e1'),
        expense(mismatching, id: 'e2', status: ExpenseStatus.rejected),
      ]),
    );

    expect(find.text('Aral Köln'), findsNWidgets(2));
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('an empty list explains what would fill it', (tester) async {
    await pumpApp(
      tester,
      const ExpenseListScreen(),
      overrides: overrides(const []),
    );

    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.textContaining('Scan a fuel receipt'), findsOneWidget);
  });
}
