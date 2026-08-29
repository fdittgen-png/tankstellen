// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3859 / #3860 / #3862 (Epic #3855) — the one UX vocabulary for a car
// whose engine is off: the GPS pill says *waiting for the engine* and
// hides Reset (the one useless action on a sleeping adapter); the pause
// banner says *start the engine* instead of offering Reset; and the parked
// prompt asks the one question that matters after 3 min stationary.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/api.dart';
import 'package:tankstellen/features/trips/presentation/widgets/gps_degraded_banner.dart';
import 'package:tankstellen/features/trips/presentation/widgets/parked_prompt_pill.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';

import '../../../../helpers/pump_app.dart';

class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initial);

  final TripRecordingState _initial;
  int stopCalls = 0;
  int dismissCalls = 0;

  @override
  TripRecordingState build() => _initial;

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    stopCalls++;
    return const StoppedTripResult.empty();
  }

  @override
  void dismissParkedPrompt() => dismissCalls++;
}

class _FakeVehiclePower extends VehiclePower {
  _FakeVehiclePower(this._state);
  final VehiclePowerState _state;
  @override
  VehiclePowerState build() => _state;
}

/// Comfortably past the ~2.5 s appear-debounce + the ~220 ms fade.
const _pastDebounce = Duration(seconds: 3);

void main() {
  group('GpsDegradedBanner — engine-off wait (#3859)', () {
    testWidgets('reads "waiting for the engine" and carries NO Reset',
        (tester) async {
      final fake = _FakeTripRecording(const TripRecordingState(
        phase: TripRecordingPhase.degradedGpsOnly,
        dropReason: TripDropReason.engineOff,
      ));
      await pumpApp(
        tester,
        const GpsDegradedBanner(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);
      expect(find.text('Waiting for the engine — recording on GPS'),
          findsOneWidget);
      expect(find.text('Recording with GPS — OBD2 reconnecting'),
          findsNothing,
          reason: 'nothing is reconnecting — the car is parked');
      expect(find.byKey(const Key('gpsDegradedBannerReset')), findsNothing,
          reason: 'a reset dials a sleeping adapter: the one useless action');
    });

    testWidgets('an ordinary transport drop keeps the reconnecting copy '
        'and its Reset (the floor)', (tester) async {
      final fake = _FakeTripRecording(const TripRecordingState(
        phase: TripRecordingPhase.degradedGpsOnly,
        dropReason: TripDropReason.transportError,
      ));
      await pumpApp(
        tester,
        const GpsDegradedBanner(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();

      expect(find.text('Recording with GPS — OBD2 reconnecting'),
          findsOneWidget);
      expect(find.byKey(const Key('gpsDegradedBannerReset')), findsOneWidget);
    });
  });

  group('Obd2PauseBanner — car asleep (#3860)', () {
    testWidgets('offers "start the engine" instead of Reset', (tester) async {
      final fake = _FakeTripRecording(
          const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop));
      await pumpApp(
        tester,
        const Obd2PauseBanner(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
          vehiclePowerProvider
              .overrideWith(() => _FakeVehiclePower(VehiclePowerState.asleep)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('obd2PauseBannerStartEngine')),
          findsOneWidget);
      expect(find.text('Start the engine to reconnect'), findsOneWidget);
      expect(find.byKey(const Key('obd2PauseBannerReset')), findsNothing);
      // Resume / End stay: the driver may still want either.
      expect(find.byKey(const Key('obd2PauseBannerResume')), findsOneWidget);
      expect(find.byKey(const Key('obd2PauseBannerEnd')), findsOneWidget);
    });

    testWidgets('with the engine running (or unknown) Reset is back',
        (tester) async {
      final fake = _FakeTripRecording(
          const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop));
      await pumpApp(
        tester,
        const Obd2PauseBanner(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
          vehiclePowerProvider.overrideWith(
              () => _FakeVehiclePower(VehiclePowerState.engineRunning)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('obd2PauseBannerReset')), findsOneWidget);
      expect(find.byKey(const Key('obd2PauseBannerStartEngine')),
          findsNothing);
    });
  });

  group('ParkedPromptPill (#3862)', () {
    testWidgets('hidden until the controller flags the prompt due',
        (tester) async {
      final fake = _FakeTripRecording(const TripRecordingState(
        phase: TripRecordingPhase.degradedGpsOnly,
        dropReason: TripDropReason.engineOff,
      ));
      await pumpApp(
        tester,
        const ParkedPromptPill(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      expect(find.byKey(const Key('parkedPromptPill')), findsNothing);
    });

    testWidgets('Stop ends the trip; Keep dismisses and never stops',
        (tester) async {
      final fake = _FakeTripRecording(const TripRecordingState(
        phase: TripRecordingPhase.degradedGpsOnly,
        dropReason: TripDropReason.engineOff,
        parkedPromptDue: true,
      ));
      await pumpApp(
        tester,
        const ParkedPromptPill(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parkedPromptPill')), findsOneWidget);
      expect(find.text('Engine off for 3 min — stop recording?'),
          findsOneWidget);

      await tester.tap(find.byKey(const Key('parkedPromptKeep')));
      await tester.pumpAndSettle();
      expect(fake.dismissCalls, 1);
      expect(fake.stopCalls, 0);

      await tester.tap(find.byKey(const Key('parkedPromptStop')));
      await tester.pumpAndSettle();
      expect(fake.stopCalls, 1);
    });
  });
}
