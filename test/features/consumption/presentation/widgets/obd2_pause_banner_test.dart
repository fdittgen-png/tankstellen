import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/obd2_pause_banner.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

import '../../../../helpers/pump_app.dart';

/// Fake notifier lets tests flip the phase imperatively while
/// counting how often the banner's Resume / End actions wire through
/// to the provider. Overriding the whole TripRecording class is
/// preferred over stubbing `resume()` / `stop()` since those methods
/// touch Obd2Service + Hive in production and we want neither
/// anywhere near a widget test.
class _FakeTripRecording extends TripRecording {
  _FakeTripRecording(this._initial);

  TripRecordingState _initial;
  int resumeCalls = 0;
  int stopCalls = 0;

  @override
  TripRecordingState build() => _initial;

  /// Flip the exposed state without touching the underlying
  /// controller. Simulates the phase transition the real provider
  /// would publish when the controller wakes from a BT drop.
  void setPhase(TripRecordingPhase phase) {
    _initial = _initial.copyWith(phase: phase);
    state = _initial;
  }

  @override
  void resume() {
    resumeCalls++;
  }

  @override
  Future<StoppedTripResult> stop() async {
    stopCalls++;
    return const StoppedTripResult.empty();
  }
}

/// Wrapper so tests can grab the banner and a ScaffoldMessenger host
/// in one pumpApp call — MaterialBanner doesn't render outside of
/// one.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [Obd2PauseBanner()],
    );
  }
}

void main() {
  group('Obd2PauseBanner (#797 phase 2)', () {
    testWidgets('not visible when phase is recording', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );
      expect(find.byKey(const Key('obd2PauseBanner')), findsNothing);
    });

    testWidgets('appears on transition to pausedDueToDrop', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.recording),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );
      expect(find.byKey(const Key('obd2PauseBanner')), findsNothing);

      fake.setPhase(TripRecordingPhase.pausedDueToDrop);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('obd2PauseBanner')), findsOneWidget);
      expect(
        find.text('OBD2 connection lost — recording paused'),
        findsOneWidget,
      );
    });

    testWidgets('Resume action calls provider.resume()', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );

      expect(fake.resumeCalls, 0);
      await tester.tap(find.byKey(const Key('obd2PauseBannerResume')));
      await tester.pumpAndSettle();
      expect(fake.resumeCalls, 1);
      expect(fake.stopCalls, 0);
    });

    testWidgets('End action calls provider.stop()', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );

      expect(fake.stopCalls, 0);
      await tester.tap(find.byKey(const Key('obd2PauseBannerEnd')));
      await tester.pumpAndSettle();
      expect(fake.stopCalls, 1);
      expect(fake.resumeCalls, 0);
    });

    testWidgets('disappears when phase returns to recording', (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );
      expect(find.byKey(const Key('obd2PauseBanner')), findsOneWidget);

      fake.setPhase(TripRecordingPhase.recording);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('obd2PauseBanner')), findsNothing);
    });

    testWidgets('disappears when phase returns to idle after End',
        (tester) async {
      final fake = _FakeTripRecording(
        const TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop),
      );
      await pumpApp(
        tester,
        const _Host(),
        overrides: [
          tripRecordingProvider.overrideWith(() => fake),
        ],
      );
      expect(find.byKey(const Key('obd2PauseBanner')), findsOneWidget);

      // The real provider's stop() completes by setting state to
      // finished. Simulate that here so the banner tears down.
      fake.setPhase(TripRecordingPhase.finished);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('obd2PauseBanner')), findsNothing);
    });
  });
}
