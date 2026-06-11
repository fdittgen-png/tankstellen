// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import '../../../../helpers/silence_error_logger.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/recording_profile_override.dart';

/// #891 — pin toggle on the active-recording screen must:
/// - swap the icon (outlined ↔ filled) and flip the semantic label.
/// - call `enable()` exactly once on pin, `disable()` exactly once on
///   unpin — we don't want every frame to hammer the platform channel.
/// - auto-release the lock when the recording stops, even if the user
///   never tapped unpin.
/// - hit the 48dp Material tap-target guideline.
///
/// #2764 — Pin now lives inside the trailing overflow kebab
/// (`recording_overflow_menu`) rather than as a primary AppBar
/// IconButton, so these tests open the kebab before reaching the pin
/// item. The item keeps its `tripPinButton` key + the Pin/Unpin
/// semantics, so the behavioural assertions are unchanged.

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
      // #2785 — these tests exercise the MANUAL pin toggle from an unpinned
      // start, so pin the profile to auto-pin OFF (the global default is now ON).
      recordingProfileOverride() as Object,
    ],
  );
}

/// #2764 — open the trailing overflow kebab so the Pin item is mounted.
Future<void> _openOverflow(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('recording_overflow_menu')));
  await tester.pumpAndSettle();
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen pin toggle (#891)', () {
    testWidgets('starts unpinned: outlined pin icon + "Pin" semantic',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);
      await _openOverflow(tester);

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

      await _openOverflow(tester);
      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();

      // Selecting the item closes the menu; re-open to read the icon,
      // which must now be the filled (pinned) variant.
      await _openOverflow(tester);
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
      await _openOverflow(tester);
      await tester.tap(pin);
      await tester.pumpAndSettle();
      // Re-open the menu for the second toggle (the first selection
      // closed it).
      await _openOverflow(tester);
      await tester.tap(pin);
      await tester.pumpAndSettle();

      await _openOverflow(tester);
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

      // Pin first (via the overflow kebab).
      await _openOverflow(tester);
      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();
      expect(facade.enableCalls, 1);
      expect(facade.disableCalls, 0);

      // Stop the recording (a primary, always-visible action) — this
      // should auto-release without a second user gesture on the pin.
      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();

      expect(facade.disableCalls, 1,
          reason: 'stop must auto-release the wake lock');
    });

    testWidgets('screen dispose releases the lock when the user '
        'forgot to unpin before navigating away', (tester) async {
      final facade = _FakeWakelockFacade();
      await _pumpRecordingScreen(tester, facade: facade);

      await _openOverflow(tester);
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
      // Open the kebab so the pin item is on screen and audited.
      await _openOverflow(tester);

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
      await _openOverflow(tester);
      expect(
        find.bySemanticsLabel('Pin recording form'),
        findsOneWidget,
        reason: 'Pin toggle should expose "Pin recording form" when unpinned',
      );

      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();

      // Re-open the kebab; the item must now read "Unpin recording form".
      await _openOverflow(tester);
      expect(
        find.bySemanticsLabel('Unpin recording form'),
        findsOneWidget,
        reason: 'Pin toggle should expose "Unpin recording form" when pinned',
      );
      handle.dispose();
    });
  });
}
