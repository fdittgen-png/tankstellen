import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/driving/coach_event.dart';
import 'package:tankstellen/features/driving/providers/haptic_eco_coach_provider.dart';

import '../../../../helpers/pump_app.dart';

/// #1273 — resume-help one-time SnackBar:
///   * Shown the first time the user backs out of the recording
///     screen while the trip is still active.
///   * Persists dismissal in [SettingsStorage] under
///     [StorageKeys.tripRecordingResumeTipShown].
///   * Does NOT show again on a subsequent back-out.

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

const TripRecordingState _activeRecording = TripRecordingState(
  phase: TripRecordingPhase.recording,
  situation: DrivingSituation.highwayCruise,
  band: ConsumptionBand.normal,
);

/// Wrap [TripRecordingScreen] in a tiny pushable host so the back
/// button has a route to pop. Returns the settings storage so tests
/// can inspect the persisted flag.
Future<_FakeSettingsStorage> _pumpHost(WidgetTester tester) async {
  final settings = _FakeSettingsStorage();
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        key: const Key('open_trip_screen'),
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const TripRecordingScreen()),
          );
        },
        child: const Text('Open'),
      ),
    ),
    overrides: [
      tripRecordingProvider
          .overrideWith(() => _FakeTripRecording(_activeRecording)),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      coachEventsProvider
          .overrideWith((ref) => const Stream<CoachEvent>.empty()),
      settingsStorageProvider.overrideWithValue(settings),
    ],
  );

  await tester.tap(find.byKey(const Key('open_trip_screen')));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen resume-help one-time tip (#1273)', () {
    testWidgets(
        'first back-out while the trip is active surfaces the resume tip '
        'and persists the flag', (tester) async {
      final settings = await _pumpHost(tester);

      // Pre-condition: the flag is unset.
      expect(
        settings.data[StorageKeys.tripRecordingResumeTipShown],
        isNull,
        reason: 'Pre-condition: flag must be unset before first back-out.',
      );

      // Tap the back arrow on the AppBar.
      // Use a precise finder — the AppBar back button is the only
      // IconButton on screen with Icons.arrow_back, so byIcon is the
      // safest disambiguator (the screen also has a leading "Open"
      // button on the host, etc.).
      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pump();
      // Allow the SnackBar enter animation to complete enough for the
      // text to be findable, but don't pumpAndSettle (the SnackBar
      // would auto-dismiss after its 6 s duration).
      await tester.pump(const Duration(milliseconds: 100));

      // Material 3's SnackBar enter animation can keep both the
      // outgoing (default) and incoming SnackBar mounted briefly —
      // assert "at least one" rather than "exactly one" so the test
      // is not flaky on framework upgrades.
      expect(
        find.byKey(const Key('tripResumeTipSnackBar')),
        findsAtLeastNWidgets(1),
        reason: 'First mid-trip back-out must surface the resume tip.',
      );
      expect(
        find.textContaining('Recording continues in the background'),
        findsAtLeastNWidgets(1),
        reason:
            'Tip copy must point the user at the persistent banner — '
            'that is the user\'s only path back into the recording '
            'screen once they have left it.',
      );
      expect(
        settings.data[StorageKeys.tripRecordingResumeTipShown],
        isTrue,
        reason:
            'Flag must flip to true on display so the tip never '
            'resurfaces on this install.',
      );
    });

    testWidgets(
        'second back-out does NOT show the tip — flag is honoured',
        (tester) async {
      // Pre-set the flag so we land in the "already shown once" state.
      final preSeed = _FakeSettingsStorage()
        ..data[StorageKeys.tripRecordingResumeTipShown] = true;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_trip_screen'),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                    builder: (_) => const TripRecordingScreen()),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider
              .overrideWith(() => _FakeTripRecording(_activeRecording)),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          coachEventsProvider
              .overrideWith((ref) => const Stream<CoachEvent>.empty()),
          settingsStorageProvider.overrideWithValue(preSeed),
        ],
      );

      await tester.tap(find.byKey(const Key('open_trip_screen')));
      await tester.pumpAndSettle();

      // Use a precise finder — the AppBar back button is the only
      // IconButton on screen with Icons.arrow_back, so byIcon is the
      // safest disambiguator (the screen also has a leading "Open"
      // button on the host, etc.).
      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const Key('tripResumeTipSnackBar')),
        findsNothing,
        reason:
            'Flag-already-true means the tip must NEVER resurface — '
            'persistent UX, not a flicker the user has to dismiss '
            'again on every back-out.',
      );
    });
  });
}
