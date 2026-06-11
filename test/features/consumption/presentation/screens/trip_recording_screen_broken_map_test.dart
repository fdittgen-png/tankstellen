// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/broken_map_belief.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/broken_map_warned_vehicles_provider.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/driving/haptic_eco_coach.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/recording_profile_override.dart';

import '../../../../helpers/pump_app.dart';

/// #1423 phase 5 — trip-recording screen integration of the broken-MAP
/// snackbar listener. Verifies:
///
///   * The snackbar fires once when the active vehicle's belief
///     crosses from below 0.7 into the 0.7-0.9 warning band.
///   * It does NOT re-fire when the belief jitters within the band
///     (0.75 → 0.8 stays warned) — the in-session
///     [BrokenMapWarnedVehicles] guard is the source of truth.
///   * Switching to a different vehicle id fires a fresh snackbar
///     (each vehicle gets one warning per session).
///   * The persistent banner is NOT shown until the belief crosses
///     0.9 — the snackbar covers the 0.7-0.9 band, the banner covers
///     >=0.9.
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
      'fires snackbar once when belief crosses into 0.7-0.9 warning band',
      (tester) async {
    final beliefs = _MutableBeliefByVehicle({});
    await _pumpRecordingScreen(
      tester,
      coachEventsController: events,
      beliefs: beliefs,
    );

    // Sanity: no snackbar at start (default belief = 0.0).
    expect(
      find.byKey(const Key('brokenMapWarningSnackBar')),
      findsNothing,
    );

    // Cross from default prior (mean=0.1) -> mean ≈ 0.75 (warning
    // band entry).
    beliefs.set(
      'veh-a',
      const BrokenMapBelief(alpha: 75, beta: 25, observationCount: 4),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('brokenMapWarningSnackBar')),
      findsAtLeastNWidgets(1),
      reason: 'Belief crossing into 0.7-0.9 must surface the snackbar.',
    );
  });

  testWidgets(
      'does NOT re-fire snackbar on jitters within the 0.7-0.9 band',
      (tester) async {
    final beliefs = _MutableBeliefByVehicle({});
    await _pumpRecordingScreen(
      tester,
      coachEventsController: events,
      beliefs: beliefs,
    );

    // First crossing fires once.
    beliefs.set(
      'veh-a',
      const BrokenMapBelief(alpha: 72, beta: 28, observationCount: 4),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const Key('brokenMapWarningSnackBar')),
      findsAtLeastNWidgets(1),
    );

    // Dismiss the lingering snackbar so the post-jitter assertion is
    // clean.
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('brokenMapWarningSnackBar'))),
    ).hideCurrentSnackBar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Jitter within the band: 0.72 -> 0.78 -> 0.85. None of these
    // should re-fire because the warned-vehicles guard is set.
    beliefs.set(
      'veh-a',
      const BrokenMapBelief(alpha: 78, beta: 22, observationCount: 5),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    beliefs.set(
      'veh-a',
      const BrokenMapBelief(alpha: 85, beta: 15, observationCount: 6),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const Key('brokenMapWarningSnackBar')),
      findsNothing,
      reason: 'Jitter within the warning band must not re-warn — '
          'the per-session guard suppresses repeats.',
    );
  });

  testWidgets(
      'persistent banner appears at posterior >= 0.9 (not at 0.85)',
      (tester) async {
    final beliefs = _MutableBeliefByVehicle({
      'veh-a': const BrokenMapBelief(
        alpha: 85,
        beta: 15,
        observationCount: 5,
      ),
    });
    await _pumpRecordingScreen(
      tester,
      coachEventsController: events,
      beliefs: beliefs,
    );

    // 0.85 is in the warning band — banner stays hidden.
    expect(find.byKey(const Key('brokenMapBanner')), findsNothing);

    // Push to 0.92 — hard-disable band, banner appears.
    beliefs.set(
      'veh-a',
      const BrokenMapBelief(alpha: 92, beta: 8, observationCount: 7),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('brokenMapBanner')), findsOneWidget);
  });
}

TripRecordingState _recordingState() {
  return const TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: DrivingSituation.highwayCruise,
    band: ConsumptionBand.normal,
  );
}

Future<void> _pumpRecordingScreen(
  WidgetTester tester, {
  required StreamController<CoachEvent> coachEventsController,
  required _MutableBeliefByVehicle beliefs,
}) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _FakeTripRecording(_recordingState()),
      ),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      recordingProfileOverride() as Object,
      hapticEcoCoachLifecycleProvider
          .overrideWith(() => _FakeHapticEcoCoachLifecycle(
                coachEventsController,
              )),
      activeVehicleProfileProvider
          .overrideWith(() => _FixedActiveVehicle('veh-a')),
      brokenMapBeliefByVehicleProvider.overrideWith(() => beliefs),
      // Reset the warned-vehicles guard between tests so a stale entry
      // from a sibling group doesn't suppress this test's snackbar.
      brokenMapWarnedVehiclesProvider
          .overrideWith(() => BrokenMapWarnedVehicles()),
    ],
  );
}

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    state = state.copyWith(phase: TripRecordingPhase.finished);
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

class _MutableBeliefByVehicle extends BrokenMapBeliefByVehicle {
  _MutableBeliefByVehicle(this._initial);
  final Map<String, BrokenMapBelief> _initial;

  @override
  Map<String, BrokenMapBelief> build() => Map.of(_initial);

  @override
  void set(String vehicleId, BrokenMapBelief belief) {
    state = {...state, vehicleId: belief};
  }
}
