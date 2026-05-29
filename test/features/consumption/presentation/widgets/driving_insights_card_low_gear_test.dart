// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_insights_card.dart';

import '../../../../helpers/pump_app.dart';

/// Card-level coverage for rendering the low-gear lesson
/// (#1263 phase 3, registry-driven since #2251).
///
/// The `> 60s` gate + minute formatting now live in `LowGearRule`
/// (covered by the registry test). These tests pin how the CARD renders
/// a low-gear lesson: a keyed tile with no trailing badge, rendered
/// above the cost-line lessons when both are present.
DrivingLesson _lowGear({int minutes = 3, double seconds = 180}) => DrivingLesson(
      id: 'lowGear',
      impact: 1000,
      metricValue: seconds,
      title: 'Labouring in low gear ($minutes min)',
      // No subtitle / trailing — matches the legacy gear-coaching row.
    );

const _highRpmLesson = DrivingLesson(
  id: 'highRpm',
  impact: 0.6,
  metricValue: 0.6,
  title: 'Engine over 3000 RPM (12% of trip): wasted 0.6 L',
  subtitle: '12% of trip',
  trailing: '+0.6 L',
);

void main() {
  const lowGearKey = ValueKey('insight_tile_lowGear');

  group('DrivingInsightsCard — low-gear lesson rendering', () {
    testWidgets('not rendered when no low-gear lesson is present',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(lessons: []),
      );

      expect(find.byKey(lowGearKey), findsNothing);
      expect(find.textContaining('Labouring'), findsNothing);
    });

    testWidgets('renders the low-gear lesson title', (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_lowGear()]),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(find.text('Labouring in low gear (3 min)'), findsOneWidget);
    });

    testWidgets(
        'when it is the only lesson, no "keep it up" empty-state copy',
        (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_lowGear()]),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsNothing,
      );
    });

    testWidgets(
        'rendered alongside cost-line lessons — gear row first', (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_lowGear(), _highRpmLesson]),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(find.text('Labouring in low gear (3 min)'), findsOneWidget);
      expect(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsNWidgets(2));

      final gearTopLeft = tester.getTopLeft(find.byKey(lowGearKey));
      final insightTopLeft = tester.getTopLeft(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
      );
      expect(gearTopLeft.dy, lessThan(insightTopLeft.dy));
    });

    testWidgets('gear row does NOT carry a trailing "+x L" badge',
        (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_lowGear()]),
      );

      final tile = tester.widget<ListTile>(find.byKey(lowGearKey));
      expect(tile.trailing, isNull);
    });
  });
}
