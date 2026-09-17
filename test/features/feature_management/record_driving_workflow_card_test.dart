// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/widgets/feature_management/record_driving_workflow_card.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/pump_app.dart';
import 'workflow_test_repository.dart';

void main() {
  late WorkflowTestRepository repo;
  setUp(() => repo = WorkflowTestRepository({Feature.gpsTripPath}));

  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    final standard = standardTestOverrides();
    await pumpScaledApp(
      tester,
      const SingleChildScrollView(child: RecordDrivingWorkflowCard()),
      textScaleFactor: scale,
      overrides: [
        ...standard.overrides,
        featureFlagsRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('reviewRecordDrivingWorkflow')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preview and cancellation never write; confirmation enables DAG',
    (tester) async {
      await pump(tester);
      await open(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('including saved preferences'),
        findsOneWidget,
      );
      expect(repo.writes, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      await open(tester);
      await tester.tap(find.byKey(const Key('confirmRecordDrivingWorkflow')));
      await tester.pumpAndSettle();
      expect(
        repo.stored,
        containsAll([
          Feature.obd2TripRecording,
          Feature.showConsumptionTab,
          Feature.gpsTripPath,
        ]),
      );
      expect(repo.writes, 1);
      expect(find.text('Workflow enabled'), findsOneWidget);
      await open(tester);
      expect(
        find.byKey(const Key('confirmRecordDrivingWorkflow')),
        findsNothing,
      );
    },
  );

  testWidgets('changed settings require another preview', (tester) async {
    await pump(tester);
    await open(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RecordDrivingWorkflowCard)),
    );
    await container
        .read(featureFlagsProvider.notifier)
        .enable(Feature.showFuel);
    await tester.tap(find.byKey(const Key('confirmRecordDrivingWorkflow')));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.stored, isNot(contains(Feature.obd2TripRecording)));
    expect(
      find.textContaining('settings changed during review'),
      findsOneWidget,
    );
  });

  testWidgets('storage failure stays inactive and offers retry', (
    tester,
  ) async {
    await pump(tester);
    repo.fail = true;
    await open(tester);
    await tester.tap(find.byKey(const Key('confirmRecordDrivingWorkflow')));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    expect(find.text('Workflow not enabled'), findsOneWidget);
    expect(find.textContaining('Could not finish updating'), findsOneWidget);
  });

  testWidgets('large text retains scrollable review and accessible action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
    await pump(tester, scale: 3);
    await tester.ensureVisible(
      find.byKey(const Key('reviewRecordDrivingWorkflow')),
    );
    await open(tester);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Confirm activation'), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
      isTrue,
    );
    } finally {
      semantics.dispose();
    }
  });
}
