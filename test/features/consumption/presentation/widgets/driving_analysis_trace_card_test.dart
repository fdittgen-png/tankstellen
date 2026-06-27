// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_analysis_trace_card.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

const _score = DrivingScore(
  score: 80,
  idlingPenalty: 0,
  hardAccelPenalty: 0,
  hardBrakePenalty: 0,
  highRpmPenalty: 0,
  fullThrottlePenalty: 0,
);

TripSummary _summary() => const TripSummary(
      distanceKm: 12,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      kind: TripKind.gpsOnly,
    );

Widget _host(Set<Feature> features) => ProviderScope(
      overrides: [enabledFeaturesProvider.overrideWithValue(features)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DrivingAnalysisTraceCard(
            summary: _summary(),
            score: _score,
            lessons: const [],
            samples: const [],
          ),
        ),
      ),
    );

void main() {
  // The export side effects (Downloads write + share handoff + failure path)
  // are covered by driving_analysis_trace_export_test.dart; that real-IO path
  // does not progress under the testWidgets fake-async clock, so here we only
  // assert the dev-gating and that the action is wired.
  testWidgets('renders nothing unless Feature.debugMode is on',
      (tester) async {
    await tester.pumpWidget(_host(const {}));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows a wired export action in debug mode', (tester) async {
    await tester.pumpWidget(_host(const {Feature.debugMode}));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
