import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/driving/haptic_eco_coach.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #1273 — visual eco-coach SnackBar + pin help bottom sheet + one-time
/// resume tooltip.
///
/// These tests pin the screen-side wiring of the three sub-features:
///
///   * SnackBar appears when the lifecycle provider emits a [CoachEvent]
///     while the recording screen is mounted.
///   * SnackBar does NOT appear after the screen has been disposed
///     (i.e. user navigated to summary / history / home).
///   * Tapping the `?` icon adjacent to the pin opens a bottom sheet.
///   * On the FIRST back-out while recording, the resume tooltip
///     SnackBar appears AND the dismissal is persisted.
///   * Subsequent back-outs (Hive flag = true) silently pop with no
///     tooltip.
///
/// To exercise the SnackBar wiring we override the
/// [hapticEcoCoachLifecycleProvider] with a fake whose `coachEvents`
/// stream we control directly. The real provider's emission gating
/// (toggle-off → no events) is covered in the provider-level test;
/// here we confirm the screen handles whatever the provider hands it.

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

/// Fake lifecycle that bypasses Riverpod's `keepAlive` machinery. We
/// override the public `coachEvents` getter via a controller the test
/// holds, so the test can pump events at any moment to exercise the
/// screen subscription.
class _FakeHapticEcoCoachLifecycle extends HapticEcoCoachLifecycle {
  _FakeHapticEcoCoachLifecycle(this._controller);

  final StreamController<CoachEvent> _controller;

  @override
  Stream<CoachEvent> get coachEvents => _controller.stream;

  @override
  void build() {
    // Skip the real wiring — we control emission directly through
    // `_controller` so the screen's subscription runs in isolation.
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
  required StreamController<CoachEvent> coachEventsController,
  TripRecordingState? state,
}) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(
        () => _FakeTripRecording(state ?? _recordingState()),
      ),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      hapticEcoCoachLifecycleProvider
          .overrideWith(() => _FakeHapticEcoCoachLifecycle(
                coachEventsController,
              )),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen visual eco-coach SnackBar (#1273)', () {
    late StreamController<CoachEvent> events;

    setUp(() {
      events = StreamController<CoachEvent>.broadcast();
    });

    tearDown(() async {
      await events.close();
    });

    testWidgets('emits SnackBar with the expected copy when the lifecycle '
        'provider pushes a CoachEvent', (tester) async {
      await _pumpRecordingScreen(tester, coachEventsController: events);

      // Sanity: no SnackBar before any event.
      expect(find.byKey(const Key('hapticEcoCoachSnackBar')), findsNothing);
      expect(
        find.text('Easy on the throttle — coasting saves more'),
        findsNothing,
      );

      // Push a fire decision through the lifecycle stream.
      events.add(CoachEvent(triggeredAt: DateTime(2026, 4, 28, 12)));
      // pump+pump(50ms) per Hive widget-test convention; SnackBar
      // entry animation runs in 250ms so we pump generously.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const Key('hapticEcoCoachSnackBar')),
        findsOneWidget,
        reason: 'SnackBar must appear when the lifecycle stream pushes an '
            'event while the recording screen is mounted.',
      );
      expect(
        find.text('Easy on the throttle — coasting saves more'),
        findsOneWidget,
        reason: 'SnackBar carries the localized eco-coach copy.',
      );
    });

    testWidgets('SnackBar disappears after navigating away — events emitted '
        'after dispose do NOT show on the next route', (tester) async {
      // Mount inside a Navigator so we can pop the recording screen
      // and verify a subsequent event doesn't surface anywhere.
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('openRecordingScreen'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_recordingState()),
          ),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          hapticEcoCoachLifecycleProvider
              .overrideWith(() => _FakeHapticEcoCoachLifecycle(events)),
        ],
      );

      await tester.tap(find.byKey(const Key('openRecordingScreen')));
      await tester.pumpAndSettle();

      // While mounted: event surfaces.
      events.add(CoachEvent(triggeredAt: DateTime(2026, 4, 28, 12)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const Key('hapticEcoCoachSnackBar')), findsOneWidget);

      // Dismiss the existing SnackBar so the next assertion isn't
      // confused by lingering state.
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('hapticEcoCoachSnackBar'))),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Pop back to the launcher — disposes the recording screen.
      Navigator.of(tester.element(find.byKey(const Key('tripPinButton'))))
          .pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripPinButton')), findsNothing,
          reason: 'recording screen must be off-screen now');

      // Emit another event — nothing should show on the launcher
      // route. Defense-in-depth: the only subscriber was the
      // recording-screen state, which is disposed.
      events.add(CoachEvent(triggeredAt: DateTime(2026, 4, 28, 12, 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byKey(const Key('hapticEcoCoachSnackBar')),
        findsNothing,
        reason: 'After dispose, post-dispose events must not surface — '
            'the subscription is the only path to the SnackBar.',
      );
    });
  });

  group('TripRecordingScreen pin help (#1273)', () {
    late StreamController<CoachEvent> events;

    setUp(() {
      events = StreamController<CoachEvent>.broadcast();
    });

    tearDown(() async {
      await events.close();
    });

    testWidgets('tapping the ? icon opens a bottom sheet with the pin help '
        'copy', (tester) async {
      await _pumpRecordingScreen(tester, coachEventsController: events);

      final helpButton = find.byKey(const Key('tripPinHelpButton'));
      expect(helpButton, findsOneWidget,
          reason: 'pin help button must be in the AppBar actions');

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      // Title in the bottom sheet.
      expect(find.text('About pin'), findsOneWidget);
      // Body in the bottom sheet — assert via `textContaining` so a
      // trailing space / line break shift doesn't break the test.
      expect(
        find.textContaining('keeps the screen on'),
        findsOneWidget,
        reason: 'Body must explain what pin does in user-facing copy.',
      );
    });

    testWidgets('? icon is visible regardless of whether the pin is on or off',
        (tester) async {
      await _pumpRecordingScreen(tester, coachEventsController: events);

      // Unpinned: help button visible.
      expect(find.byKey(const Key('tripPinHelpButton')), findsOneWidget);

      // Pin → help still visible.
      await tester.tap(find.byKey(const Key('tripPinButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tripPinHelpButton')), findsOneWidget);
    });
  });

  group('TripRecordingScreen one-time resume tooltip (#1273)', () {
    late StreamController<CoachEvent> events;

    setUp(() {
      events = StreamController<CoachEvent>.broadcast();
    });

    tearDown(() async {
      await events.close();
    });

    testWidgets('first back-out while recording shows the tooltip and '
        'persists the dismissal', (tester) async {
      // Use an in-memory fake instead of real Hive to keep the test
      // hermetic and avoid the well-known Windows hang during Hive
      // tearDown (feedback_hive_widget_test_teardown.md). The
      // persistence contract is the same — `getSetting` / `putSetting`
      // round-trip through whatever the provider hands us.
      final settings = _FakeSettingsStorage();
      // Sanity: the flag must start absent.
      expect(
        settings.getSetting(StorageKeys.tripRecordingResumeHintShown),
        isNull,
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('openRecordingScreen'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_recordingState()),
          ),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          hapticEcoCoachLifecycleProvider
              .overrideWith(() => _FakeHapticEcoCoachLifecycle(events)),
          settingsStorageProvider.overrideWithValue(settings),
        ],
      );

      await tester.tap(find.byKey(const Key('openRecordingScreen')));
      await tester.pumpAndSettle();

      // Tap the AppBar back button (the leading IconButton with the
      // back arrow tooltip).
      await tester.tap(find.byTooltip('Back'));
      // Don't `pumpAndSettle` immediately — the SnackBar must surface
      // before the pop animation completes. Pump a couple of frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const Key('tripRecordingResumeHintSnackBar')),
        findsAtLeastNWidgets(1),
        reason: 'First back-out while recording must show the resume hint. '
            'Use findsAtLeast because the SnackBar can transiently appear '
            'twice in the widget tree during the pop transition.',
      );
      expect(
        find.textContaining('Tap the red banner'),
        findsAtLeastNWidgets(1),
        reason: 'SnackBar carries the localized resume copy.',
      );

      // Allow the pop animation to finish so the persistence write
      // settles.
      await tester.pumpAndSettle();
      expect(
        settings.data[StorageKeys.tripRecordingResumeHintShown],
        isTrue,
        reason:
            'Dismissal must be persisted after the first back-out so the '
            'tooltip never fires twice.',
      );
    });

    testWidgets('subsequent back-out (flag = true) does NOT show the tooltip',
        (tester) async {
      final settings = _FakeSettingsStorage()
        ..data[StorageKeys.tripRecordingResumeHintShown] = true;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('openRecordingScreen'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(
            () => _FakeTripRecording(_recordingState()),
          ),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          hapticEcoCoachLifecycleProvider
              .overrideWith(() => _FakeHapticEcoCoachLifecycle(events)),
          settingsStorageProvider.overrideWithValue(settings),
        ],
      );

      await tester.tap(find.byKey(const Key('openRecordingScreen')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const Key('tripRecordingResumeHintSnackBar')),
        findsNothing,
        reason: 'Returning users with the persisted flag must back-out '
            'without seeing the tooltip again.',
      );
    });
  });
}

/// In-memory fake of [SettingsStorage] for tests that want to verify
/// the persistence contract without spinning up Hive (which can hang
/// on Windows during tearDown — feedback_hive_widget_test_teardown.md).
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
