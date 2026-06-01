// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_degraded_banner.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_pause_banner.dart';
// `trip_recording_provider.dart` re-exports TripRecordingPhase + State.
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests flip the phase imperatively without touching
/// the production controller (which reaches Obd2Service + Hive).
class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initial);

  TripRecordingState _initial;
  int resumeCalls = 0;
  int stopCalls = 0;

  @override
  TripRecordingState build() => _initial;

  void setPhase(TripRecordingPhase phase) {
    _initial = _initial.copyWith(phase: phase);
    state = _initial;
  }

  @override
  void resume() => resumeCalls++;

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    stopCalls++;
    return const StoppedTripResult.empty();
  }
}

/// Hosts BOTH banners so a single pump can assert their mutual exclusion.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [Obd2PauseBanner(), GpsDegradedBanner()],
    );
  }
}

void main() {
  group('GpsDegradedBanner (#2565)', () {
    testWidgets('not visible while recording', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);
    });

    testWidgets('appears on transition to degradedGpsOnly, with NO Resume / '
        'End actions (recording continues automatically)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);

      fake.setPhase(TripRecordingPhase.degradedGpsOnly);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);
      expect(
        find.text('Recording with GPS — OBD2 reconnecting'),
        findsOneWidget,
      );
      // The GPS banner must carry no escape hatches — recording is live.
      expect(find.byKey(const Key('obd2PauseBannerResume')), findsNothing);
      expect(find.byKey(const Key('obd2PauseBannerEnd')), findsNothing);
    });

    testWidgets('the pause banner does NOT render in degradedGpsOnly — '
        'the two banners are mutually exclusive', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);
      expect(find.byKey(const Key('obd2PauseBanner')), findsNothing,
          reason: 'the contradictory "recording paused" banner must never '
              'show while the trip is actively recording GPS-only');
    });

    testWidgets('the GPS banner does NOT render in pausedDueToDrop — the '
        'pause banner owns that state', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      expect(find.byKey(const Key('obd2PauseBanner')), findsOneWidget);
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);
    });

    testWidgets('disappears when phase returns to recording (OBD2 '
        'reconnected)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);

      fake.setPhase(TripRecordingPhase.recording);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);
    });

    test('degradedGpsOnly is an ACTIVE state (the recording chrome stays '
        'up)', () {
      const state =
          TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly);
      expect(state.isActive, isTrue);
    });
  });
}
