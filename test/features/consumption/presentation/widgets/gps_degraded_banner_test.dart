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

  /// #2767 — flip the passive-waiting signal so the test can prove the
  /// banner swaps its copy.
  void setPassiveWaiting(bool value) {
    _initial = _initial.copyWith(reconnectPassiveWaiting: value);
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

/// Comfortably past the ~2.5 s appear-debounce + the ~220 ms fade.
const _pastDebounce = Duration(seconds: 3);

/// Comfortably past the ~1.5 s hide-grace + the fade.
const _pastGrace = Duration(seconds: 2);

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

    testWidgets(
        'appears (after the debounce) on a sustained transition to '
        'degradedGpsOnly, with NO Resume / End actions (recording continues '
        'automatically)', (tester) async {
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
      await tester.pump();
      // #3010 — the debounce holds it back until the link has stayed
      // degraded long enough; it must NOT pop in immediately.
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing,
          reason: 'the appear-debounce must suppress the banner on the '
              'leading edge so transient drops never flash it');

      await tester.pump(_pastDebounce);
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
      // Mounted already-degraded: the same debounce applies (see initState).
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();

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

    testWidgets(
        'disappears (after the grace window) when phase returns to recording '
        '(OBD2 reconnected)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);

      fake.setPhase(TripRecordingPhase.recording);
      await tester.pump();
      // #3010 — it lingers through the grace window so a quick re-drop
      // keeps it up rather than strobing it off then back on.
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget,
          reason: 'the hide-grace must keep the banner up briefly after '
              'reconnect so a re-drop never strobes it');

      await tester.pump(_pastGrace);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);
    });

    test('degradedGpsOnly is an ACTIVE state (the recording chrome stays '
        'up)', () {
      const state =
          TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly);
      expect(state.isActive, isTrue);
    });

    testWidgets(
        'while active-scanning shows the busy "OBD2 reconnecting" copy '
        '(#2767)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(
          phase: TripRecordingPhase.degradedGpsOnly,
          // Default false — the scanner is still active-scanning.
        ),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();

      expect(find.text('Recording with GPS — OBD2 reconnecting'),
          findsOneWidget);
      expect(find.text('Recording with GPS — waiting for the OBD2 adapter'),
          findsNothing);
    });

    testWidgets(
        'once the scanner gives up active scanning it swaps to the calmer '
        '"waiting for the OBD2 adapter" copy (#2767)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      // Starts busy.
      expect(find.text('Recording with GPS — OBD2 reconnecting'),
          findsOneWidget);

      // The reconnect scanner exhausts its active-scan ceiling → passive wait.
      fake.setPassiveWaiting(true);
      await tester.pumpAndSettle();

      expect(find.text('Recording with GPS — waiting for the OBD2 adapter'),
          findsOneWidget,
          reason: 'a distinct, calmer banner must surface so the user knows '
              'reconnect is still trying passively, not stuck (#2767)');
      expect(find.text('Recording with GPS — OBD2 reconnecting'), findsNothing,
          reason: 'the busy copy must give way — the two are distinct states');
      // The banner stays action-free in either copy — recording continues.
      expect(find.byKey(const Key('obd2PauseBannerResume')), findsNothing);
      expect(find.byKey(const Key('obd2PauseBannerEnd')), findsNothing);
    });
  });

  group('GpsDegradedBanner flicker fix (#3010)', () {
    testWidgets('the banner is wrapped in AnimatedSize — it eases in/out '
        'instead of popping', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();

      // The single GpsDegradedBanner must contribute an AnimatedSize wrapping
      // its content — proves the abrupt SizedBox.shrink() toggle is gone.
      expect(
        find.descendant(
          of: find.byType(GpsDegradedBanner),
          matching: find.byType(AnimatedSize),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(GpsDegradedBanner),
          matching: find.byType(AnimatedOpacity),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'a transient degrade→recover INSIDE the debounce window never '
        'surfaces the banner (no strobe on a Bluetooth blip)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      // Drop, then reconnect well within the ~2.5 s appear-debounce.
      fake.setPhase(TripRecordingPhase.degradedGpsOnly);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);

      fake.setPhase(TripRecordingPhase.recording);
      await tester.pump(const Duration(milliseconds: 800));

      // Let the original debounce deadline pass: the banner must STILL be
      // gone — the blip resolved before the debounce armed it.
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing,
          reason: 'a transient OBD2 drop that recovers inside the debounce '
              'window must never flash the banner');
    });

    testWidgets(
        'rapid strobe (degrade→recover→degrade→recover all inside the '
        'debounce) never surfaces the banner', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      for (var i = 0; i < 4; i++) {
        fake.setPhase(TripRecordingPhase.degradedGpsOnly);
        await tester.pump(const Duration(milliseconds: 300));
        fake.setPhase(TripRecordingPhase.recording);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);
      }

      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing,
          reason: 'rapid drop/reconnect blips must never strobe the banner');
    });

    testWidgets(
        'a sustained disconnect (longer than the debounce) DOES surface the '
        'banner', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      fake.setPhase(TripRecordingPhase.degradedGpsOnly);
      await tester.pump();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsNothing);

      // Hold the degrade past the debounce.
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget,
          reason: 'a real, sustained OBD2 drop must still inform the user');
    });

    testWidgets(
        'a re-drop INSIDE the hide-grace keeps the banner up (no off-then-on '
        'strobe on a flapping link)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.degradedGpsOnly),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);

      // Reconnect, then drop again well within the ~1.5 s grace.
      fake.setPhase(TripRecordingPhase.recording);
      await tester.pump(const Duration(milliseconds: 500));
      fake.setPhase(TripRecordingPhase.degradedGpsOnly);
      await tester.pump(const Duration(milliseconds: 500));

      // It must have stayed up the whole time — never blinked off.
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget,
          reason: 'a flapping link inside the grace window must keep the '
              'banner steady, not strobe it');

      // And it stays up past where a naive hide would have fired.
      await tester.pump(_pastGrace);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);
    });

    testWidgets(
        'showing the banner does NOT shift the metrics row above it — the '
        'height animates from 0 in place (reserved layout)', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      // A sentinel "metrics row" sits ABOVE the banner, mirroring the real
      // TripRecordingBanner Column (status bar, then the GPS banner). Its
      // top offset must not move when the banner shows/hides — the banner
      // grows downward, so anything above it stays put.
      await pumpApp(
        tester,
        const Column(
          children: [
            SizedBox(
              key: Key('metricsRow'),
              height: 40,
              width: double.infinity,
            ),
            GpsDegradedBanner(),
          ],
        ),
        overrides: [tripRecordingProvider.overrideWith(() => fake)],
      );

      final before = tester.getTopLeft(find.byKey(const Key('metricsRow')));

      fake.setPhase(TripRecordingPhase.degradedGpsOnly);
      await tester.pump(_pastDebounce);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpsDegradedBanner')), findsOneWidget);

      final afterShow = tester.getTopLeft(find.byKey(const Key('metricsRow')));
      expect(afterShow, before,
          reason: 'the metrics row above the banner must not move when the '
              'banner appears (it grows downward into reserved space)');

      // And it stays put when the banner eases away again.
      fake.setPhase(TripRecordingPhase.recording);
      await tester.pump(_pastGrace);
      await tester.pumpAndSettle();
      final afterHide = tester.getTopLeft(find.byKey(const Key('metricsRow')));
      expect(afterHide, before,
          reason: 'the metrics row must stay put when the banner eases away');
    });
  });
}
