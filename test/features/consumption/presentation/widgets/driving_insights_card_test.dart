// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/lessons/driving_lesson.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_insights_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [DrivingInsightsCard] (#1041 phase 2;
/// registry-driven since #2251).
///
/// The card is purely presentational — it takes the registry's already
/// ranked [DrivingLesson]s and turns them into ListTile rows. The tests
/// lock down the localized title, the empty-state copy, and that the
/// card renders the lesson's resolved title / subtitle / trailing
/// verbatim (the rules own the formatting). Ranking lives in the
/// registry's own test file.
DrivingLesson _highRpm({
  double impact = 0.6,
  String title = 'Engine over 3000 RPM (12% of trip): wasted 0.6 L',
  String subtitle = '12% of trip',
  String trailing = '+0.6 L',
}) =>
    DrivingLesson(
      id: 'highRpm',
      impact: impact,
      metricValue: impact,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );

void main() {
  group('DrivingInsightsCard — title', () {
    testWidgets('renders the localized "Top wasteful behaviours" title',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(lessons: []),
      );

      expect(find.text('Top wasteful behaviours'), findsOneWidget);
    });
  });

  group('DrivingInsightsCard — empty state', () {
    testWidgets('renders the empty-state copy when lessons is empty',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(lessons: []),
      );

      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsOneWidget,
      );
    });

    testWidgets('does not render any lesson tiles when lessons is empty',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(lessons: []),
      );

      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('DrivingInsightsCard — populated', () {
    testWidgets('renders one ListTile per lesson', (tester) async {
      final lessons = [
        _highRpm(),
        const DrivingLesson(
          id: 'hardAccel',
          impact: 0.2,
          metricValue: 0.2,
          title: '4 hard accelerations: wasted 0.2 L',
          subtitle: '4% of trip',
          trailing: '+0.2 L',
        ),
        const DrivingLesson(
          id: 'idling',
          impact: 0.1,
          metricValue: 0.1,
          title: 'Idling (8% of trip): wasted 0.1 L',
          subtitle: '8% of trip',
          trailing: '+0.1 L',
        ),
      ];

      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: lessons),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('does not render the empty-state when lessons is non-empty',
        (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_highRpm()]),
      );

      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsNothing,
      );
    });

    testWidgets('renders the lesson title verbatim', (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_highRpm()]),
      );

      expect(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
        findsOneWidget,
      );
    });

    testWidgets('renders the trailing badge from the lesson', (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_highRpm()]),
      );

      expect(find.text('+0.6 L'), findsOneWidget);
    });

    testWidgets('renders the subtitle "{pct}% of trip" beneath each tile',
        (tester) async {
      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: [_highRpm()]),
      );

      expect(find.text('12% of trip'), findsOneWidget);
    });

    testWidgets('preserves lesson order (registry is the source of truth)',
        (tester) async {
      // The card MUST NOT re-sort — the registry owns ranking. Pump the
      // idling lesson first even though its impact is smaller.
      final lessons = [
        const DrivingLesson(
          id: 'idling',
          impact: 0.1,
          metricValue: 0.1,
          title: 'Idling (8% of trip): wasted 0.1 L',
          subtitle: '8% of trip',
          trailing: '+0.1 L',
        ),
        const DrivingLesson(
          id: 'hardAccel',
          impact: 0.9,
          metricValue: 0.9,
          title: '18 hard accelerations: wasted 0.9 L',
          subtitle: '4% of trip',
          trailing: '+0.9 L',
        ),
      ];

      await pumpApp(
        tester,
        DrivingInsightsCard(lessons: lessons),
      );

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles, hasLength(2));
      expect((tiles[0].title as Text).data, contains('Idling'));
      expect((tiles[1].title as Text).data, contains('hard accelerations'));
    });
  });
}
