// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fuel_tab.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trajets_tab.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';
import 'package:tankstellen/features/achievements/providers/achievements_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2494 — both the Carburant fill-up list and the Trajets trip list float
/// their "add" / "start recording" FAB over the list through the SAME
/// mechanism (`PageScaffold.floatingActionButton`) and reserve the SAME
/// shared [kFabScrollClearance] bottom padding — never the old
/// hand-rolled `Stack + Positioned` that double-counted the system inset.
///
/// These structural assertions lock in the unified path: the tab bodies
/// own no FAB / Stack overlay, and their scrollable list reserves exactly
/// `kFabScrollClearance` at the bottom (no `viewPadding.bottom` added on
/// top).
void main() {
  final AppLocalizations l10nEn = lookupAppLocalizations(const Locale('en'));

  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  EdgeInsets listPadding(WidgetTester tester) {
    final padding =
        tester.widget<ListView>(find.byType(ListView)).padding as EdgeInsets;
    return padding;
  }

  group('FuelTab FAB-over-list clearance', () {
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

    testWidgets(
      'reserves exactly kFabScrollClearance and owns no FAB / Stack',
      (tester) async {
        await pumpApp(
          tester,
          FuelTab(fillUps: fillUps, stats: stats, l: l10nEn),
          overrides: [
            achievementsProvider.overrideWithValue(const <EarnedAchievement>[]),
            gamificationEnabledProvider.overrideWithValue(false),
            activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
            fillUpListProvider.overrideWith(() => _FixedFillUpList(fillUps)),
          ],
        );

        expect(listPadding(tester).bottom, kFabScrollClearance);
        // The FAB is hosted by the Scaffold (PageScaffold) in production, not
        // by the tab body — so the body must not embed its own FAB overlay.
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );
  });

  group('TrajetsTab FAB-over-list clearance', () {
    TripHistoryEntry entry(String id) => TripHistoryEntry(
      id: id,
      vehicleId: 'v1',
      summary: TripSummary(
        distanceKm: 10,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: DateTime(2026, 4, 22, 9),
      ),
    );

    testWidgets(
      'reserves exactly kFabScrollClearance and owns no FAB / Stack',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpApp(
          tester,
          const Scaffold(body: TrajetsTab(vehicleId: null)),
          overrides: [
            tripHistoryListProvider.overrideWith(
              () => _FixedTripHistoryList([entry('trip-a')]),
            ),
            vehicleProfileListProvider.overrideWith(
              () => _FixedVehicleProfileList(const [
                VehicleProfile(
                  id: 'v1',
                  name: 'Daily Driver',
                  type: VehicleType.combustion,
                ),
              ]),
            ),
            activeVehicleProfileProvider.overrideWith(
              () => _FixedActiveVehicle(
                const VehicleProfile(
                  id: 'v1',
                  name: 'Daily Driver',
                  type: VehicleType.combustion,
                ),
              ),
            ),
          ],
        );

        final padding =
            tester
                    .widget<ListView>(find.byKey(const Key('trajets_list')))
                    .padding
                as EdgeInsets;
        expect(padding.bottom, kFabScrollClearance);
        // No hand-rolled overlay inside the tab body — the record FAB lives
        // in the Scaffold FAB slot (TrajetsRecordFab) in production.
        expect(find.byType(FloatingActionButton), findsNothing);
      },
    );
  });
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

class _FixedFillUpList extends FillUpList {
  _FixedFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

class _FixedTripHistoryList extends TripHistoryList {
  _FixedTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

class _FixedVehicleProfileList extends VehicleProfileList {
  _FixedVehicleProfileList(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}
