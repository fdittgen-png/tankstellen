// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3917 — the "Bilan du plein": every line of the inventory, the
// calibration outcome or its skip reason, the sheet's dismiss button, and
// the Carburant-tab card's scoping to the active vehicle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_unit.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_inventory.dart';
import 'package:tankstellen/features/fill_ups/domain/services/pump_gain_learner.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_inventory_card.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fill_inventory_sheet.dart';
import 'package:tankstellen/features/fill_ups/providers/fill_inventory_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

final _date = DateTime(2026, 9, 1, 9);

FillInventory _inventory({
  bool full = true,
  double? previous = 0.93,
  double? next = 0.72,
  PumpGainSkipReason? skip,
  double coverage = 0.81,
  double recordedKm = 453,
  double? raw = 10.5,
  double? km = 559,
  double? pump = 6.39,
  String vehicleId = 'car',
}) =>
    FillInventory(
      vehicleId: vehicleId,
      fillId: 'f2',
      fillDate: _date,
      fuelKey: 'e85',
      isFullTank: full,
      pumpLiters: 35.7,
      kmSinceLastFull: km,
      pumpLPer100Km: pump,
      coverageShare: coverage,
      recordedKm: recordedKm,
      rawRecordedLPer100Km: raw,
      previousGain: previous,
      newGain: next,
      skipReason: skip,
    );

class _FixedInventory extends LastFillInventory {
  _FixedInventory(this._value);
  final FillInventory? _value;
  @override
  FillInventory? build() => _value;
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._profile);
  final VehicleProfile? _profile;
  @override
  VehicleProfile? build() => _profile;
}

void main() {
  silenceErrorLoggerSpool();

  group('FillInventoryLines', () {
    testWidgets('calibrated full fill: every inventory line + the gain line',
        (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(),
          unit: ConsumptionUnit.lPer100Km,
          tankLevelL: 35.0,
        ),
      );
      expect(find.text('Fill-up summary'), findsOneWidget);
      expect(find.textContaining('Full tank on'), findsOneWidget);
      // Numbers go through UnitFormatter so the assertions hold in any
      // host locale (decimal comma vs point).
      String d(double v, [int digits = 1]) =>
          UnitFormatter.formatDecimal(v, fractionDigits: digits);
      String c(double v) =>
          UnitFormatter.formatConsumptionLocalized(v, ConsumptionUnit.lPer100Km);
      expect(find.text('${d(559, 0)} km since the last full tank'), findsOneWidget);
      expect(find.text('${d(35.7)} L pumped'), findsOneWidget);
      expect(find.text('Pump consumption: ${c(6.39)}'), findsOneWidget);
      expect(find.text('Recorded trips: 81 % of the tank · ${c(10.5)} raw'),
          findsOneWidget);
      // 35 L ÷ 6.39 × 100 ≈ 548 km at pump consumption.
      expect(find.text('Tank now: ${d(35.0)} L · ≈ ${d(547.7, 0)} km at pump consumption'),
          findsOneWidget);
      expect(
          find.text('Pump calibration: ×${d(0.93, 2)} → ×${d(0.72, 2)} (-23 %)'),
          findsOneWidget);
    });

    testWidgets('unit-aware: the pump figure follows the consumption unit',
        (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(),
          unit: ConsumptionUnit.kmPerL,
        ),
      );
      expect(
          find.text('Pump consumption: '
              '${UnitFormatter.formatConsumptionLocalized(6.39, ConsumptionUnit.kmPerL)}'),
          findsOneWidget);
      expect(find.textContaining('Tank now'), findsNothing,
          reason: 'no tank level → no line');
    });

    testWidgets('skipped: coverage too low, with the reason', (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(
            previous: null,
            next: null,
            skip: PumpGainSkipReason.coverageTooLow,
            coverage: 0.42,
          ),
          unit: ConsumptionUnit.lPer100Km,
        ),
      );
      expect(
        find.text('Pump calibration: skipped — recorded trips cover 42 % '
            'of the tank (60 % needed)'),
        findsOneWidget,
      );
    });

    testWidgets('skipped: first full tank has no window and no km line',
        (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(
            previous: null,
            next: null,
            skip: PumpGainSkipReason.noWindow,
            km: null,
            pump: null,
            raw: null,
            recordedKm: 0,
            coverage: 0,
          ),
          unit: ConsumptionUnit.lPer100Km,
        ),
      );
      expect(find.textContaining('since the last full tank'), findsNothing);
      expect(find.textContaining('Pump consumption'), findsNothing);
      expect(
        find.text('Pump calibration: skipped — first full tank (no window '
            'closed yet)'),
        findsOneWidget,
      );
    });

    testWidgets('skipped: partial fill, recorded distance too short',
        (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(
            full: false,
            previous: null,
            next: null,
            skip: PumpGainSkipReason.recordedTooShort,
            recordedKm: 18,
          ),
          unit: ConsumptionUnit.lPer100Km,
        ),
      );
      expect(find.textContaining('Partial fill on'), findsOneWidget);
      expect(
        find.text('Pump calibration: skipped — only 18 recorded km (40 km needed)'),
        findsOneWidget,
      );
    });

    testWidgets('a window without recordings says so', (tester) async {
      await pumpApp(
        tester,
        FillInventoryLines(
          inventory: _inventory(
            previous: null,
            next: null,
            skip: PumpGainSkipReason.recordedTooShort,
            recordedKm: 0,
            raw: null,
            coverage: 0,
          ),
          unit: ConsumptionUnit.lPer100Km,
        ),
      );
      expect(find.text('No recorded trip in this tank'), findsOneWidget);
    });

    test('rangeAtPumpConsumption', () {
      expect(FillInventoryLines.rangeAtPumpConsumption(35, 7), closeTo(500, 1e-9));
      expect(FillInventoryLines.rangeAtPumpConsumption(null, 7), isNull);
      expect(FillInventoryLines.rangeAtPumpConsumption(35, 0), isNull);
    });
  });

  group('FillInventorySheet', () {
    testWidgets('renders the content and dismisses', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showFillInventorySheet(context, _inventory()),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fillInventorySheetContent')), findsOneWidget);
      expect(find.byKey(const Key('fillInventoryCalibrationLine')), findsOneWidget);
      await tester.tap(find.byKey(const Key('fillInventoryDismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fillInventorySheetContent')), findsNothing);
    });
  });

  group('FillInventoryCard', () {
    testWidgets('hidden without an inventory', (tester) async {
      await pumpApp(
        tester,
        const FillInventoryCard(),
        overrides: [
          lastFillInventoryProvider.overrideWith(() => _FixedInventory(null)),
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(null)),
        ],
      );
      expect(find.byKey(const Key('fillInventoryCard')), findsNothing);
    });

    testWidgets('hidden when the inventory belongs to another vehicle',
        (tester) async {
      await pumpApp(
        tester,
        const FillInventoryCard(),
        overrides: [
          lastFillInventoryProvider
              .overrideWith(() => _FixedInventory(_inventory(vehicleId: 'other'))),
          activeVehicleProfileProvider.overrideWith(() =>
              _FixedActiveVehicle(const VehicleProfile(id: 'car', name: 'c'))),
        ],
      );
      expect(find.byKey(const Key('fillInventoryCard')), findsNothing);
    });

    testWidgets('shows the last inventory for the active vehicle',
        (tester) async {
      await pumpApp(
        tester,
        const FillInventoryCard(),
        overrides: [
          lastFillInventoryProvider
              .overrideWith(() => _FixedInventory(_inventory())),
          activeVehicleProfileProvider.overrideWith(() =>
              _FixedActiveVehicle(const VehicleProfile(id: 'car', name: 'c'))),
        ],
      );
      expect(find.byKey(const Key('fillInventoryCard')), findsOneWidget);
      expect(find.text('Fill-up summary'), findsOneWidget);
      expect(find.byKey(const Key('fillInventoryCalibrationLine')), findsOneWidget);
    });
  });
}
