import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/eco_score.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/eco_score_badge.dart';

import '../../../../helpers/pump_app.dart';

EcoScore _score({
  double lp100 = 6.0,
  double avg = 6.0,
  double delta = 0.0,
  EcoScoreDirection direction = EcoScoreDirection.stable,
}) =>
    EcoScore(
      litersPer100Km: lp100,
      rollingAverage: avg,
      deltaPercent: delta,
      direction: direction,
    );

void main() {
  group('EcoScoreBadge rendering', () {
    testWidgets('shows the current L/100 km and delta percentage',
        (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score:
              _score(lp100: 5.4, avg: 6.0, delta: -10, direction: EcoScoreDirection.improving),
        ),
      );
      expect(find.textContaining('5.4 L/100 km'), findsOneWidget);
      expect(find.textContaining('-10%'), findsOneWidget);
    });

    testWidgets('formats a positive delta with a leading + sign',
        (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(
              lp100: 6.6,
              avg: 6.0,
              delta: 10,
              direction: EcoScoreDirection.worsening),
        ),
      );
      expect(find.textContaining('+10%'), findsOneWidget);
    });
  });

  group('EcoScoreBadge colour + icon', () {
    testWidgets('improving → green down-arrow', (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(direction: EcoScoreDirection.improving, delta: -5),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
      expect(icon.color, Colors.green.shade700);
    });

    testWidgets('worsening → orange up-arrow', (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(direction: EcoScoreDirection.worsening, delta: 5),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(icon.color, Colors.orange.shade800);
    });

    testWidgets('stable → neutral forward-arrow', (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(direction: EcoScoreDirection.stable, delta: 1),
        ),
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('EcoScoreBadge a11y + tooltip', () {
    testWidgets('tooltip explains the 3-fill-up comparison window',
        (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(lp100: 5.4, avg: 6.0, delta: -10),
        ),
      );
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('3 fill-ups'));
      expect(tip.message, contains('6.0'));
    });

    testWidgets('Semantics label states both numbers for TalkBack',
        (tester) async {
      await pumpApp(
        tester,
        EcoScoreBadge(
          score: _score(lp100: 5.4, delta: -10),
        ),
      );
      final semantics = tester.getSemantics(find.byType(EcoScoreBadge));
      expect(semantics.label, contains('5.4 L/100 km'));
      expect(semantics.label, contains('-10%'));
    });
  });
}
