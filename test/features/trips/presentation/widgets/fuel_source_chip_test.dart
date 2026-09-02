// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3919 — the fuel-source badge (Measured / Estimated · calibrated /
// Estimated / GPS), its "recalculated" tooltip, and its placement on the
// trip row (with the re-expressed figure) and the trip detail header.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/calibrated_trip_figures.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/presentation/widgets/fuel_source_chip.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trajet_row.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_summary_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';

final _t0 = DateTime(2026, 9, 1, 19, 22);
final _learnedAt = DateTime(2026, 9, 2, 8);

TripSummary _trip({
  double? gain,
  String? dominant,
  double? veUsed,
  TripKind kind = TripKind.gpsPlusObd2,
  double? liters = 10.5,
}) =>
    TripSummary(
      distanceKm: 100,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      fuelLitersConsumed: liters,
      avgLPer100Km: liters,
      startedAt: _t0,
      endedAt: _t0.add(const Duration(minutes: 40)),
      pumpGainApplied: gain,
      dominantFuelSource: dominant,
      volumetricEfficiencyUsed: veUsed,
      kind: kind,
    );

final _calibrated = VehicleProfile(
  id: 'v',
  name: 'x',
  pumpGain: 0.72,
  pumpGainSamples: 1,
  pumpGainUpdatedAt: _learnedAt,
);

void main() {
  silenceErrorLoggerSpool();

  group('FuelSourceChip', () {
    Future<void> pump(WidgetTester t, TripSummary s, VehicleProfile? v) =>
        pumpApp(t, FuelSourceChip(figures: CalibratedTripFigures.of(s, v)));

    testWidgets('Measured', (tester) async {
      await pump(tester, _trip(dominant: 'pid5E', gain: 0.9), _calibrated);
      expect(find.text('Measured'), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('never rescaled'));
      expect(tip.message, isNot(contains('recalculated')));
    });

    testWidgets('Estimated · calibrated, recalculated', (tester) async {
      await pump(tester, _trip(veUsed: 0.85), _calibrated);
      expect(find.text('Estimated · calibrated'), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, endsWith('· recalculated'));
    });

    testWidgets('Estimated (no calibration)', (tester) async {
      await pump(tester, _trip(dominant: 'maf'), const VehicleProfile(id: 'v', name: 'x'));
      expect(find.text('Estimated'), findsOneWidget);
    });

    testWidgets('GPS', (tester) async {
      await pump(tester, _trip(kind: TripKind.gpsOnly), _calibrated);
      expect(find.text('GPS'), findsOneWidget);
    });

    testWidgets('no fuel figure → nothing', (tester) async {
      await pump(tester, _trip(liters: null), _calibrated);
      expect(find.byKey(const Key('fuelSourceChip')), findsNothing);
    });
  });

  group('TrajetRow', () {
    Widget host(TripSummary s, VehicleProfile? v) => Builder(
          builder: (context) => TrajetRow(
            entry: TripHistoryEntry(id: 't1', vehicleId: 'v', summary: s),
            vehicle: v,
            l: AppLocalizations.of(context),
            theme: Theme.of(context),
            onTap: () {},
          ),
        );

    testWidgets('re-expressed consumption figure + calibrated chip',
        (tester) async {
      await pumpApp(tester, host(_trip(veUsed: 0.85), _calibrated));
      // 10.5 × 0.72 = 7.56 → one decimal, in the host locale.
      expect(find.textContaining(UnitFormatter.formatDecimal(7.56)), findsOneWidget);
      expect(find.textContaining(UnitFormatter.formatDecimal(10.5)), findsNothing);
      expect(find.text('Estimated · calibrated'), findsOneWidget);
    });

    testWidgets('measured trip keeps its stored figure', (tester) async {
      await pumpApp(tester, host(_trip(dominant: 'pid5E'), _calibrated));
      expect(find.textContaining(UnitFormatter.formatDecimal(10.5)), findsOneWidget);
      expect(find.text('Measured'), findsOneWidget);
    });
  });

  group('TripSummaryCard header', () {
    testWidgets('chip + gain applied + recalculated after the fill of …',
        (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: TripHistoryEntry(
              id: 't1', vehicleId: 'v', summary: _trip(veUsed: 0.85)),
          vehicle: _calibrated,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('Estimated · calibrated'), findsOneWidget);
      expect(find.text('Pump gain applied: -28 %'), findsOneWidget);
      expect(find.byKey(const Key('tripDetailRecalculatedAfterFill')), findsOneWidget);
      expect(find.textContaining('Recalculated after the fill-up of'), findsOneWidget);
      expect(
          find.textContaining(
              '${UnitFormatter.formatDecimal(7.56, fractionDigits: 2)} L'),
          findsOneWidget,
          reason: 'fuel used re-expressed');
    });

    testWidgets('measured trip: chip only, no gain lines', (tester) async {
      await pumpApp(
        tester,
        TripSummaryCard(
          entry: TripHistoryEntry(
              id: 't1', vehicleId: 'v', summary: _trip(dominant: 'pid5E')),
          vehicle: _calibrated,
          samples: const [],
          isEv: false,
        ),
      );
      expect(find.text('Measured'), findsOneWidget);
      expect(find.byKey(const Key('tripDetailGainApplied')), findsNothing);
      expect(find.byKey(const Key('tripDetailRecalculatedAfterFill')), findsNothing);
    });
  });
}
