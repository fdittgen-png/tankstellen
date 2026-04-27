import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';

import '../../../../helpers/pump_app.dart';

/// Regression coverage for #1185 — the Trip-summary CTA must save a
/// trip as a consumption record, NOT pretend to be a fill-up.
///
/// The trip itself is persisted by [TripRecording.stop()] (already
/// covered upstream in the provider tests). What this file pins down
/// is the post-stop summary screen behaviour:
///
///  1. Button label reads "Save trip" via [AppLocalizations.tripSaveRecording]
///     — the legacy "Save as fill-up" copy is gone.
///  2. Tapping the button pops the screen with a [TripSaveResult] whose
///     `entryId` matches the id [TripRecording._saveToHistory] would
///     have used (ISO start timestamp).
///  3. Tapping the button does NOT push [AddFillUpScreen] — a trip and
///     a fill-up are different domain entities.
///
/// We don't drive the live recording loop here — instead we hand the
/// fake `stop()` a deterministic [StoppedTripResult] so the save path
/// runs without a real OBD2 stack.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _StoppingFakeTripRecording extends TripRecording {
  _StoppingFakeTripRecording(this._stoppedResult);

  final StoppedTripResult _stoppedResult;
  int resetCalls = 0;

  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.recording,
        situation: DrivingSituation.highwayCruise,
        band: ConsumptionBand.normal,
      );

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return _stoppedResult;
  }

  @override
  void reset() {
    resetCalls++;
    state = const TripRecordingState();
  }
}

/// Builds a deterministic [StoppedTripResult] with a known
/// `startedAt` so the assertion on [TripSaveResult.entryId] is stable.
StoppedTripResult _stoppedAt(DateTime startedAt) {
  return StoppedTripResult(
    summary: TripSummary(
      distanceKm: 2.95,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 9.1,
      fuelLitersConsumed: 0.27,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 5)),
    ),
    odometerStartKm: 12000,
    odometerLatestKm: 12003,
  );
}

Future<void> _pumpAndStop(
  WidgetTester tester, {
  required _StoppingFakeTripRecording notifier,
  Object? popResult,
}) async {
  // Wrap the screen in a Navigator so we can capture the pop value the
  // save handler emits — and so the screen has a route to pop.
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        key: const Key('open_trip_screen'),
        onPressed: () async {
          final result = await Navigator.of(context).push<TripSaveResult?>(
            MaterialPageRoute(
              builder: (_) => const TripRecordingScreen(),
            ),
          );
          popResult = result;
        },
        child: const Text('Open'),
      ),
    ),
    overrides: [
      tripRecordingProvider.overrideWith(() => notifier),
      wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
    ],
  );

  await tester.tap(find.byKey(const Key('open_trip_screen')));
  await tester.pumpAndSettle();

  // Tap stop → the fake's `stop()` resolves with the canned result and
  // the screen flips into the summary view.
  await tester.tap(find.byKey(const Key('tripStopButton')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen save (#1185)', () {
    testWidgets('summary CTA reads "Save trip" — not "Save as fill-up"',
        (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8)),
      );
      await _pumpAndStop(tester, notifier: notifier);

      // New, semantic label.
      expect(find.text('Save trip'), findsOneWidget);
      // Legacy "fill-up" copy must not survive the rename.
      expect(find.text('Save as fill-up'), findsNothing);
      // The save button keeps its key so existing tests / accessibility
      // tooling can still find it.
      expect(find.byKey(const Key('tripSaveButton')), findsOneWidget);
    });

    testWidgets('tapping Save trip pops with a TripSaveResult carrying '
        'the persisted entry id', (tester) async {
      final startedAt = DateTime.utc(2026, 4, 27, 8);
      final notifier = _StoppingFakeTripRecording(_stoppedAt(startedAt));

      // Capture the popped value via the GlobalKey-less Navigator
      // pattern: a Builder pushes the screen, awaits the pop, and
      // we read the result from a closure-scoped variable.
      TripSaveResult? captured;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_trip_screen'),
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<TripSaveResult?>(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
              captured = result;
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(() => notifier),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        ],
      );

      await tester.tap(find.byKey(const Key('open_trip_screen')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tripSaveButton')));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      // Id derivation must mirror `TripRecording._saveToHistory` so
      // the popped result resolves to the persisted entry.
      expect(captured!.entryId, startedAt.toIso8601String());
      // Summary forwarded — the caller can use it for an immediate
      // refresh / scroll-to without re-reading from Hive.
      expect(captured!.summary.distanceKm, 2.95);
      expect(captured!.summary.fuelLitersConsumed, 0.27);
      // The provider must be reset so the next recording starts clean.
      expect(notifier.resetCalls, 1);
    });

    testWidgets('tapping Save trip does NOT push AddFillUpScreen '
        '(trip-as-consumption-record fix)', (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8)),
      );
      await _pumpAndStop(tester, notifier: notifier);

      expect(find.byType(AddFillUpScreen), findsNothing,
          reason: 'Pre-save sanity: AddFillUpScreen must not be on the stack');

      await tester.tap(find.byKey(const Key('tripSaveButton')));
      await tester.pumpAndSettle();

      // After save: still no AddFillUpScreen — saving a trip MUST NOT
      // funnel the user into the fill-up creation flow (#1185).
      expect(find.byType(AddFillUpScreen), findsNothing,
          reason: 'Saving a trip must not push AddFillUpScreen — a '
              'trip is a consumption record, not a refuel event.');
    });

    testWidgets('discard does not pop a TripSaveResult', (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8)),
      );
      TripSaveResult? captured;
      Object? sentinel = const Object();
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_trip_screen'),
            onPressed: () async {
              final result = await Navigator.of(context)
                  .push<TripSaveResult?>(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
              captured = result;
              sentinel = null;
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(() => notifier),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        ],
      );

      await tester.tap(find.byKey(const Key('open_trip_screen')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tripDiscardButton')));
      await tester.pumpAndSettle();

      expect(sentinel, isNull,
          reason: 'Discard must complete the push so the caller resumes');
      expect(captured, isNull,
          reason: 'Discard pops with null — no TripSaveResult');
    });
  });
}
