// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tankstellen/core/sharing/public_file_exporter.dart';
import 'package:tankstellen/features/trips/domain/trip_sample.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/domain/driving_score.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/driving_score/presentation/widgets/driving_analysis_trace_card.dart';
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

Widget _host(
  Set<Feature> features, {
  List<TripSample> samples = const [],
  TripSummary? summary,
}) =>
    ProviderScope(
      overrides: [enabledFeaturesProvider.overrideWithValue(features)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DrivingAnalysisTraceCard(
            summary: summary ?? _summary(),
            score: _score,
            lessons: const [],
            samples: samples,
          ),
        ),
      ),
    );

void main() {
  // The export side effects (Downloads write + share handoff + failure path)
  // are covered by driving_analysis_trace_export_test.dart; that real-IO path
  // does not progress under the testWidgets fake-async clock, so here we only
  // assert the dev-gating and that the action is wired.
  testWidgets('renders nothing unless Feature.debugMode is on', (tester) async {
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
  testWidgets(
    'OBD export action includes kinematic KPIs, typed totals and score evidence',
    (tester) async {
      Map<String, dynamic>? exported;
      final done = Completer<void>.sync();
      debugPublicFileExporterOverride =
          ({required bytes, required fileName, required mimeType}) async {
        exported = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        done.complete();
        return 'content://downloads/$fileName';
      };
      addTearDown(() => debugPublicFileExporterOverride = null);
      final samples = [
        for (var i = 0; i < 31; i++)
          TripSample(
            timestamp: DateTime.utc(2026).add(Duration(seconds: i)),
            speedKmh: 50.0 + i,
            rpm: 2000,
            hAccuracyM: 3,
            fuelRateLPerHour: 4,
            fuelSource: 'speedDensity',
          ),
      ];
      await tester.pumpWidget(
        _host(
          const {Feature.debugMode},
          samples: samples,
          summary: _summary().copyWith(kind: TripKind.gpsPlusObd2),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      await tester.runAsync(() async {
        button.onPressed!();
        await done.future.timeout(const Duration(seconds: 10));
      });
      await tester.pump();
      expect(exported!['gpsFeatures'], isNotNull);
      expect((exported!['kinematicTimeline'] as Map)['rows'], hasLength(31));
      expect((exported!['patternEvidence'] as Map)['modelVersion'], 2);
      expect((exported!['score'] as Map)['calculation'], isNotNull);
      expect(
        (exported!['imu'] as Map)['recordDefinitions'],
        contains('droppedEvents'),
      );
      expect(exported!['mixtureLessonEvidence'], isNotNull);
    },
  );
}
