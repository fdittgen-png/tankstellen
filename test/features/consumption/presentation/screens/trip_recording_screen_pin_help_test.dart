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

/// #1273 — pin-help bottom sheet:
///   * `?` icon (key `tripPinHelpButton`) sits next to the pin button.
///   * Tapping it opens a [showModalBottomSheet] containing the title
///     + body copy from the issue acceptance.
///   * Affordance is independent of the eco-coach toggle.

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen pin-help affordance (#1273)', () {
    Future<void> pumpScreen(WidgetTester tester) async {
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
    }

    testWidgets('? icon is present alongside the pin button',
        (tester) async {
      await pumpScreen(tester);

      expect(
        find.byKey(const Key('tripPinButton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tripPinHelpButton')),
        findsOneWidget,
        reason:
            'A `?` icon must sit next to the pin button so first-time '
            'users discover what pin does (#1273).',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('tripPinHelpButton')),
          matching: find.byIcon(Icons.help_outline),
        ),
        findsOneWidget,
        reason:
            'Help affordance must use the standard help_outline glyph '
            'so users recognise it without reading the tooltip.',
      );
    });

    testWidgets(
        'tapping ? opens a modal bottom sheet with the help title + '
        'body copy', (tester) async {
      await pumpScreen(tester);

      // Pre-tap: the help body is NOT on screen (no sheet open).
      expect(
        find.text('About the pin button'),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('tripPinHelpButton')));
      await tester.pumpAndSettle();

      // Post-tap: the modal title is visible.
      expect(
        find.text('About the pin button'),
        findsOneWidget,
        reason: 'Sheet must show the localized title from the ARB.',
      );
      // And the body explains pin behaviour as the issue copy spells out.
      expect(
        find.textContaining('keeps the screen on'),
        findsOneWidget,
        reason:
            'Body must mention the wakelock effect — that is the '
            'whole reason a user might want this explainer.',
      );
      expect(
        find.textContaining('Auto-releases when the trip stops'),
        findsOneWidget,
        reason:
            'Body must surface the auto-release safety net so users '
            'know they cannot leave the wakelock on after a trip.',
      );
      // Got-it dismiss button is reachable.
      expect(find.text('Got it'), findsOneWidget);
    });
  });
}
