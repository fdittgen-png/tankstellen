// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_view.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

const _stationE10 = Station(
  id: 's-1',
  name: 'Carrefour Pézenas',
  brand: 'Carrefour',
  street: '12 ROUTE DE BÉZIERS',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.46,
  lng: 3.42,
  e10: 1.879,
  diesel: 1.999,
  isOpen: true,
);

TripRecordingState _activeState({
  double distance = 12.4,
  Duration elapsed = const Duration(minutes: 8, seconds: 32),
}) =>
    TripRecordingState(
      phase: TripRecordingPhase.recording,
      situation: DrivingSituation.highwayCruise,
      band: ConsumptionBand.normal,
      live: TripLiveReading(
        speedKmh: 70,
        distanceKmSoFar: distance,
        elapsed: elapsed,
      ),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('TripRecordingPipView (#2084) — approach-radius layout', () {
    testWidgets('default state renders the L/100 km layout — no approach',
        (tester) async {
      await tester.pumpWidget(_wrap(TripRecordingPipView(
        state: _activeState(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        approachState: const ApproachIdle(),
      )));
      // L/100 km unit caption is the canonical default-layout marker.
      expect(find.text('L/100 km'), findsOneWidget);
      // Approach layout would surface the station name; assert absent.
      expect(find.text('Carrefour Pézenas'), findsNothing);
    });

    testWidgets('ApproachInRadius flips to huge-price layout', (tester) async {
      await tester.pumpWidget(_wrap(TripRecordingPipView(
        state: _activeState(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        approachState: const ApproachInRadius(
          station: _stationE10,
          distanceMeters: 350,
        ),
        fuelType: FuelType.e10,
      )));
      // Station name shows.
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      // The price for the requested fuel type renders.
      // Format depends on locale; assert the integer portion is present.
      expect(find.textContaining('1'), findsWidgets);
      // The L/100 km caption is GONE in approach mode.
      expect(find.text('L/100 km'), findsNothing);
    });

    testWidgets('ApproachLeaving keeps the price layout through grace',
        (tester) async {
      // During the 5 s exit grace the price should stay visible —
      // suppresses UI flicker.
      await tester.pumpWidget(_wrap(TripRecordingPipView(
        state: _activeState(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        approachState: const ApproachLeaving(lastStation: _stationE10),
        fuelType: FuelType.e10,
      )));
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);
    });

    testWidgets('approachState=null still renders the default layout',
        (tester) async {
      await tester.pumpWidget(_wrap(TripRecordingPipView(
        state: _activeState(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      )));
      expect(find.text('L/100 km'), findsOneWidget);
    });

    testWidgets('approach with no price for the requested fuel falls back to —',
        (tester) async {
      const stationDieselOnly = Station(
        id: 's-2',
        name: 'Diesel-only',
        brand: 'X',
        street: '',
        postCode: '',
        place: '',
        lat: 0,
        lng: 0,
        diesel: 2.0,
        isOpen: true,
      );
      await tester.pumpWidget(_wrap(TripRecordingPipView(
        state: _activeState(),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        approachState: const ApproachInRadius(
          station: stationDieselOnly,
          distanceMeters: 100,
        ),
        fuelType: FuelType.e10, // not sold here
      )));
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Diesel-only'), findsOneWidget);
    });
  });

  group('TripRecordingPipView (#2086) — state-machine transitions', () {
    // Integration coverage: simulated trajet passes through a station
    // fixture, asserts overlay flips to big-price on radius entry,
    // holds for the grace, and collapses back to L/100 km on exit.
    testWidgets(
        'Idle → Polling → InRadius → Leaving → Polling: layout follows '
        'the state-machine transitions one-to-one', (tester) async {
      // Sweep the widget through the 5 state-machine transitions and
      // assert the layout matches at each step. We do not test the
      // detector itself here (that's covered by
      // approach_detector_test.dart) — only the widget's response.

      Future<void> pumpWithState(ApproachState approach) async {
        await tester.pumpWidget(_wrap(TripRecordingPipView(
          state: _activeState(),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          approachState: approach,
          fuelType: FuelType.e10,
        )));
        await tester.pump();
      }

      // 1. Idle — default layout (L/100 km caption present, station
      //    absent).
      await pumpWithState(const ApproachIdle());
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Carrefour Pézenas'), findsNothing);

      // 2. Polling — same default layout (we'd need a real GPS Position
      //    to build a Polling state; the widget doesn't care about that
      //    state's fields, only that it's NOT InRadius/Leaving).

      // 3. InRadius — flips to price view.
      await pumpWithState(const ApproachInRadius(
        station: _stationE10,
        distanceMeters: 350,
      ));
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);

      // 4. Leaving — price view persists.
      await pumpWithState(const ApproachLeaving(lastStation: _stationE10));
      expect(find.text('Carrefour Pézenas'), findsOneWidget);
      expect(find.text('L/100 km'), findsNothing);

      // 5. Back to Idle — layout collapses to L/100 km again.
      await pumpWithState(const ApproachIdle());
      expect(find.text('L/100 km'), findsOneWidget);
      expect(find.text('Carrefour Pézenas'), findsNothing);
    });
  });
}
