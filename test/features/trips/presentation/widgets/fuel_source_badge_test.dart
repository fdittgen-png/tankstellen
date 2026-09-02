// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/obd2/domain/fuel_mixture_model.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/fuel_source_badge.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_avg_consumption_card.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3916 (Epic #3914) — the consumption card's fuel-source badge: measured
/// (ECU fuel flow) vs estimated (pump-calibrated ±x % / not calibrated) vs
/// the GPS estimate, resolved from the live reading's provenance and the
/// vehicle's pump gain (#3886).
class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}

const _measured = TripLiveReading(
  elapsed: Duration(minutes: 5),
  distanceKmSoFar: 5.0,
  fuelLitersSoFar: 0.3,
  fuelRateLPerHour: 4.0,
  fuelSource: FuelRateSourceTag.pid5E,
);

const _estimated = TripLiveReading(
  elapsed: Duration(minutes: 5),
  distanceKmSoFar: 5.0,
  fuelLitersSoFar: 0.3,
  fuelRateLPerHour: 4.0,
  fuelSource: FuelRateSourceTag.speedDensity,
);

const _gpsOnly = TripLiveReading(
  elapsed: Duration(minutes: 5),
  distanceKmSoFar: 5.0,
  gpsEstimatedAvgLPer100Km: 6.4,
);

VehicleProfile _vehicle({double gain = 1.0, int samples = 0}) =>
    VehicleProfile(
      id: 'veh-a',
      name: 'Test',
      pumpGain: gain,
      pumpGainSamples: samples,
    );

void main() {
  group('resolveFuelSourceBadge', () {
    test('measured PID → measured, whatever the pump gain', () {
      expect(
        resolveFuelSourceBadge(
            live: _measured, vehicle: _vehicle(gain: 1.2, samples: 3)),
        const FuelSourceBadgeState(FuelSourceKind.measured),
      );
    });

    test('estimated branch with pump samples → calibrated ±|1−gain| %', () {
      expect(
        resolveFuelSourceBadge(
            live: _estimated, vehicle: _vehicle(gain: 1.043, samples: 2)),
        const FuelSourceBadgeState(FuelSourceKind.estimatedCalibrated,
            calibrationPercent: 4),
      );
      expect(
        resolveFuelSourceBadge(
            live: _estimated, vehicle: _vehicle(gain: 0.91, samples: 1)),
        const FuelSourceBadgeState(FuelSourceKind.estimatedCalibrated,
            calibrationPercent: 9),
      );
    });

    test('estimated branch without samples (or vehicle) → not calibrated',
        () {
      expect(
        resolveFuelSourceBadge(live: _estimated, vehicle: _vehicle()),
        const FuelSourceBadgeState(FuelSourceKind.estimatedUncalibrated),
      );
      expect(
        resolveFuelSourceBadge(live: _estimated, vehicle: null),
        const FuelSourceBadgeState(FuelSourceKind.estimatedUncalibrated),
      );
    });

    test('no provenance but a GPS estimate → GPS estimate', () {
      expect(
        resolveFuelSourceBadge(live: _gpsOnly, vehicle: null),
        const FuelSourceBadgeState(FuelSourceKind.gpsEstimate),
      );
    });

    test('nothing known → no badge', () {
      expect(resolveFuelSourceBadge(live: null, vehicle: null), isNull);
      expect(
        resolveFuelSourceBadge(
          live: const TripLiveReading(
              elapsed: Duration.zero, distanceKmSoFar: 0),
          vehicle: null,
        ),
        isNull,
      );
    });
  });

  group('TripAvgConsumptionCard badge', () {
    Widget harness(TripLiveReading? live, VehicleProfile? vehicle,
        {Locale? locale}) {
      return ProviderScope(
        overrides: [
          activeVehicleProfileProvider
              .overrideWith(() => _FixedActiveVehicle(vehicle)),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: TripAvgConsumptionCard(live: live),
            ),
          ),
        ),
      );
    }

    testWidgets('measured reading shows "Measured (ECU fuel flow)"',
        (tester) async {
      await tester.pumpWidget(harness(_measured, _vehicle()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripAvgFuelSourceBadge')), findsOneWidget);
      expect(find.text('Measured (ECU fuel flow)'), findsOneWidget);
    });

    testWidgets('estimated + calibrated shows the pump-calibrated percent, '
        'in French too', (tester) async {
      await tester.pumpWidget(harness(
        _estimated,
        _vehicle(gain: 1.043, samples: 2),
        locale: const Locale('fr'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Estimé · calibré à la pompe ±4 %'), findsOneWidget);
    });

    testWidgets('estimated without samples shows "not calibrated"',
        (tester) async {
      await tester.pumpWidget(harness(_estimated, _vehicle()));
      await tester.pumpAndSettle();
      expect(find.text('Estimated · not calibrated'), findsOneWidget);
    });

    testWidgets('GPS-only reading shows "GPS estimate" beside the maturity '
        'badge', (tester) async {
      await tester.pumpWidget(harness(_gpsOnly, _vehicle()));
      await tester.pumpAndSettle();
      expect(find.text('GPS estimate'), findsOneWidget);
      expect(find.byKey(const Key('tripAvgEstimateTooltip')), findsOneWidget);
    });

    testWidgets('no reading → no badge', (tester) async {
      await tester.pumpWidget(harness(null, _vehicle()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripAvgFuelSourceBadge')), findsNothing);
    });
  });
}
