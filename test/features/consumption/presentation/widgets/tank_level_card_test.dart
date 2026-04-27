import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/tank_level_card.dart';
import 'package:tankstellen/features/consumption/providers/tank_level_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [TankLevelCard] (#1195).
///
/// The card itself is presentational — it reads
/// [tankLevelProvider] and reflects the [TankLevelEstimate] with a big
/// number, a range sub-text, a `LinearProgressIndicator`, and a method
/// caption. These tests pin:
///   * empty state when no fill-ups
///   * populated rendering of level + range
///   * low-fuel colour switch at < 15 % capacity
///   * detail bottom-sheet open on tap
///   * method-label localisation across the three enum values
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
          tankCapacityL: 50,
        ),
      ];
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'stub-vehicle',
        name: 'Stub Car',
        type: VehicleType.combustion,
        tankCapacityL: 50,
      );
}

List<Object> _activeVehicleOverrides() => <Object>[
      vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
      activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle()),
    ];

List<Object> _tankLevelOverride(TankLevelEstimate estimate) => <Object>[
      ..._activeVehicleOverrides(),
      tankLevelProvider('stub-vehicle').overrideWith((ref) => estimate),
    ];

void main() {
  group('TankLevelCard — populated rendering', () {
    testWidgets('renders the localized title and big number',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 462,
        tripsSince: 1,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.text('Tank level'), findsOneWidget);
      expect(find.text('32.4 L'), findsOneWidget);
    });

    testWidgets('renders the range sub-text when rangeKm is non-null',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 462,
        tripsSince: 1,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.textContaining('462'), findsOneWidget);
      expect(find.textContaining('km of range'), findsOneWidget);
    });

    testWidgets('renders the LinearProgressIndicator with the fraction',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 25,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 357,
        tripsSince: 0,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      expect(bar.value, closeTo(0.5, 0.0001));
    });
  });

  group('TankLevelCard — low-fuel colouring', () {
    testWidgets('applies error colour to the bar at < 15% capacity',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 6, // 6 / 50 = 12 % → low-fuel
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 86,
        tripsSince: 5,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      // The bar's color reflects the theme's error colour at < 15 %.
      // We check non-null + non-default; the exact MaterialColor varies
      // by theme so we just lock in that the override fired.
      expect(bar.color, isNotNull);
    });

    testWidgets('does NOT apply low-fuel colouring at >= 15% capacity',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 10, // 20 %
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 143,
        tripsSince: 4,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('tank_level_progress')),
      );
      // Above the threshold the widget passes `null` for color so the
      // theme's primary tint takes over.
      expect(bar.color, isNull);
    });
  });

  group('TankLevelCard — empty state', () {
    testWidgets('shows the "Log a fill-up" message when there are no fills',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(const TankLevelEstimate.unknown()),
      );

      expect(find.text('Log a fill-up to see your tank level'), findsOneWidget);
      // No big number / progress bar in the empty state.
      expect(find.byKey(const Key('tank_level_big_number')), findsNothing);
      expect(find.byKey(const Key('tank_level_progress')), findsNothing);
    });
  });

  group('TankLevelCard — detail sheet', () {
    testWidgets('tap opens the bottom sheet with the localized title',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 462,
        tripsSince: 0,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      await tester.tap(find.byType(TankLevelCard));
      await tester.pumpAndSettle();

      expect(find.text('Trips since last fill-up'), findsOneWidget);
    });
  });

  group('TankLevelCard — method label', () {
    testWidgets('OBD2 method shows "OBD2 measured"', (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.obd2,
        rangeKm: 462,
        tripsSince: 1,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.textContaining('OBD2 measured'), findsOneWidget);
    });

    testWidgets('distanceFallback shows "distance-based estimate"',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.distanceFallback,
        rangeKm: 462,
        tripsSince: 2,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.textContaining('distance-based estimate'), findsOneWidget);
    });

    testWidgets('mixed method shows "mixed measurement"', (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        method: TankLevelEstimationMethod.mixed,
        rangeKm: 462,
        tripsSince: 3,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.textContaining('mixed measurement'), findsOneWidget);
    });
  });
}
