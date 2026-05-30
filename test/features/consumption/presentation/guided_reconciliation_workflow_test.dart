// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/reconciliation_resolution.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/guided_reconciliation_workflow.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Structural widget coverage of the guided reconciliation workflow
/// (#2442). Asserts the three steps render and that each attribution
/// answer routes to the correct [ReconciliationResolution] — NO golden
/// PNGs (macOS goldens fail Linux CI per project memory).
void main() {
  /// Mutable holder for the resolution captured when the dialog closes —
  /// the dialog resolves asynchronously, so the test reads `.value`
  /// AFTER it drives the flow to completion.
  late _Holder holder;

  /// Pump the workflow inside a button-triggered host so the dialog is
  /// raised on a real Navigator, then open it.
  Future<void> runWorkflow(WidgetTester tester) async {
    holder = _Holder();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                holder.value = await showGuidedReconciliationWorkflow(
                  context: context,
                  pumpedText: '12.0',
                  consumedText: '5.0',
                  gapText: '7.0',
                  gapLiters: 7,
                  defaultDistanceKm: 100,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Step 1 explains the gap (pumped/consumed/difference)',
      (tester) async {
    await runWorkflow(tester);
    expect(find.byKey(const Key('reconcile-step-explain')), findsOneWidget);
    // The pre-formatted numbers are surfaced verbatim.
    expect(find.textContaining('12.0'), findsWidgets);
    expect(find.textContaining('5.0'), findsWidgets);
    expect(find.textContaining('7.0'), findsWidgets);
  });

  testWidgets('advances through all three steps', (tester) async {
    await runWorkflow(tester);
    expect(find.byKey(const Key('reconcile-step-explain')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reconcile-step-attribute')), findsOneWidget);

    // Answer both questions so Next enables, then advance.
    final yes = find.text('Yes');
    await tester.tap(yes.first);
    await tester.pumpAndSettle();
    await tester.tap(yes.last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reconcile-step-gather')), findsOneWidget);
  });

  testWidgets('both answers correct → Path B (virtual trajet)', (tester) async {
    await runWorkflow(tester);
    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    // Fill-ups complete? Yes. All drives recorded? Yes. → by elimination
    // the gap is unrecorded driving → Path B.
    await tester.tap(find.text('Yes').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    // The Path B distance field is shown.
    expect(find.byKey(const Key('reconcile-virtual-distance')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reconcile-apply')));
    await tester.pumpAndSettle();

    expect(holder.value!.path, ReconciliationPath.virtualTrajet);
    expect(holder.value!.virtualDistanceKm, 100);
  });

  testWidgets('fill-ups NOT complete → Path A (correct fill-up)',
      (tester) async {
    await runWorkflow(tester);
    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    // Fill-ups complete? No → Path A.
    await tester.tap(find.text('No').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reconcile-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reconcile-correction-liters')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reconcile-apply')));
    await tester.pumpAndSettle();

    expect(holder.value!.path, ReconciliationPath.correctFillUp);
    expect(holder.value!.correctionLiters, 7);
  });

  testWidgets('Decide later → deferred resolution (nothing chosen)',
      (tester) async {
    await runWorkflow(tester);
    await tester.tap(find.byKey(const Key('reconcile-decide-later')));
    await tester.pumpAndSettle();
    expect(holder.value!.path, ReconciliationPath.deferred);
    expect(holder.value!.correctionLiters, isNull);
    expect(holder.value!.virtualDistanceKm, isNull);
  });

  testWidgets('dismiss (no choice) → deferred resolution', (tester) async {
    await runWorkflow(tester);
    // Tap the scrim to dismiss.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(holder.value!.path, ReconciliationPath.deferred);
  });
}

class _Holder {
  ReconciliationResolution? value;
}
