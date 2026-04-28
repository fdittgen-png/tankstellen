import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/milestone.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/achievements_tab.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/fuel_vs_ev_card.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/milestones_card.dart';

import '../../../../helpers/pump_app.dart';

MilestoneProgress _p(
  String id,
  MilestoneCategory cat, {
  double current = 0,
  double target = 100,
  bool unlocked = false,
}) =>
    MilestoneProgress(
      milestone: Milestone(
        id: id,
        category: cat,
        target: target,
        unit: 'L',
      ),
      current: current,
      unlocked: unlocked,
    );

void main() {
  group('AchievementsTab', () {
    testWidgets('renders MilestonesCard + FuelVsEvCard', (tester) async {
      // Tall viewport so both cards land on-screen.
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(
        tester,
        Builder(
          builder: (context) => AchievementsTab(
            milestones: [
              _p('m1', MilestoneCategory.firstFillUp, unlocked: true),
              _p('m2', MilestoneCategory.litersTracked, current: 40),
            ],
            fuelCo2Kg: 120,
            distanceKm: 1500,
            theme: Theme.of(context),
          ),
        ),
      );

      expect(
        find.byType(MilestonesCard, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byType(FuelVsEvCard, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('renders without throwing on empty milestones',
        (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => AchievementsTab(
            milestones: const [],
            fuelCo2Kg: 0,
            distanceKm: 0,
            theme: Theme.of(context),
          ),
        ),
      );

      expect(find.byType(MilestonesCard), findsOneWidget);
      expect(find.byType(FuelVsEvCard), findsOneWidget);
    });
  });
}
