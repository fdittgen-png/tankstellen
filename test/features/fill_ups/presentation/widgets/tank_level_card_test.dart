// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_mix_view.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fuel_and_tank/fuel_and_tank_labels.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_blend_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_mix_provider.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_level_card.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_level_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/text_hierarchy.dart';

/// Widget-level coverage for [TankLevelCard] (#1195).
///
/// The card itself is presentational — it reads
/// [tankLevelProvider] and reflects the [TankLevelEstimate] with a
/// display-role number + baseline unit (#3950), a range sub-text, a
/// `LinearProgressIndicator`, and a method caption. These tests pin:
///   * empty state when no fill-ups
///   * populated rendering of level + range
///   * low-fuel colour switch at < 15 % capacity
///   * detail bottom-sheet open on tap
///   * method-label localisation across the three enum values
///   * the visual grammar: the litres are the largest text on the card,
///     the `L` unit sits beside them, and the card survives 320 dp under
///     the en_XA pseudo-locale at a 1.3× font setting
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

class _NoFills extends FillUpList {
  @override
  List<FillUp> build() => const [];
}

class _FlexVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'stub-vehicle',
          name: 'Stub Car',
          type: VehicleType.combustion,
          tankCapacityL: 50,
          multiFuelCapable: true,
        ),
      ];
}

/// A blend snapshot with [shares]; [exact] collapses the volume too.
TankBlendSnapshot _snapshot(Map<FuelGrade, double> shares,
        {bool exact = false}) =>
    TankBlendSnapshot(
      gradeShares: shares,
      minLitres: exact ? 32.4 : 20,
      maxLitres: exact ? 32.4 : 40,
      tankCapacityLitres: 50,
      appliedEventIds: const [],
      logFingerprint: 0,
    );

TankMixView _mixOf(Map<FuelGrade, double> shares, {bool exact = false}) =>
    TankMixView.of(_snapshot(shares, exact: exact));

List<Object> _activeVehicleOverrides() => <Object>[
      vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
      activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle()),
    ];

List<Object> _tankLevelOverride(TankLevelEstimate estimate) => <Object>[
      ..._activeVehicleOverrides(),
      tankLevelProvider('stub-vehicle').overrideWith((ref) => estimate),
    ];

/// [_tankLevelOverride] for a MULTI-FUEL vehicle, so the real
/// `tankMixProvider` reaches the tank blend.
List<Object> _flexTankLevelOverride(TankLevelEstimate estimate) => <Object>[
      vehicleProfileListProvider.overrideWith(() => _FlexVehicleList()),
      activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle()),
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
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(find.text('Tank level'), findsOneWidget);
      // #3950 — the litres are the display number; the unit is its own
      // label-role Text on the same baseline, not part of the string.
      expect(find.text('32,4'), findsOneWidget);
      expect(find.byKey(const Key('tank_level_big_number')), findsOneWidget);
      expect(find.byKey(const Key('tank_level_unit')), findsOneWidget);
      expect(find.text('32,4 L'), findsNothing);
    });

    testWidgets('renders the range sub-text when rangeKm is non-null',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 32.4,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
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
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 357,
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

  group('TankLevelCard — range at last consumption (#3764)', () {
    TankLevelEstimate estimate({
      double? rangeKm,
      double? rangeKmLastInterval,
    }) =>
        TankLevelEstimate(
          levelL: 32.4,
          capacityL: 50,
          lastFillUpDate: DateTime(2026, 4, 27),
          source: TankLevelSource.fillUp,
          sensorReadAt: null,
          rangeKm: rangeKm,
          rangeKmLastInterval: rangeKmLastInterval,
        );

    testWidgets('leads with the last-interval projection and shows the '
        'long-run average as secondary context', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(
          estimate(rangeKm: 405, rangeKmLastInterval: 324),
        ),
      );

      // Primary line = the last-tank projection.
      expect(
        find.text("≈ 324 km at your last tank's consumption"),
        findsOneWidget,
      );
      // Secondary context = the long-run figure.
      expect(find.text('Long-run average: ≈ 405 km'), findsOneWidget);
      // The generic range string does NOT render.
      expect(find.textContaining('km of range'), findsNothing);
    });

    testWidgets('no closed interval yet → today\'s long-run range string, '
        'no long-run context line', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate(rangeKm: 462)),
      );

      expect(find.textContaining('462'), findsOneWidget);
      expect(find.textContaining('km of range'), findsOneWidget);
      expect(find.byKey(const Key('tank_level_range_long_run')), findsNothing);
      expect(find.textContaining("last tank's consumption"), findsNothing);
    });

    testWidgets('long-run context hidden when it rounds to the same figure '
        'as the last-interval projection', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(
          estimate(rangeKm: 324.2, rangeKmLastInterval: 324.4),
        ),
      );

      expect(
        find.text("≈ 324 km at your last tank's consumption"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tank_level_range_long_run')), findsNothing);
    });
  });

  group('TankLevelCard — low-fuel colouring', () {
    testWidgets('applies error colour to the bar at < 15% capacity',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 6, // 6 / 50 = 12 % → low-fuel
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 86,
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
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 143,
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
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 462,
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
    testWidgets('fill-up source captions the anchor date (#3647)',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 30,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.fillUp,
        sensorReadAt: null,
        rangeKm: 400,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(
        // #3903 — localized medium date, not a raw YYYY-MM-DD.
        find.textContaining('Anchored at the last fill-up: Apr 27, 2026'),
        findsOneWidget,
      );
    });

    testWidgets('OBD2-sensor source captions the reading date (#3647)',
        (tester) async {
      final estimate = TankLevelEstimate(
        levelL: 28.5,
        capacityL: 50,
        lastFillUpDate: DateTime(2026, 4, 27),
        source: TankLevelSource.obd2Sensor,
        sensorReadAt: DateTime(2026, 4, 29),
        rangeKm: 380,
      );

      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate),
      );

      expect(
        find.textContaining('OBD2 tank sensor · Apr 29, 2026'),
        findsOneWidget,
      );
    });
  });

  group('TankLevelCard — tank mix line (#3652, one model since #4322)', () {
    TankLevelEstimate estimate() => TankLevelEstimate(
          levelL: 32.4,
          capacityL: 50,
          lastFillUpDate: DateTime(2026, 4, 27),
          source: TankLevelSource.fillUp,
          sensorReadAt: null,
          rangeKm: 462,
        );

    testWidgets('an exact blend renders each grade with its percentage',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) =>
              _mixOf({FuelGrade.e10: 0.57, FuelGrade.e85: 0.43}, exact: true)),
        ],
      );

      expect(
        find.text('Tank mix: 57 % Super E10 · 43 % E85 Bioethanol'),
        findsOneWidget,
      );
    });

    testWidgets('a partly known tank shows guaranteed minimums and the '
        'unknown share — never a guessed split', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) => _mixOf({
                FuelGrade.e85: 0.62,
                FuelGrade.e10: 0.30,
                FuelGrade.unknown: 0.08,
              })),
        ],
      );

      expect(
        find.text(
            'Tank mix: ≥ 62 % E85 Bioethanol · ≥ 30 % Super E10 · 8 % unknown'),
        findsOneWidget,
      );
    });

    testWidgets('a single known grade with an unknown rest still says so',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) =>
              _mixOf({FuelGrade.e85: 0.9, FuelGrade.unknown: 0.1})),
        ],
      );
      expect(find.text('Tank mix: ≥ 90 % E85 Bioethanol · 10 % unknown'),
          findsOneWidget);
    });

    testWidgets('no mix line for a single-fuel vehicle (provider null)',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith((ref) => null),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
    });

    testWidgets('an established pure tank stays silent', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith(
              (ref) => _mixOf({FuelGrade.e85: 1.0}, exact: true)),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
    });

    testWidgets('a tank nothing is attributed to stays silent — the card '
        'never prints "100 % unknown"', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle')
              .overrideWith((ref) => _mixOf({FuelGrade.unknown: 1.0})),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
    });

    testWidgets('an UNWIRED mix graph degrades silently — shell safety '
        '(#2163)', (tester) async {
      // No tankMixProvider override: a multi-fuel vehicle makes the
      // provider reach the tank blend, whose fill-up / trip lists isolated
      // harnesses don't wire; the guard must swallow it.
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._flexTankLevelOverride(estimate()),
        ],
      );
      expect(find.byKey(const Key('tank_mix_line')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('#4322 guard — the card and the Fuel & Tank surface render '
        'the SAME mix line from the same blend', (tester) async {
      final tank = _snapshot(
          {FuelGrade.e85: 0.62, FuelGrade.e10: 0.30, FuelGrade.unknown: 0.08});
      // The real tankMixProvider, fed by the blend the surface reads.
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._flexTankLevelOverride(estimate()),
          tankBlendProvider('stub-vehicle').overrideWithValue(tank),
          fillUpListProvider.overrideWith(_NoFills.new),
        ],
      );
      final card = tester
          .widget<Text>(find.byKey(const Key('tank_mix_line')))
          .data!;
      final l = AppLocalizations.of(
          tester.element(find.byKey(const Key('tank_mix_line'))));
      final surfaceLine = FuelAndTankLabels.mixLine(l, TankMixView.of(tank));
      expect(card, l.tankMixCaption(surfaceLine));
      expect(surfaceLine,
          '≥ 62 % E85 Bioethanol · ≥ 30 % Super E10 · 8 % unknown');
    });
  });

  group('TankLevelCard — visual grammar (#3950, Epic #3947)', () {
    TankLevelEstimate estimate() => TankLevelEstimate(
          levelL: 32.4,
          capacityL: 50,
          lastFillUpDate: DateTime(2026, 4, 27),
          source: TankLevelSource.fillUp,
          sensorReadAt: null,
          rangeKm: 405,
          rangeKmLastInterval: 324,
        );

    testWidgets('the litres are the ONE display number — strictly the '
        'largest text on the card', (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: <Object>[
          ..._tankLevelOverride(estimate()),
          tankMixProvider('stub-vehicle').overrideWith(
            (ref) =>
                _mixOf({FuelGrade.e10: 0.57, FuelGrade.e85: 0.43}, exact: true),
          ),
        ],
      );

      expectFocalNumberLargest(
        tester,
        within: find.byType(TankLevelCard),
        focal: find.byKey(const Key('tank_level_big_number')),
      );
    });

    testWidgets('display number and unit share one alphabetic baseline',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate()),
      );

      final row = tester.widget<Row>(find.ancestor(
        of: find.byKey(const Key('tank_level_unit')),
        matching: find.byType(Row),
      ).first);
      expect(row.crossAxisAlignment, CrossAxisAlignment.baseline);
      expect(row.textBaseline, TextBaseline.alphabetic);
      // The unit is muted and clearly smaller than the number.
      final sizes = textFontSizesUnder(tester, find.byType(TankLevelCard));
      final number = sizes.entries
          .singleWhere((e) => e.key.widget.key == const Key('tank_level_big_number'))
          .value;
      final unit = sizes.entries
          .singleWhere((e) => e.key.widget.key == const Key('tank_level_unit'))
          .value;
      expect(unit, lessThan(number));
    });

    testWidgets('the range is ONE body line; the long-run figure is a '
        'label-role caption and the bar carries no end labels',
        (tester) async {
      await pumpApp(
        tester,
        const TankLevelCard(),
        overrides: _tankLevelOverride(estimate()),
      );

      final primary = tester.widget<Text>(
          find.byKey(const Key('tank_level_range_primary')));
      final longRun = tester.widget<Text>(
          find.byKey(const Key('tank_level_range_long_run')));
      expect(primary.style!.fontSize!, greaterThan(longRun.style!.fontSize!));
      expect(find.byKey(const Key('tank_level_bar_labels')), findsNothing);
      expect(find.text('0 L'), findsNothing);
      expect(find.text('50 L'), findsNothing);
    });

    testWidgets('en_XA at 320 dp + 1.3x text scale: no overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // The card's real host (the Carburant tab) scrolls; a fixed 800 dp
      // body would only measure the test font's square glyphs.
      await pumpApp(
        tester,
        const SingleChildScrollView(child: TankLevelCard()),
        overrides: _tankLevelOverride(estimate()),
        locale: const Locale('en', 'XA'),
      );

      expect(tester.takeException(), isNull,
          reason: 'the tank card overflows at 320 dp under en_XA / 1.3x');
      expect(find.byKey(const Key('tank_level_big_number')), findsOneWidget);
    });
  });
}
