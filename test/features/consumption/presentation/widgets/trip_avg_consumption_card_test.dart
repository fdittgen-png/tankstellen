// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_matrix_maturity_badge.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_avg_consumption_card.dart';
import 'package:tankstellen/features/vehicle/domain/entities/gps_calibration_matrix.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #2391 — GPS-only live Average-consumption card + maturity badge on
/// the trip-recording screen (Epic #2385).
///
/// Covers the card's three honest display modes plus the warm-up
/// graceful-placeholder path and the maturity-tier transitions:
///
///  * GPS-only with a running estimate → `~X.X L/100 km` + the right
///    maturity badge for the active vehicle's calibration state.
///  * Too-few-samples (no estimate yet) → muted `—`, no badge.
///  * OBD2 trip (measured) → real average, no `~`, no badge — no
///    regression of the measured path.
///  * Maturity transitions cold → warming → converged track the
///    matrix's fill-up reconciliation count + residual variance.
void main() {
  Widget harness({
    required TripLiveReading? live,
    String? brokenMapOverride,
    GpsCalibrationMatrix? matrix,
  }) {
    return ProviderScope(
      overrides: [
        activeVehicleProfileProvider.overrideWith(
          () => _FixedActiveVehicle(
            VehicleProfile(
              id: 'veh-a',
              name: 'Test',
              gpsCalibration: matrix,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TripAvgConsumptionCard(
            live: live,
            brokenMapOverride: brokenMapOverride,
          ),
        ),
      ),
    );
  }

  Text valueText(WidgetTester tester) => tester.widget<Text>(
        find.byKey(const Key('tripAvgConsumptionValue')),
      );

  group('TripAvgConsumptionCard (#2391)', () {
    testWidgets(
        'GPS-only with a running estimate → ~X.X L/100 km + maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // No measured fuel → liveAvgLPer100Km is null; the GPS running
        // average is the only consumption signal.
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        // 0 reconciliations → cold tier.
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '~6.4 L/100 km',
          reason: 'GPS estimate must carry a leading ~ (ADR 0012).');
      expect(find.byType(GpsMatrixMaturityBadge), findsOneWidget,
          reason: 'GPS estimate must show the calibration-maturity badge.');
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsOneWidget,
          reason: 'GPS estimate must carry the explanatory ~ tooltip.');
    });

    testWidgets('too-few-samples (no estimate yet) → muted — and no badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // Estimator still warming up: neither measured nor estimated.
        live: const TripLiveReading(
          elapsed: Duration(seconds: 3),
          distanceKmSoFar: 0.02,
        ),
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '—');
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing);
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsNothing);
    });

    testWidgets('OBD2 trip (measured) → real average, no ~, no maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        // 0.83 L over 10 km = 8.3 L/100 km (measured fuel-rate path).
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          fuelLitersSoFar: 0.83,
          // Even if a GPS estimate were present, measured wins.
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '8.3 L/100 km',
          reason: 'Measured average must NOT carry a ~ prefix.');
      expect(valueText(tester).data, isNot(contains('~')));
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing,
          reason: 'Measured data carries full confidence — no maturity badge.');
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsNothing);
    });

    testWidgets(
        'broken-MAP override wins over both branches, no ~, no maturity badge',
        (tester) async {
      await tester.pumpWidget(harness(
        live: const TripLiveReading(
          elapsed: Duration(minutes: 5),
          distanceKmSoFar: 10.0,
          gpsEstimatedAvgLPer100Km: 6.4,
        ),
        brokenMapOverride: '7.0 L/100 km',
        matrix: const GpsCalibrationMatrix(),
      ));
      await tester.pumpAndSettle();

      expect(valueText(tester).data, '7.0 L/100 km');
      expect(valueText(tester).data, isNot(contains('~')));
      expect(find.byType(GpsMatrixMaturityBadge), findsNothing);
    });

    // Maturity transitions cold → warming → converged. One fresh widget
    // tree per tier (a fresh ProviderScope each time) so the active-
    // vehicle override is re-evaluated cleanly per case.
    const estimateLive = TripLiveReading(
      elapsed: Duration(minutes: 5),
      distanceKmSoFar: 10.0,
      gpsEstimatedAvgLPer100Km: 6.4,
    );

    testWidgets('maturity badge: cold tier (<3 reconciliations)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(fillUpReconciliationCount: 1),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityCold), findsOneWidget);
    });

    testWidgets('maturity badge: warming tier (3–7, variance ≤ 1.5)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(
          fillUpReconciliationCount: 5,
          residualVariance: 1.0,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityWarming), findsOneWidget);
    });

    testWidgets('maturity badge: converged tier (8+, variance ≤ 0.5)',
        (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(harness(
        live: estimateLive,
        matrix: const GpsCalibrationMatrix(
          fillUpReconciliationCount: 10,
          residualVariance: 0.3,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(l.gpsMatrixMaturityConverged), findsOneWidget);
    });
  });
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._vehicle);
  final VehicleProfile _vehicle;

  @override
  VehicleProfile? build() => _vehicle;
}
