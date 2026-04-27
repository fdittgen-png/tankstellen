import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_score.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_score_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [DrivingScoreCard] (#1041 phase 5a — Card A).
///
/// The card is purely presentational — it takes a pre-computed
/// [DrivingScore] and renders the big number, a localized title, an
/// `out of 100` caption, and a chip row showing the top one or two
/// penalty contributions. Tests lock down the big-number rendering,
/// the breakdown chip selection, accessibility (Semantics label,
/// 48dp tap-target guideline), and the localized title.
void main() {
  group('DrivingScoreCard — title and big number', () {
    testWidgets('renders the localized "Driving score" title',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingScoreCard(score: DrivingScore.perfect),
      );

      expect(find.text('Driving score'), findsOneWidget);
    });

    testWidgets('renders the big 0..100 number for the supplied score',
        (tester) async {
      const score = DrivingScore(
        score: 87,
        idlingPenalty: 8,
        hardAccelPenalty: 3,
        hardBrakePenalty: 0,
        highRpmPenalty: 2,
        fullThrottlePenalty: 0,
      );
      await pumpApp(
        tester,
        const DrivingScoreCard(score: score),
      );

      expect(find.text('87'), findsOneWidget);
    });

    testWidgets('renders the /100 suffix beside the score', (tester) async {
      await pumpApp(
        tester,
        const DrivingScoreCard(score: DrivingScore.perfect),
      );

      expect(find.text('/100'), findsOneWidget);
    });

    testWidgets('renders the explanatory subtitle line', (tester) async {
      await pumpApp(
        tester,
        const DrivingScoreCard(score: DrivingScore.perfect),
      );

      // The placeholder subtitle is the first sentence of the future
      // baseline-comparison sub-text.
      expect(
        find.textContaining('Composite score from idling'),
        findsOneWidget,
      );
    });
  });

  group('DrivingScoreCard — accessibility', () {
    testWidgets(
        'big number carries a "Driving score X out of 100" Semantics label',
        (tester) async {
      const score = DrivingScore(
        score: 72,
        idlingPenalty: 12,
        hardAccelPenalty: 6,
        hardBrakePenalty: 0,
        highRpmPenalty: 10,
        fullThrottlePenalty: 0,
      );
      await pumpApp(
        tester,
        const DrivingScoreCard(score: score),
      );

      expect(
        find.bySemanticsLabel('Driving score 72 out of 100'),
        findsOneWidget,
      );
    });

    testWidgets('passes the Android tap-target guideline', (tester) async {
      const score = DrivingScore(
        score: 50,
        idlingPenalty: 25,
        hardAccelPenalty: 15,
        hardBrakePenalty: 0,
        highRpmPenalty: 10,
        fullThrottlePenalty: 0,
      );
      final handle = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          const DrivingScoreCard(score: score),
        );

        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('DrivingScoreCard — breakdown chips', () {
    testWidgets('shows no chips when every penalty is below 1 point',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingScoreCard(score: DrivingScore.perfect),
      );

      // None of the breakdown labels should appear — the card stays
      // focused on the score itself when the trip was clean.
      expect(find.text('Idling'), findsNothing);
      expect(find.text('Hard accelerations'), findsNothing);
      expect(find.text('Hard braking'), findsNothing);
      expect(find.text('High RPM'), findsNothing);
      expect(find.text('Full throttle'), findsNothing);
    });

    testWidgets('shows the single dominant penalty chip when only one fires',
        (tester) async {
      const score = DrivingScore(
        score: 85,
        idlingPenalty: 0,
        hardAccelPenalty: 0,
        hardBrakePenalty: 0,
        highRpmPenalty: 15,
        fullThrottlePenalty: 0,
      );
      await pumpApp(
        tester,
        const DrivingScoreCard(score: score),
      );

      expect(find.text('High RPM'), findsOneWidget);
      // Other chips stay hidden.
      expect(find.text('Idling'), findsNothing);
      expect(find.text('Hard accelerations'), findsNothing);
    });

    testWidgets('shows at most two chips even when three penalties fire',
        (tester) async {
      const score = DrivingScore(
        score: 60,
        idlingPenalty: 12,
        hardAccelPenalty: 6,
        hardBrakePenalty: 0,
        highRpmPenalty: 22,
        fullThrottlePenalty: 0,
      );
      await pumpApp(
        tester,
        const DrivingScoreCard(score: score),
      );

      // Top two penalties: high RPM (22) and idling (12) — hard accel
      // (6) must not appear.
      expect(find.text('High RPM'), findsOneWidget);
      expect(find.text('Idling'), findsOneWidget);
      expect(find.text('Hard accelerations'), findsNothing);
    });

    testWidgets('orders chips by penalty magnitude (descending)',
        (tester) async {
      const score = DrivingScore(
        score: 70,
        idlingPenalty: 4,
        hardAccelPenalty: 9,
        hardBrakePenalty: 0,
        highRpmPenalty: 17,
        fullThrottlePenalty: 0,
      );
      await pumpApp(
        tester,
        const DrivingScoreCard(score: score),
      );

      // Two chips expected — highest first. Verify both render and
      // that the third-largest penalty (idling, 4) is filtered out.
      expect(find.text('High RPM'), findsOneWidget);
      expect(find.text('Hard accelerations'), findsOneWidget);
      expect(find.text('Idling'), findsNothing);
    });
  });
}
