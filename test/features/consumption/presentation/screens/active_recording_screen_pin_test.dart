import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';

import '../../../../helpers/pump_app.dart';

/// #891 — pin toggle on the active-recording screen must:
/// - swap the icon (outlined ↔ filled) and flip the semantic label.
/// - call `enable()` exactly once on pin, `disable()` exactly once on
///   unpin — we don't want every frame to hammer the platform channel.
/// - auto-release the lock when the recording stops, even if the user
///   never tapped unpin.
/// - hit the 48dp Material tap-target guideline.

class _FakeWakelockFacade implements WakelockFacade {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async {
    enableCalls++;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
  }
}

/// Pinnable fake — start in `recording`, let tests call `stop()` to
/// flip to `finished` without hitting the real Obd2 stack.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

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

TripRecordingState _recordingState() {
  return const TripRecordingState(
    phase: TripRecordingPhase.recording,
    situation: DrivingSituation.highwayCruise,
    band: ConsumptionBand.normal,
  );
}

Future<void> _pumpRecordingScreen(
  WidgetTester tester, {
  required _FakeWakelockFacade facade,
}) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _FakeTripRecording(_recordingState()),
      ),
      wakelockFacadeProvider.overrideWithValue(facade),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen pin toggle (#891)', () {
    testWidgets('starts unpinned: outlined pin icon + "Pin" semantic',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      final pinButton = find.byKey(const Key('tripPinButton'));
      expect(pinButton, findsOneWidget);
      expect(
        find.descendant(
          of: pinButton,
          matching: find.byIcon(Icons.push_pin_outlined),
        ),
        findsOneWidget,
      );
      // Sanity: nothing has been enabled/disabled yet.
      expect(facade.enableCalls, 0);
      expect(facade.disableCalls, 0);
    });

    testWidgets('tapping pin swaps icon to filled + calls enable() once',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('tripPinButton')),
          matching: find.byIcon(Icons.push_pin),
        ),
        findsOneWidget,
      );
      expect(facade.enableCalls, 1);
      expect(facade.disableCalls, 0);
    });

    testWidgets('tapping pin a second time calls disable() once '
        'and restores the outlined icon', (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      final pin = find.byKey(const Key('tripPinButton'));
      await tester.tap(pin);
      await tester.pumpAndSettle();
      await tester.tap(pin);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: pin,
          matching: find.byIcon(Icons.push_pin_outlined),
        ),
        findsOneWidget,
      );
      expect(facade.enableCalls, 1);
      expect(facade.disableCalls, 1);
    });

    testWidgets('recording stop auto-releases the wake lock '
        'even if the user forgot to unpin', (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      // Pin first.
      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();
      expect(facade.enableCalls, 1);
      expect(facade.disableCalls, 0);

      // Stop the recording — this should auto-release without a
      // second user gesture on the pin toggle.
      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();

      expect(facade.disableCalls, 1,
          reason: 'stop must auto-release the wake lock');
    });

    testWidgets('screen dispose releases the lock when the user '
        'forgot to unpin before navigating away', (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();
      expect(facade.disableCalls, 0);

      // Replace the widget tree — triggers dispose on the screen.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(facade.disableCalls, 1,
          reason: 'dispose must also release the lock as a safety net');
    });

    testWidgets('pin button meets the Android tap-target guideline',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('semantic label flips between Pin / Unpin when toggled',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      // When unpinned, Semantics label should read "Pin recording form".
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Pin recording form'),
        findsOneWidget,
        reason: 'Pin toggle should expose "Pin recording form" when unpinned',
      );

      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Unpin recording form'),
        findsOneWidget,
        reason: 'Pin toggle should expose "Unpin recording form" when pinned',
      );
      handle.dispose();
    });
  });
}
