import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';

void main() {
  group('TripRecordingState default constructor', () {
    test('fields default to idle/null/normal', () {
      const state = TripRecordingState();
      expect(state.phase, TripRecordingPhase.idle);
      expect(state.live, isNull);
      expect(state.situation, DrivingSituation.idle);
      expect(state.band, ConsumptionBand.normal);
      expect(state.liveDeltaFraction, isNull);
    });

    test('isActive is false on default (idle)', () {
      const state = TripRecordingState();
      expect(state.isActive, isFalse);
    });
  });

  group('TripRecordingState.copyWith', () {
    const baseLive = TripLiveReading(
      distanceKmSoFar: 1.0,
      elapsed: Duration(seconds: 30),
    );
    const base = TripRecordingState(
      phase: TripRecordingPhase.recording,
      live: baseLive,
      situation: DrivingSituation.urbanCruise,
      band: ConsumptionBand.eco,
      liveDeltaFraction: -0.05,
    );

    test('changing only phase preserves other fields', () {
      final next = base.copyWith(phase: TripRecordingPhase.paused);
      expect(next.phase, TripRecordingPhase.paused);
      expect(next.live, same(baseLive));
      expect(next.situation, DrivingSituation.urbanCruise);
      expect(next.band, ConsumptionBand.eco);
      expect(next.liveDeltaFraction, -0.05);
    });

    test('changing only live preserves other fields', () {
      const newReading = TripLiveReading(
        distanceKmSoFar: 2.5,
        elapsed: Duration(minutes: 1),
      );
      final next = base.copyWith(live: newReading);
      expect(next.live, same(newReading));
      expect(next.phase, TripRecordingPhase.recording);
      expect(next.situation, DrivingSituation.urbanCruise);
      expect(next.band, ConsumptionBand.eco);
      expect(next.liveDeltaFraction, -0.05);
    });

    test('changing only situation preserves other fields', () {
      final next = base.copyWith(situation: DrivingSituation.highwayCruise);
      expect(next.situation, DrivingSituation.highwayCruise);
      expect(next.phase, TripRecordingPhase.recording);
      expect(next.live, same(baseLive));
      expect(next.band, ConsumptionBand.eco);
      expect(next.liveDeltaFraction, -0.05);
    });

    test('changing only band preserves other fields', () {
      final next = base.copyWith(band: ConsumptionBand.heavy);
      expect(next.band, ConsumptionBand.heavy);
      expect(next.phase, TripRecordingPhase.recording);
      expect(next.live, same(baseLive));
      expect(next.situation, DrivingSituation.urbanCruise);
      expect(next.liveDeltaFraction, -0.05);
    });

    test('changing only liveDeltaFraction preserves other fields', () {
      final next = base.copyWith(liveDeltaFraction: 0.08);
      expect(next.liveDeltaFraction, 0.08);
      expect(next.phase, TripRecordingPhase.recording);
      expect(next.live, same(baseLive));
      expect(next.situation, DrivingSituation.urbanCruise);
      expect(next.band, ConsumptionBand.eco);
    });

    test('clearDelta: true forces liveDeltaFraction to null '
        'even when original was non-null', () {
      final next = base.copyWith(clearDelta: true);
      expect(next.liveDeltaFraction, isNull);
      // Other fields still preserved.
      expect(next.phase, TripRecordingPhase.recording);
      expect(next.live, same(baseLive));
    });

    test('clearDelta: true overrides an explicit liveDeltaFraction value', () {
      final next = base.copyWith(
        clearDelta: true,
        liveDeltaFraction: 0.1,
      );
      expect(next.liveDeltaFraction, isNull);
    });

    test('copyWith(live: ...) on state with null live adds the reading', () {
      const empty = TripRecordingState();
      const reading = TripLiveReading(
        distanceKmSoFar: 0.5,
        elapsed: Duration(seconds: 15),
      );
      final next = empty.copyWith(live: reading);
      expect(next.live, same(reading));
    });

    test('copyWith(live: ...) on state with existing live replaces it', () {
      const newReading = TripLiveReading(
        distanceKmSoFar: 10.0,
        elapsed: Duration(minutes: 5),
      );
      final next = base.copyWith(live: newReading);
      expect(next.live, same(newReading));
      expect(next.live, isNot(same(baseLive)));
    });
  });

  group('TripRecordingState.isActive', () {
    test('true when phase is recording', () {
      const state =
          TripRecordingState(phase: TripRecordingPhase.recording);
      expect(state.isActive, isTrue);
    });

    test('true when phase is paused', () {
      const state = TripRecordingState(phase: TripRecordingPhase.paused);
      expect(state.isActive, isTrue);
    });

    test('true when phase is pausedDueToDrop', () {
      const state =
          TripRecordingState(phase: TripRecordingPhase.pausedDueToDrop);
      expect(state.isActive, isTrue);
    });

    test('false when phase is idle', () {
      const state = TripRecordingState(phase: TripRecordingPhase.idle);
      expect(state.isActive, isFalse);
    });

    test('false when phase is finished', () {
      const state = TripRecordingState(phase: TripRecordingPhase.finished);
      expect(state.isActive, isFalse);
    });
  });
}
