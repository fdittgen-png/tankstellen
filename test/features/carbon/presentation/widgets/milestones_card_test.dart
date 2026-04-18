import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/milestone.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/milestones_card.dart';

import '../../../../helpers/pump_app.dart';

Milestone _m(String id, MilestoneCategory cat,
        {double target = 100, String unit = 'L'}) =>
    Milestone(id: id, category: cat, target: target, unit: unit);

MilestoneProgress _p(Milestone m, {double current = 0, bool unlocked = false}) =>
    MilestoneProgress(milestone: m, current: current, unlocked: unlocked);

void main() {
  group('MilestonesCard', () {
    testWidgets('renders title + one row per progress entry',
        (tester) async {
      final progress = [
        _p(_m('a', MilestoneCategory.firstFillUp), unlocked: true),
        _p(_m('b', MilestoneCategory.litersTracked), current: 40),
        _p(_m('c', MilestoneCategory.co2Tracked), current: 10),
      ];
      await pumpApp(tester, MilestonesCard(progress: progress));

      expect(find.text('Milestones'), findsOneWidget);
      // One row per progress entry → 3 progress indicators (one per row).
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('unlocked entries render a filled check icon',
        (tester) async {
      final progress = [
        _p(_m('a', MilestoneCategory.firstFillUp), unlocked: true),
      ];
      await pumpApp(tester, MilestonesCard(progress: progress));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });

    testWidgets('locked entries render an empty-radio icon',
        (tester) async {
      final progress = [
        _p(_m('a', MilestoneCategory.firstFillUp), unlocked: false),
      ];
      await pumpApp(tester, MilestonesCard(progress: progress));

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('unlocked entries are sorted to the top', (tester) async {
      // Given a mixed list (locked first, unlocked second), the card
      // should display the unlocked row first.
      final locked = _p(_m('locked', MilestoneCategory.litersTracked),
          current: 10);
      final unlocked = _p(_m('unlocked', MilestoneCategory.firstFillUp),
          unlocked: true);
      final progress = [locked, unlocked];

      await pumpApp(tester, MilestonesCard(progress: progress));

      // Locate the two icons and compare their on-screen y-offsets.
      final checkY =
          tester.getCenter(find.byIcon(Icons.check_circle)).dy;
      final uncheckedY =
          tester.getCenter(find.byIcon(Icons.radio_button_unchecked)).dy;
      expect(checkY, lessThan(uncheckedY),
          reason: 'unlocked row should sit above the locked one');
    });

    testWidgets('progress bar reflects fraction', (tester) async {
      final progress = [
        _p(_m('half', MilestoneCategory.litersTracked, target: 100),
            current: 50),
      ];
      await pumpApp(tester, MilestonesCard(progress: progress));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.5, 0.0001));
    });

    testWidgets('progress bar clamps to 1.0 when over-target',
        (tester) async {
      final progress = [
        _p(_m('over', MilestoneCategory.litersTracked, target: 100),
            current: 500),
      ];
      await pumpApp(tester, MilestonesCard(progress: progress));

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
    });

    testWidgets('empty progress list renders just the title',
        (tester) async {
      await pumpApp(
        tester,
        const MilestonesCard(progress: []),
      );
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
