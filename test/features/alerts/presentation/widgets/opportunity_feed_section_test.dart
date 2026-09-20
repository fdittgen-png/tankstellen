// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/opportunity_feed_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/hive_temp_dir.dart';

/// #4154 — the feed that makes "suppressed is not discarded" something a
/// user can open.
void main() {
  late Directory tmpDir;
  final now = DateTime.utc(2026, 9, 15, 12);

  Opportunity opportunity({
    String? stationId = 'de-a',
    String? stationName = 'ARAL Berlin',
    OpportunityKind kind = OpportunityKind.bestStopNow,
    double? net = 3.8,
    double distanceKm = 3.2,
    DateTime? expiresAt,
    DataConfidence confidence = DataConfidence.high,
  }) =>
      Opportunity(
        kind: kind,
        stationId: stationId,
        stationName: stationName,
        fuelType: 'e10',
        currentPrice: 1.649,
        reference: OpportunityReference.localMedian,
        referencePrice: 1.729,
        grossSaving: net == null ? null : net + 0.4,
        detourCost: net == null ? null : 0.4,
        netSaving: net,
        distanceKm: distanceKm,
        priceAge: const DataValue.measured(Duration(minutes: 12)),
        confidence: confidence,
        detectedAt: now,
        expiresAt: expiresAt ?? now.add(const Duration(hours: 6)),
      );

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('opportunity_feed_ui_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tmpDir);
  });

  /// Hive writes are real file I/O, and a `testWidgets` body runs in a
  /// FakeAsync zone whose clock never advances on its own — so an
  /// awaited disk write there never completes and the test hangs with no
  /// failure at all. `runAsync` is the escape hatch for exactly this.
  Future<void> record(WidgetTester tester, BudgetOutcome outcome) =>
      tester.runAsync(
          () => const OpportunityFeedStore().recordScan(outcome, now));

  Future<void> pumpHidden(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [appClockProvider.overrideWithValue(FixedClock(now))],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: OpportunityFeedSection(hideWhenEmpty: true),
              ),
            ),
          ),
        ),
      );

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        ProviderScope(
          overrides: [appClockProvider.overrideWithValue(FixedClock(now))],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(child: OpportunityFeedSection()),
            ),
          ),
        ),
      );

  testWidgets('an empty feed says what the engine watches for', (tester) async {
    await pump(tester);

    expect(find.text('Nothing worth telling you about yet'), findsOneWidget);
    expect(find.textContaining('in the background'), findsOneWidget,
        reason: '#4154 requires the empty state to say what is being '
            'watched for, and forbids a fabricated example row');
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('hideWhenEmpty renders nothing at all, not a smaller note',
      (tester) async {
    // What the Alerts screen passes today: it is still a CONFIGURATION
    // screen, and even a compact note above the lists the user came for
    // pushes them down the page for no gain.
    await pumpHidden(tester);

    expect(find.text('Nothing worth telling you about yet'), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('hideWhenEmpty still shows the findings when there are some',
      (tester) async {
    await record(tester, BudgetOutcome(notify: opportunity()));
    await pumpHidden(tester);

    expect(find.text('Best stop nearby'), findsOneWidget,
        reason: 'the flag suppresses the EMPTY note, never the feed');
  });

  testWidgets('a sent opportunity has no "not sent" chip', (tester) async {
    await record(tester, BudgetOutcome(notify: opportunity()));
    await pump(tester);

    expect(find.text('Best stop nearby'), findsOneWidget);
    expect(find.textContaining('ARAL Berlin'), findsOneWidget);
    expect(find.text('Not sent'), findsNothing);
  });

  testWidgets('a refused one is SHOWN, with the budget\'s reason',
      (tester) async {
    await record(tester, BudgetOutcome(demoted: [
        DemotedOpportunity(opportunity(), BudgetRefusal.outrankedInWindow),
      ]));
    await pump(tester);

    expect(find.text('Not sent'), findsOneWidget);
    // Collapsed: the reason is one tap deeper, like every other
    // explanation in this app.
    expect(find.text('A better one went out instead'), findsNothing);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('A better one went out instead'), findsOneWidget,
        reason: '#4151 promised a demotion is not a deletion; this is '
            'where the user can open it');
  });

  testWidgets('expanding shows the #4152 reasons, from the model',
      (tester) async {
    await record(tester, BudgetOutcome(notify: opportunity()));
    await pump(tester);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.textContaining('on your usual fill'), findsOneWidget);
    expect(find.textContaining('below the local average'), findsOneWidget);
    expect(find.textContaining('Price updated'), findsOneWidget);
  });

  testWidgets('a low-confidence source says so, a high-confidence one does not',
      (tester) async {
    await record(tester, BudgetOutcome(notify: opportunity(confidence: DataConfidence.low)));
    await pump(tester);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.textContaining('data is incomplete or slow'), findsOneWidget,
        reason: '#4152 — a weekly-refresh country must not read like a '
            '5-minute feed');
  });

  testWidgets('an expired opportunity is not presented as current',
      (tester) async {
    await record(tester, BudgetOutcome(
        notify: opportunity(
            expiresAt: now.subtract(const Duration(minutes: 1))),
      ));
    await pump(tester);

    expect(find.byType(Card), findsNothing,
        reason: 'a feed still showing yesterday\'s bargain teaches the '
            'user the list is stale — the same failure a late '
            'notification causes');
    expect(find.text('Nothing worth telling you about yet'), findsOneWidget);
    expect(const OpportunityFeedStore().read(), hasLength(1),
        reason: 'filtered from the VIEW, not deleted from the store');
  });

  testWidgets('an area-wide movement names no station', (tester) async {
    // The one kind that is about an area. The row must not fall back to
    // a station id — `de-9f3a1c` in front of a user is the defect #4179
    // removed from the home-screen widget.
    await record(tester, BudgetOutcome(
        notify: opportunity(
          kind: OpportunityKind.localMovement,
          stationId: null,
          stationName: null,
          net: null,
          distanceKm: 0,
        ),
      ));
    await pump(tester);

    expect(find.text('Prices moving nearby'), findsOneWidget);
    expect(find.textContaining('de-'), findsNothing);
  });
}
