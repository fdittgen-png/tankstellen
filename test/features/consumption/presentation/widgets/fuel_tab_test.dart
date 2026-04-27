import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';
import 'package:tankstellen/features/achievements/presentation/widgets/badge_shelf.dart';
import 'package:tankstellen/features/achievements/providers/achievements_provider.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_tab.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the gamification opt-out gate on [FuelTab] (#1194).
///
/// The Fuel tab embeds a [BadgeShelf] inside its header column. When
/// the gamification toggle is off the shelf must be omitted from the
/// widget tree entirely (not merely hidden) so the consumption screen
/// shows nothing achievement-related.
void main() {
  final fillUps = <FillUp>[
    FillUp(
      id: 'f1',
      date: DateTime(2026, 1, 1),
      liters: 50,
      totalCost: 80,
      odometerKm: 10000,
      fuelType: FuelType.diesel,
    ),
  ];
  const stats = ConsumptionStats(
    fillUpCount: 1,
    totalLiters: 50,
    totalSpent: 80,
    totalDistanceKm: 0,
  );
  final earned = <EarnedAchievement>[
    EarnedAchievement(
      id: AchievementId.firstFillUp,
      earnedAt: DateTime(2026, 1, 2),
    ),
  ];

  List<Object> overrides({required bool gamification}) => [
        achievementsProvider.overrideWithValue(earned),
        gamificationEnabledProvider.overrideWith((ref) => gamification),
        activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
        fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
      ];

  testWidgets('mounts BadgeShelf when gamification is enabled',
      (tester) async {
    await pumpApp(
      tester,
      FuelTab(fillUps: fillUps, stats: stats, l: null),
      overrides: overrides(gamification: true),
    );

    expect(find.byType(BadgeShelf), findsOneWidget);
    // Card from the BadgeShelf renders when at least one badge is earned.
    expect(find.text('Achievements'), findsOneWidget);
  });

  testWidgets('omits BadgeShelf when gamification is disabled',
      (tester) async {
    await pumpApp(
      tester,
      FuelTab(fillUps: fillUps, stats: stats, l: null),
      overrides: overrides(gamification: false),
    );

    expect(find.byType(BadgeShelf), findsNothing);
    // The Achievements heading from the badge shelf must not be in
    // the tree either — that's the user-visible signal that the gate
    // worked.
    expect(find.text('Achievements'), findsNothing);
  });
}

/// Returns null for the active vehicle so [TankLevelCard] short-circuits
/// without trying to read Hive.
class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

/// Static fill-up list so the underlying repository never touches Hive.
class _FixedFillUpList extends FillUpList {
  _FixedFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}
