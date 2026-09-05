// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/trips/domain/situation_classifier.dart';
import 'package:tankstellen/features/trips/data/trip_history_repository.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/add_fill_up_screen.dart';
import 'package:tankstellen/features/trips/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/trips/providers/wakelock_facade.dart';
import '../../../../helpers/silence_error_logger.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/recording_profile_override.dart';

/// Regression coverage for #1185 and #3963 — stopping a recording saves
/// the trip as a consumption record and puts the user back in the list.
///
/// The trip is persisted by [TripRecording.stop()] (covered upstream in
/// the provider tests). What this file pins is what STOP does on screen:
///
///  1. #3963 — it pops. There is no summary form to dismiss: a driver
///     should never have to confirm a save.
///  2. It pops a [TripSaveResult] whose `entryId` mirrors the id
///     [TripRecording._saveToHistory] used (ISO start timestamp), and it
///     resets the provider so the next recording starts clean.
///  3. It does NOT push [AddFillUpScreen] — a trip and a fill-up are
///     different domain entities (#1185).
///  4. #3582/#3963 — the confirmation snackbar's Delete removes the
///     PERSISTED entry, which is the honest delete the summary owned.
///  5. #2509 — a stop that saved nothing says so instead.
///
/// We don't drive the live recording loop here — the fake `stop()`
/// returns a deterministic [StoppedTripResult] so the path runs without
/// a real OBD2 stack.

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

/// Records the ids the snackbar's Delete asks the repository to remove.
class _RecordingTripHistoryRepository implements TripHistoryRepository {
  final List<String> deleted = <String>[];

  @override
  Future<void> delete(String id) async => deleted.add(id);

  @override
  void Function(TripHistoryEntry entry)? onSavedHook;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '_RecordingTripHistoryRepository.${invocation.memberName} '
        'was not expected to be called by the stop flow',
      );
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
StoppedTripResult _stoppedAt(
  DateTime startedAt, {
  bool discardedNoMovement = false,
}) {
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
    discardedNoMovement: discardedNoMovement,
  );
}

Future<void> _pumpAndStop(
  WidgetTester tester, {
  required _StoppingFakeTripRecording notifier,
  _RecordingTripHistoryRepository? repo,
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
      recordingProfileOverride() as Object,
      if (repo != null) tripHistoryRepositoryProvider.overrideWithValue(repo),
    ],
  );

  await tester.tap(find.byKey(const Key('open_trip_screen')));
  await tester.pumpAndSettle();

  // Tap stop → the fake's `stop()` resolves with the canned result and
  // the screen pops straight back (#3963).
  await tester.tap(find.byKey(const Key('tripStopButton')));
  await tester.pumpAndSettle();
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen save (#1185)', () {
    testWidgets('#3963 — stop pops: there is no summary form to dismiss',
        (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8)),
      );
      await _pumpAndStop(tester, notifier: notifier);

      expect(find.byType(TripRecordingScreen), findsNothing);
      expect(find.byKey(const Key('tripSaveButton')), findsNothing);
      expect(find.byKey(const Key('tripDiscardButton')), findsNothing);
      // The save is confirmed where the user now is, not on a screen.
      expect(find.byKey(const Key('tripSavedSnackBar')), findsOneWidget);
    });

    testWidgets('stop pops with a TripSaveResult carrying the persisted '
        'entry id, and resets the provider', (tester) async {
      final startedAt = DateTime.utc(2026, 4, 27, 8);
      final notifier = _StoppingFakeTripRecording(_stoppedAt(startedAt));

      TripSaveResult? captured;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open_trip_screen'),
            onPressed: () async {
              captured = await Navigator.of(context).push<TripSaveResult?>(
                MaterialPageRoute(
                  builder: (_) => const TripRecordingScreen(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        overrides: [
          tripRecordingProvider.overrideWith(() => notifier),
          wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
          recordingProfileOverride() as Object,
        ],
      );

      await tester.tap(find.byKey(const Key('open_trip_screen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tripStopButton')));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      // Id derivation mirrors `TripRecording._saveToHistory` so the popped
      // result resolves to the persisted entry.
      expect(captured!.entryId, startedAt.toIso8601String());
      expect(captured!.summary.distanceKm, 2.95);
      expect(captured!.summary.fuelLitersConsumed, 0.27);
      expect(notifier.resetCalls, 1);
    });

    testWidgets('stop does NOT push AddFillUpScreen '
        '(trip-as-consumption-record fix, #1185)', (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8)),
      );
      await _pumpAndStop(tester, notifier: notifier);

      expect(find.byType(AddFillUpScreen), findsNothing,
          reason: 'Saving a trip must not funnel the user into the '
              'fill-up creation flow — a trip is a consumption record.');
    });

    testWidgets("#3582 — the snackbar's Delete removes the PERSISTED entry, "
        'not just the UI', (tester) async {
      final startedAt = DateTime.utc(2026, 4, 27, 8);
      final repo = _RecordingTripHistoryRepository();
      final notifier = _StoppingFakeTripRecording(_stoppedAt(startedAt));
      await _pumpAndStop(tester, notifier: notifier, repo: repo);

      await tester.tap(find.text('Delete this trip'));
      await tester.pumpAndSettle();

      expect(repo.deleted, [startedAt.toIso8601String()]);
    });

    testWidgets('#2509 — a stop that saved nothing says so, and offers no '
        'delete', (tester) async {
      final notifier = _StoppingFakeTripRecording(
        _stoppedAt(DateTime.utc(2026, 4, 27, 8), discardedNoMovement: true),
      );
      await _pumpAndStop(tester, notifier: notifier);

      expect(find.byKey(const Key('tripSavedSnackBar')), findsNothing);
      expect(find.text('Delete this trip'), findsNothing);
    });
  });
}
