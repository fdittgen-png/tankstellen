// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4378 — what a STOP whose history write failed tells the user.
///
/// #3582's rule is that the UI never lies about persistence: a trip that
/// did not reach history must not be reported as saved. It says the trip
/// is kept — it is: #4328 keeps its WAL row and #4378 keeps the trip under
/// its own id — and offers a retry that goes through the same confirmed
/// save, which this test taps. What that retry WRITES is pinned by
/// `trip_recording_pending_save_test.dart`; here the tap is the subject.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/trips/providers/pending_trip_save_retry_provider.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/trips/providers/wakelock_facade.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/recording_profile_override.dart';
import '../../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  final startedAt = DateTime.utc(2026, 9, 17, 8);

  Future<void> pumpAndStop(
    WidgetTester tester, {
    required TripRecording notifier,
    required Future<int> Function() retry,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          key: const Key('open_trip_screen'),
          onPressed: () => Navigator.of(context).push<TripSaveResult?>(
            MaterialPageRoute(builder: (_) => const TripRecordingScreen()),
          ),
          child: const Text('Open'),
        ),
      ),
      overrides: [
        tripRecordingProvider.overrideWith(() => notifier),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        pendingTripSaveRetryProvider.overrideWithValue(retry),
        recordingProfileOverride() as Object,
      ],
    );
    await tester.tap(find.byKey(const Key('open_trip_screen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tripStopButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('a failed save is reported as kept, and its Retry runs the '
      'save again', (tester) async {
    var retries = 0;
    await pumpAndStop(
      tester,
      notifier: _StoppingTripRecording(startedAt, saveFailed: true),
      retry: () async {
        retries++;
        return 1;
      },
    );

    expect(find.byKey(const Key('tripSaveFailedSnackBar')), findsOneWidget,
        reason: 'a trip that did not reach history is never reported saved');
    expect(find.byKey(const Key('tripSavedSnackBar')), findsNothing);
    expect(retries, 0, reason: 'the retry is the user\'s decision');

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1, reason: 'Retry goes through the confirmed save');
  });

  testWidgets('a save that landed is still reported as saved, with no retry',
      (tester) async {
    var retries = 0;
    await pumpAndStop(
      tester,
      notifier: _StoppingTripRecording(startedAt, saveFailed: false),
      retry: () async {
        retries++;
        return 0;
      },
    );

    expect(find.byKey(const Key('tripSavedSnackBar')), findsOneWidget);
    expect(find.byKey(const Key('tripSaveFailedSnackBar')), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(retries, 0);
  });
}

/// A recording whose stop reports a landed or a failed history write.
class _StoppingTripRecording extends TripRecording {
  _StoppingTripRecording(this._startedAt, {required this.saveFailed});

  final DateTime _startedAt;
  final bool saveFailed;

  @override
  TripRecordingState build() =>
      const TripRecordingState(phase: TripRecordingPhase.recording);

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: TripSummary(
        distanceKm: 12.5,
        maxRpm: 2600,
        highRpmSeconds: 0,
        idleSeconds: 4,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: _startedAt,
      ),
      odometerStartKm: null,
      odometerLatestKm: null,
      entryId: saveFailed ? null : _startedAt.toIso8601String(),
      saveFailed: saveFailed,
    );
  }

  @override
  void reset() => state = const TripRecordingState();
}

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}
