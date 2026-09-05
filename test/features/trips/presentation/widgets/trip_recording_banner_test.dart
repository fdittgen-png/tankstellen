// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/theme/contrast_utils.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/trips/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/trips/domain/situation_classifier.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_pause_banner.dart';
import 'package:tankstellen/features/trips/presentation/widgets/gps_degraded_banner.dart';
import 'package:tankstellen/features/trips/presentation/widgets/parked_prompt_pill.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_recording_pip_view.dart';
import 'package:tankstellen/features/trips/providers/pip_mode_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests pin the banner to an exact state without
/// spinning up an Obd2Service + controller + streams.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

  @override
  TripRecordingState build() => _initial;
}

/// Fake [PipMode] notifier — pins the app's PiP-mode flag for a test.
class _FakePipMode extends PipMode {
  final bool _value;
  _FakePipMode(this._value);

  @override
  bool build() => _value;
}

TripRecordingState _activeState({
  ConsumptionBand band = ConsumptionBand.normal,
  DrivingSituation situation = DrivingSituation.highwayCruise,
  double? delta,
  double? distance,
  double? speedKmh,
  double? fuelRateLPerHour,
  double? gpsEstimatedLPer100Km,
}) {
  return TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: situation,
    band: band,
    liveDeltaFraction: delta,
    live: distance == null
        ? null
        : TripLiveReading(
            distanceKmSoFar: distance,
            elapsed: const Duration(minutes: 1),
            speedKmh: speedKmh,
            fuelRateLPerHour: fuelRateLPerHour,
            gpsEstimatedLPer100Km: gpsEstimatedLPer100Km,
          ),
  );
}

void main() {
  group('TripRecordingBanner a11y (#767)', () {
    testWidgets('idle state: no banner rendered — Semantics empty',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('child'))),
      );
      expect(find.byKey(const Key('tripRecordingBanner')), findsNothing);
      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    // #3959 — a RECORDING draws no chrome above the app any more: the
    // band-coloured strip (situation, delta, distance, elapsed) moved
    // onto the recording form as `LiveBandHeader`, and the reduced tile
    // keeps the colour. What must stay true here is that the wrapper
    // costs the child NOTHING.
    testWidgets('an ACTIVE recording adds no height above the child',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              band: ConsumptionBand.heavy,
              delta: 0.08,
              distance: 5.2,
            )),
          ),
        ],
      );

      expect(find.byKey(const Key('tripRecordingBanner')), findsNothing);
      expect(tester.getTopLeft(find.byKey(const Key('child'))).dy, 0);
    });

    testWidgets('the transient pills still float over the content while '
        'recording (#3545)', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 1.0)),
          ),
        ],
      );

      // They render zero-size in this state; what matters is that the
      // wrapper still mounts them over the child instead of dropping
      // them with the strip.
      expect(find.byType(GpsDegradedBanner), findsOneWidget);
      expect(find.byType(ParkedPromptPill), findsOneWidget);
      expect(find.byType(Obd2PauseBanner), findsOneWidget);
    });
  });

  group('TripRecordingBanner PiP mode (#1977)', () {
    testWidgets(
        'in PiP mode renders only the compact tile — the shell child '
        '(which carries the bottom nav bar) is dropped', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('shell-child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
        ],
      );

      expect(find.byKey(const Key('shell-child')), findsNothing,
          reason: 'PiP must not render the shell — that is what dragged '
              'the button bar into the tile (#1977)');
      // The compact trip strip is still shown. With distance=4.0 +
      // no fuel rate + no estimate, #2601's consumption-framed warm-up
      // branch leads with the "~" placeholder under the est. L/100 km
      // caption and demotes the distance ("4.0 km") to the secondary
      // row. Finding the distance value is enough proof the tile
      // didn't collapse to nothing.
      expect(find.text('~'), findsOneWidget);
      expect(find.text('4,0 km'), findsOneWidget);
    });

    testWidgets('outside PiP mode the shell child renders as usual',
        (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox(key: Key('shell-child'))),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(false)),
        ],
      );

      expect(find.byKey(const Key('shell-child')), findsOneWidget);
    });
  });

  // #2382 — in approach mode the PiP tile adopts the FUEL TYPE's colour
  // (matching the hue the fuel wears elsewhere in the app) with a
  // WCAG-contrasting foreground. Outside approach mode it keeps the
  // driving-band palette.
  group('TripRecordingBanner approach-overlay fuel-type colour (#2382)', () {
    const station = Station(
      id: 's-1',
      name: 'Carrefour Pézenas',
      brand: 'Carrefour',
      street: '12 ROUTE DE BÉZIERS',
      postCode: '34120',
      place: 'Pézenas',
      lat: 43.46,
      lng: 3.42,
      e85: 1.099,
      isOpen: true,
    );

    TripRecordingPipView pipView(WidgetTester tester) =>
        tester.widget<TripRecordingPipView>(
          find.byType(TripRecordingPipView),
        );

    Future<void> pumpInApproach(
      WidgetTester tester, {
      required ApproachState approach,
      required FuelType fuel,
    }) {
      return pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(distance: 4.0)),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
          effectiveApproachStateProvider.overrideWithValue(approach),
          effectiveFuelTypeProvider.overrideWithValue(fuel),
        ],
      );
    }

    testWidgets('ApproachInRadius → background is the fuel type colour',
        (tester) async {
      const fuel = FuelType.e85;
      await pumpInApproach(
        tester,
        approach: const ApproachInRadius(
          station: station,
          distanceMeters: 350,
        ),
        fuel: fuel,
      );

      final view = pipView(tester);
      expect(view.backgroundColor, FuelColors.forType(fuel),
          reason: 'approach mode must paint the tile in the fuel hue');
      // Foreground must clear WCAG AA-large against the fuel background.
      expect(
        ContrastUtils.meetsAALarge(view.foregroundColor, view.backgroundColor),
        isTrue,
        reason: 'the huge price figure must stay legible on the fuel hue',
      );
    });

    testWidgets('a DIFFERENT fuel type yields its OWN colour', (tester) async {
      const fuel = FuelType.diesel;
      await pumpInApproach(
        tester,
        approach: const ApproachLeaving(lastStation: station),
        fuel: fuel,
      );
      expect(pipView(tester).backgroundColor, FuelColors.forType(fuel));
    });

    testWidgets('outside approach mode the band palette wins — NOT the fuel '
        'colour', (tester) async {
      await pumpApp(
        tester,
        const TripRecordingBanner(child: SizedBox()),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_activeState(
              band: ConsumptionBand.eco,
              distance: 4.0,
            )),
          ),
          pipModeProvider.overrideWith(() => _FakePipMode(true)),
          effectiveApproachStateProvider
              .overrideWithValue(const ApproachIdle()),
          effectiveFuelTypeProvider.overrideWithValue(FuelType.e85),
        ],
      );
      expect(
        pipView(tester).backgroundColor,
        isNot(FuelColors.forType(FuelType.e85)),
        reason: 'no approach → the driving-band palette must win',
      );
    });
  });

  // #2390 — the banner strip mirrors the PiP: on a GPS-only trajet the
  // consumption slot (normally OBD2-only) shows the live physics
  // estimate as "~X.X L/100"; OBD2 trips stay tilde-free; warm-up
  // (null estimate) leaves the slot silent.
}
