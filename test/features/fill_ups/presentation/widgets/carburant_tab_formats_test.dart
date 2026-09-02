// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/achievements/domain/achievement.dart';
import 'package:tankstellen/features/achievements/providers/achievements_provider.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_up_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fuel_tab.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_level_card.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_level_provider.dart';
import 'package:tankstellen/features/profile/providers/gamification_enabled_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3903 — Carburant tab formats: localized medium dates, grouped
/// whole-km odometers, tank-bar end labels, the fill-up count as a grid
/// tile, and FAB clearance that follows the consumed safe-area inset.
class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
          tankCapacityL: 35,
        ),
      ];
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
        id: 'stub-vehicle',
        name: 'Stub Car',
        type: VehicleType.combustion,
        tankCapacityL: 35,
      );
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

class _FixedFillUpList extends FillUpList {
  _FixedFillUpList(this._items);
  final List<FillUp> _items;
  @override
  List<FillUp> build() => _items;
}

final _fillUp = FillUp(
  id: 'f1',
  date: DateTime(2026, 8, 21),
  liters: 30.5,
  totalCost: 52.4,
  odometerKm: 122700,
  fuelType: FuelType.e10,
  stationName: 'SUPER U',
);

String _groupSep(String locale) =>
    NumberFormat.decimalPattern(locale).symbols.GROUP_SEP;

void main() {
  silenceErrorLoggerSpool();
  tearDown(() => PriceFormatter.setCountry('FR'));

  group('FillUpCard — localized date + grouped odometer (#3903)', () {
    testWidgets('fr_FR: "21 août 2026 · 122 700 km"', (tester) async {
      PriceFormatter.setCountry('FR');
      await pumpApp(tester, FillUpCard(fillUp: _fillUp),
          locale: const Locale('fr'));
      expect(
        find.text('21 août 2026 · 122${_groupSep('fr_FR')}700 km'),
        findsOneWidget,
      );
      expect(find.textContaining('2026-08-21'), findsNothing);
      expect(find.textContaining('122700'), findsNothing);
    });

    testWidgets('de_DE: "21. Aug. 2026 · 122.700 km"', (tester) async {
      PriceFormatter.setCountry('DE');
      await pumpApp(tester, FillUpCard(fillUp: _fillUp),
          locale: const Locale('de'));
      expect(find.text('21. Aug. 2026 · 122.700 km'), findsOneWidget);
    });

    testWidgets('en_US: "Aug 21, 2026 · 122,700 km"', (tester) async {
      PriceFormatter.setCountry('AU');
      await pumpApp(tester, FillUpCard(fillUp: _fillUp),
          locale: const Locale('en'));
      expect(find.text('Aug 21, 2026 · 122,700 km'), findsOneWidget);
    });
  });

  group('TankLevelCard — bar end labels + localized anchor (#3903)', () {
    final estimate = TankLevelEstimate(
      levelL: 21,
      capacityL: 35,
      lastFillUpDate: DateTime(2026, 8, 21),
      source: TankLevelSource.fillUp,
      sensorReadAt: null,
      rangeKm: 611,
      rangeKmLastInterval: 548,
    );
    List<Object> overrides() => <Object>[
          vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
          activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle()),
          tankLevelProvider('stub-vehicle').overrideWith((ref) => estimate),
        ];

    testWidgets('renders "0 L" … "35 L" under the bar', (tester) async {
      await pumpApp(tester, const TankLevelCard(), overrides: overrides());
      final labels = find.byKey(const Key('tank_level_bar_labels'));
      expect(labels, findsOneWidget);
      expect(find.descendant(of: labels, matching: find.text('0 L')),
          findsOneWidget);
      expect(find.descendant(of: labels, matching: find.text('35 L')),
          findsOneWidget);
    });

    testWidgets('keeps both range figures: a primary sentence and a smaller '
        'secondary line', (tester) async {
      await pumpApp(tester, const TankLevelCard(), overrides: overrides());
      final primary = tester.widget<Text>(
          find.byKey(const Key('tank_level_range_primary')));
      final secondary = tester.widget<Text>(
          find.byKey(const Key('tank_level_range_long_run')));
      expect(primary.data, contains('548'));
      expect(secondary.data, contains('611'));
      expect(primary.style!.fontSize!, greaterThan(secondary.style!.fontSize!));
    });

    testWidgets('fr: the anchor caption carries the French medium date',
        (tester) async {
      await pumpApp(tester, const TankLevelCard(),
          overrides: overrides(), locale: const Locale('fr'));
      expect(find.textContaining('21 août 2026'), findsOneWidget);
      expect(find.textContaining('2026-08-21'), findsNothing);
    });
  });

  group('FuelTab — FAB clearance (#3903)', () {
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    const stats = ConsumptionStats(
      fillUpCount: 1,
      totalLiters: 30.5,
      totalSpent: 52.4,
      totalDistanceKm: 0,
    );
    List<Object> overrides() => [
          achievementsProvider.overrideWithValue(const <EarnedAchievement>[]),
          gamificationEnabledProvider.overrideWithValue(false),
          activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
          fillUpListProvider.overrideWith(() => _FixedFillUpList([_fillUp])),
        ];

    testWidgets('list bottom padding = FAB clearance + the consumed '
        'safe-area inset', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(bottom: 40)),
            child: FuelTab(fillUps: [_fillUp], stats: stats, l: l10nEn),
          ),
        ),
        overrides: overrides(),
      );
      final list = tester.widget<ListView>(find.byType(ListView).first);
      final padding = list.padding!.resolve(TextDirection.ltr);
      expect(padding.bottom, kFabScrollClearance + 40);
      expect(padding.bottom, greaterThanOrEqualTo(56 + 16 + 16 + 40));
    });
  });
}
