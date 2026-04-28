import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/driving/coach_event.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #1273 — visual coach SnackBar on the trip-recording screen MUST:
///   * Appear when a [CoachEvent] arrives via [coachEventsProvider]
///     and the trip is active.
///   * Carry the eco icon + the loca-fallback "Easy on the throttle"
///     copy so users see why they were nudged.
///   * NOT appear when the eco-coach toggle is off — we model that by
///     overriding the stream provider with `Stream.empty()`, which
///     mirrors what the lifecycle returns when its bridge is down.
///
/// We don't reach into the heuristic from these tests — the lifecycle
/// + heuristic are covered separately in `coach_events_provider_test.dart`.
/// Here we just verify the UI's subscription wiring is correct.

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
  void reset() {
    state = const TripRecordingState();
  }
}

const TripRecordingState _activeRecording = TripRecordingState(
  phase: TripRecordingPhase.recording,
  situation: DrivingSituation.highwayCruise,
  band: ConsumptionBand.normal,
);

CoachEvent _sampleEvent() => CoachEvent(
      firedAt: DateTime(2026, 1, 1, 12, 0, 0),
      avgThrottlePercent: 82.0,
      speedDeltaKmh: 3.0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen coach SnackBar (#1273)', () {
    testWidgets(
        'a CoachEvent arriving on the stream surfaces the SnackBar with '
        'the eco icon and copy', (tester) async {
      // The screen subscribes to [coachEventsProvider] in `initState`.
      // We override it with a controlled controller so the test can
      // dispatch a single fire-decision deterministically.
      final controller = StreamController<CoachEvent>.broadcast();
      addTearDown(controller.close);

      await pumpApp(
        tester,
        const TripRecordingScreen(),
        overrides: [
          tripRecordingProvider
              .overrideWith(() => _FakeTripRecording(_activeRecording)),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          coachEventsProvider.overrideWith((ref) => controller.stream),
        ],
      );

      // Fire one event onto the stream — the screen's listenManual
      // must pick it up and pump a SnackBar.
      controller.add(_sampleEvent());
      await tester.pump(); // dispatch microtasks
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const Key('coachSnackBar')),
        findsOneWidget,
        reason:
            'A CoachEvent on the UI stream must surface a SnackBar — '
            'this is the entire point of the visual coach (#1273).',
      );
      expect(
        find.text('Easy on the throttle — coasting saves more'),
        findsOneWidget,
        reason:
            'Visible copy must match the issue acceptance — anything '
            'else means the ARB key did not flow through.',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('coachSnackBar')),
          matching: find.byIcon(Icons.eco),
        ),
        findsOneWidget,
        reason:
            'SnackBar must carry the eco leaf icon so the meaning '
            'reads at a glance, even before the text resolves.',
      );
    });

    testWidgets(
        'no SnackBar when the eco-coach stream stays empty — toggle off '
        'leaves the visual surface silent', (tester) async {
      // Override with an empty stream — that is exactly what the
      // lifecycle returns when the toggle is off: no events ever
      // reach the screen.
      await pumpApp(
        tester,
        const TripRecordingScreen(),
        overrides: [
          tripRecordingProvider
              .overrideWith(() => _FakeTripRecording(_activeRecording)),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          coachEventsProvider
              .overrideWith((ref) => const Stream<CoachEvent>.empty()),
        ],
      );

      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byKey(const Key('coachSnackBar')),
        findsNothing,
        reason:
            'With the toggle off the lifecycle returns an empty '
            'stream — the screen MUST stay silent.',
      );
    });
  });
}
