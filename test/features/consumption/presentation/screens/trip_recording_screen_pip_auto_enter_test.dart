// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pip_controller.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/pip_mode_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/pump_app.dart';

/// #2274 concern 4 — foreground-then-PiP auto-enter (Android). With the
/// start-now-connect-later push (concern 2) the recording screen is
/// foreground+active before the user can leave to Maps, so the native
/// onUserLeaveHint auto-enter PiP fires reliably. The Dart-side guarantee
/// this test pins: while a trip is actively recording on the foreground
/// screen, the native auto-PiP opt-in is ARMED; once it stops it is
/// disarmed. Android-only — the controller is a no-op on every other
/// platform.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _ActiveTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.recording,
        situation: DrivingSituation.highwayCruise,
        band: ConsumptionBand.normal,
      );

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
  void reset() => state = const TripRecordingState();
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tankstellen/pip');

  testWidgets(
      'auto-PiP is armed while recording on the foreground screen and '
      'disarmed when the trip stops', (tester) async {
    // Force the Android code path so PipController.isSupported is true and
    // the auto-enter opt-in actually crosses the (mocked) channel. Reset
    // at the end of the body — a foundation debug var left set trips the
    // test framework's end-of-body invariant check.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final autoEnterCalls = <bool>[];
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setAutoEnter') {
        autoEnterCalls.add(call.arguments == true);
      }
      return null;
    });

    // A fresh controller per pump so the mocked channel is bound.
    final pip = PipController();
    addTearDown(pip.dispose);

    await pumpApp(
      tester,
      const TripRecordingScreen(),
      overrides: [
        tripRecordingProvider.overrideWith(() => _ActiveTripRecording()),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        pipControllerProvider.overrideWithValue(pip),
      ],
    );
    await tester.pump();

    // Armed (true) while recording + foreground.
    expect(autoEnterCalls.contains(true), isTrue,
        reason: 'auto-PiP must be armed while a trip records on the '
            'foreground recording screen (concern 4)');

    // Stop the trip → the opt-in disarms.
    autoEnterCalls.clear();
    await tester.tap(find.byKey(const Key('tripStopButton')));
    await tester.pumpAndSettle();

    expect(autoEnterCalls.contains(false), isTrue,
        reason: 'auto-PiP must disarm once the trip is no longer recording');

    // Reset the channel + platform override BEFORE the body returns so
    // the framework's end-of-body invariant check passes.
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
}
