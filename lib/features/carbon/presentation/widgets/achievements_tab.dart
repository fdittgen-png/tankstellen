import 'package:flutter/material.dart';

import '../../domain/milestone.dart';
import 'fuel_vs_ev_card.dart';
import 'milestones_card.dart';

/// Achievements tab of the carbon dashboard. Renders the milestones
/// progress card and the fuel-vs-EV comparison card.
///
/// Extracted from `carbon_dashboard_screen.dart` to keep the screen
/// file under the 300-LOC target (Refs #563).
class AchievementsTab extends StatelessWidget {
  final List<MilestoneProgress> milestones;
  final double fuelCo2Kg;
  final double distanceKm;
  final ThemeData theme;

  const AchievementsTab({
    super.key,
    required this.milestones,
    required this.fuelCo2Kg,
    required this.distanceKm,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      children: [
        MilestonesCard(progress: milestones),
        FuelVsEvCard(fuelCo2Kg: fuelCo2Kg, distanceKm: distanceKm),
      ],
    );
  }
}
