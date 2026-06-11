// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import '../../../../helpers/silence_error_logger.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/recording_profile_override.dart';

/// Regression coverage for #1458 phase 2 — when the user lands on the
/// trip-recording screen with the pin toggle OFF AND a recording is
/// active, a one-shot SnackBar must surface explaining that the screen
/// has to be pinned to keep GPS active.
///
/// Three contracts:
///   1. The SnackBar fires the moment the screen mounts on an active
///      recording with `_pinned` defaulting to false.
///   2. A non-active state (e.g. provider in `idle` because the test
///      harness hasn't started a recording) does NOT fire the warning
///      — there's nothing to warn about.
///   3. The SnackBar must NOT fire twice for the same screen mount —
///      a guard prevents the post-frame check from re-entering on a
///      rebuild and spamming the user.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

/// Minimal fake [TripRecording] that lets tests pin the provider's
/// initial state without needing the OBD2 stack. The base class is the
/// real Riverpod-generated notifier; we only override [build] so the
/// screen sees the right phase + flags.
class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initialState, {this.fakeStartedAt});

  final TripRecordingState _initialState;

  /// Override the `lastTripStartedAt` clock so the recording-screen's
  /// "fresh recording start" gate passes (the warning fires only when
  /// the trip kicked off in the recent past — see the screen's
  /// `_maybeShowUnpinnedWarning` for the gate semantics). Pass null
  /// to simulate the "screen mounted long after recording started"
  /// case.
  final DateTime? fakeStartedAt;

  @override
  DateTime? get lastTripStartedAt => fakeStartedAt;

  @override
  TripRecordingState build() => _initialState;

  // The screen calls these in response to AppBar buttons; defaulting
  // to no-ops keeps the harness honest — the tests don't exercise
  // pause/stop, so any call here would be a regression.
  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return const StoppedTripResult.empty();
  }

  @override
  void reset() {
    state = const TripRecordingState();
  }
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen unpinned-recording warning (#1458 phase 2)', () {
    testWidgets(
      'fires the SnackBar when the user lands on the recording screen '
      'with pin OFF and a trip is active',
      (tester) async {
        final notifier = _FakeTripRecording(
          const TripRecordingState(
            phase: TripRecordingPhase.recording,
            situation: DrivingSituation.urbanCruise,
            band: ConsumptionBand.normal,
          ),
          fakeStartedAt: DateTime.now(),
        );
        await pumpApp(
          tester,
          const TripRecordingScreen(),
          overrides: [
            tripRecordingProvider.overrideWith(() => notifier),
            wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
            recordingProfileOverride() as Object,
          ],
        );
        // The warning is deferred ~600 ms post-mount so it doesn't
        // race against other on-mount SnackBars (broken-MAP /
        // eco-coach). Pump past the deferred-fire timer + give the
        // SnackBar entry animation room to land.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const Key('tripRecordingUnpinnedWarningSnackBar')),
          findsOneWidget,
          reason:
              'Unpinned recording must surface the GPS-throttle warning; '
              'this is the upfront mitigation while the diagnostics '
              'instrumentation collects evidence (#1458 phase 2).',
        );
      },
    );

    testWidgets(
      'does NOT fire the SnackBar when no trip is active',
      (tester) async {
        // Provider in idle phase — there's no recording to warn about.
        // We deliberately pass `fakeStartedAt: DateTime.now()` to prove
        // that the active-state check fires BEFORE the start-age gate;
        // a "started just now" timestamp without an active recording
        // must still be filtered out.
        final notifier = _FakeTripRecording(
          const TripRecordingState(),
          fakeStartedAt: DateTime.now(),
        );
        await pumpApp(
          tester,
          const TripRecordingScreen(),
          overrides: [
            tripRecordingProvider.overrideWith(() => notifier),
            wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
            recordingProfileOverride() as Object,
          ],
        );
        // Pump past the deferred-fire timer so the post-mount path
        // has every chance to fire — and assert it didn't.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const Key('tripRecordingUnpinnedWarningSnackBar')),
          findsNothing,
          reason:
              'No active recording means no GPS subscription; the warning '
              'would be misleading.',
        );
      },
    );

    testWidgets(
      'does NOT fire when the user re-enters the recording screen '
      'long after the trip started (banner re-entry)',
      (tester) async {
        // Simulate the banner-reentry case: the recording started
        // 5 minutes ago, the user backed out, came back via the
        // persistent banner. The warning is for fresh recording
        // starts — re-entry is noise.
        final notifier = _FakeTripRecording(
          const TripRecordingState(
            phase: TripRecordingPhase.recording,
            situation: DrivingSituation.urbanCruise,
            band: ConsumptionBand.normal,
          ),
          fakeStartedAt:
              DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await pumpApp(
          tester,
          const TripRecordingScreen(),
          overrides: [
            tripRecordingProvider.overrideWith(() => notifier),
            wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
            recordingProfileOverride() as Object,
          ],
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const Key('tripRecordingUnpinnedWarningSnackBar')),
          findsNothing,
          reason:
              'Banner re-entry must NOT re-show the warning — the user '
              'has already been driving for a while; the toast would be '
              'noise rather than the upfront mitigation it is designed '
              'to be.',
        );
      },
    );

    testWidgets(
      'does NOT fire twice on a single screen mount',
      (tester) async {
        final notifier = _FakeTripRecording(
          const TripRecordingState(
            phase: TripRecordingPhase.recording,
            situation: DrivingSituation.urbanCruise,
            band: ConsumptionBand.normal,
          ),
          fakeStartedAt: DateTime.now(),
        );
        await pumpApp(
          tester,
          const TripRecordingScreen(),
          overrides: [
            tripRecordingProvider.overrideWith(() => notifier),
            wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
            recordingProfileOverride() as Object,
          ],
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 250));

        // First fire is expected — verify it's there.
        expect(
          find.byKey(const Key('tripRecordingUnpinnedWarningSnackBar')),
          findsOneWidget,
        );

        // Force a rebuild without unmounting. The post-frame path must
        // NOT re-show the SnackBar because the guard sticks for the
        // lifetime of this state object.
        notifier.state = notifier.state.copyWith(
          band: ConsumptionBand.heavy,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Wait for the SnackBar's auto-dismiss timer (8 s in production)
        // to elapse so we can verify nothing replaced it. We pump
        // 9 seconds in 100 ms slices to keep the test deterministic
        // without pumpAndSettle (which would hang on indeterminate
        // animations).
        for (var i = 0; i < 90; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          find.byKey(const Key('tripRecordingUnpinnedWarningSnackBar')),
          findsNothing,
          reason:
              'After the SnackBar auto-dismisses, the guard must keep it '
              'from re-firing on subsequent rebuilds within the same mount.',
        );
      },
    );
  });
}
