// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/broken_map_warned_vehicles_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/driving/haptic_eco_coach.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/recording_profile_override.dart';

import '../../../../helpers/pump_app.dart';

/// #1423 phase 5 — fuel-rate display degradation when the active
/// vehicle's broken-MAP belief crosses 0.9.
///
///   * Belief 0.85 (warning band, not hard-disable): the live MAP-
///     derived L/100 km from `TripLiveReading.liveAvgLPer100Km` is
///     rendered. The disclaimer chip is also visible (covered in the
///     widget tests; here we only need to assert the live number is
///     used).
///   * Belief 0.92 (hard-disable): the live number is hidden, and
///     the receipt-derived per-vehicle L/100 km from the fill-up
///     history is shown instead. The persistent banner appears.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<CoachEvent> events;

  setUp(() {
    events = StreamController<CoachEvent>.broadcast();
  });

  tearDown(() async {
    await events.close();
  });

  testWidgets(
      'posterior ≈ 0.85 → live MAP-derived L/100 km is rendered',
      (tester) async {
    await _pumpRecordingScreen(
      tester,
      coachEvents: events,
      belief: const BrokenMapBelief(
        alpha: 85,
        beta: 15,
        observationCount: 5,
      ),
      live: const TripLiveReading(
        // 0.5 L over 5 km = exactly 10.0 L/100 km — distinct from any
        // receipt-derived value below so we can grep by number.
        fuelLitersSoFar: 0.5,
        distanceKmSoFar: 5.0,
        elapsed: Duration(minutes: 5),
      ),
      fills: _twoTanksAt7Avg(),
    );

    // #2026 — the live figure is now also rendered in
    // MinimalDriveSummary at the top of the recording column, so we
    // expect at least one (and now two) widgets to show it. The
    // intent of the assertion is preserved: the value is still
    // visible, not swapped or hidden.
    expect(
      find.textContaining('10.0 L/100 km'),
      findsAtLeastNWidgets(1),
      reason: 'In the warning band the live number remains the source '
          'of truth — only the disclaimer chip + snackbar surface.',
    );
    expect(find.byKey(const Key('brokenMapBanner')), findsNothing);
  });

  testWidgets(
      'posterior ≈ 0.92 → live rate is replaced by receipt-derived '
      'L/100 km AND the persistent banner appears',
      (tester) async {
    await _pumpRecordingScreen(
      tester,
      coachEvents: events,
      belief: const BrokenMapBelief(
        alpha: 92,
        beta: 8,
        observationCount: 8,
      ),
      live: const TripLiveReading(
        // Same live data as the warning-band test — 10.0 L/100 km.
        fuelLitersSoFar: 0.5,
        distanceKmSoFar: 5.0,
        elapsed: Duration(minutes: 5),
      ),
      fills: _twoTanksAt7Avg(),
    );

    // The receipt-derived L/100 km computed from the seeded fills:
    // 100 km between odometer 10000 and 10100, 7 L pumped on the
    // closing plein → 7.0 L/100 km. Distinct from the live 10.0
    // value so we can assert the swap.
    expect(
      find.textContaining('7.0 L/100 km'),
      findsOneWidget,
      reason: 'Hard-disable must swap to receipt-derived per-vehicle '
          'average from the fill-up history.',
    );
    expect(
      find.textContaining('10.0 L/100 km'),
      findsNothing,
      reason: 'Live MAP-derived value must NOT be visible in the '
          'hard-disable band.',
    );
    expect(find.byKey(const Key('brokenMapBanner')), findsOneWidget);
  });
}

/// Two-fill plein-to-plein window for vehicle veh-a:
///   * Opening fill at odometer 10000 km.
///   * Closing plein at 10100 km, 7 L pumped → 7.0 L/100 km.
List<FillUp> _twoTanksAt7Avg() => [
      FillUp(
        id: 'opening',
        date: DateTime(2026, 4, 1, 8),
        liters: 30,
        totalCost: 45,
        odometerKm: 10000,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
      ),
      FillUp(
        id: 'closing',
        date: DateTime(2026, 4, 2, 18),
        liters: 7,
        totalCost: 10.5,
        odometerKm: 10100,
        fuelType: FuelType.e10,
        vehicleId: 'veh-a',
      ),
    ];

Future<void> _pumpRecordingScreen(
  WidgetTester tester, {
  required StreamController<CoachEvent> coachEvents,
  required BrokenMapBelief belief,
  required TripLiveReading live,
  required List<FillUp> fills,
}) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _LiveFakeTripRecording(live),
      ),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      recordingProfileOverride() as Object,
      hapticEcoCoachLifecycleProvider
          .overrideWith(() => _FakeHapticEcoCoachLifecycle(coachEvents)),
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle('veh-a')),
      brokenMapBeliefByVehicleProvider.overrideWith(
        () => _FixedBeliefByVehicle({'veh-a': belief}),
      ),
      brokenMapWarnedVehiclesProvider
          .overrideWith(() => BrokenMapWarnedVehicles()),
      fillUpListProvider.overrideWith(() => _FakeFillUpList(fills)),
    ],
  );
}

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _LiveFakeTripRecording extends TripRecording {
  _LiveFakeTripRecording(this._live);
  final TripLiveReading _live;

  @override
  TripRecordingState build() => TripRecordingState(
        phase: TripRecordingPhase.recording,
        situation: DrivingSituation.urbanCruise,
        band: ConsumptionBand.normal,
        live: _live,
      );

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    return const StoppedTripResult(
      summary: TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      odometerStartKm: null,
      odometerLatestKm: null,
    );
  }

  @override
  void reset() {
    state = const TripRecordingState();
  }
}

class _FakeHapticEcoCoachLifecycle extends HapticEcoCoachLifecycle {
  _FakeHapticEcoCoachLifecycle(this._controller);
  final StreamController<CoachEvent> _controller;

  @override
  Stream<CoachEvent> get coachEvents => _controller.stream;

  @override
  void build() {}
}

class _FixedActiveVehicle extends ActiveVehicleProfile {
  _FixedActiveVehicle(this._id);
  final String _id;

  @override
  VehicleProfile? build() => VehicleProfile(id: _id, name: 'Test');
}

class _FixedBeliefByVehicle extends BrokenMapBeliefByVehicle {
  _FixedBeliefByVehicle(this._initial);
  final Map<String, BrokenMapBelief> _initial;

  @override
  Map<String, BrokenMapBelief> build() => _initial;
}

class _FakeFillUpList extends FillUpList {
  _FakeFillUpList(this._initial);
  final List<FillUp> _initial;

  @override
  List<FillUp> build() => _initial;
}
