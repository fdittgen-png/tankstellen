// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/approach/providers/radar_swipe_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// #2661 — the distance-pagination index behind the swipe-to-page Fuel
/// Station Radar card (replacing the #2633 ignore stack). The card shows
/// `candidates[currentIndex]` (clamped); these unit tests assert the index
/// walk (nearer = decrement, farther = increment, both clamped + idempotent
/// at the ends) and the trip-stop reset to the nearest (index 0).

/// Drives the trip phase from a test so the [RadarSwipe.reset]-on-stop
/// `ref.listen` can be exercised without the real recorder.
class _FakeTripRecording extends TripRecording {
  final TripRecordingState _initial;
  _FakeTripRecording(this._initial);

  @override
  TripRecordingState build() => _initial;

  void setPhase(TripRecordingPhase phase) =>
      state = state.copyWith(phase: phase);
}

void main() {
  ProviderContainer makeContainer({
    TripRecordingState trip = const TripRecordingState(),
    _FakeTripRecording Function()? recordingFactory,
  }) {
    final container = ProviderContainer(
      overrides: [
        tripRecordingProvider.overrideWith(
          recordingFactory ?? () => _FakeTripRecording(trip),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('starts at the nearest station (index 0)', () {
    final container = makeContainer();
    expect(container.read(radarSwipeProvider).currentIndex, 0);
  });

  test('farther increments the index toward the farther end (clamped)', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    // 3 candidates → maxIndex 2.
    notifier.farther(2);
    expect(container.read(radarSwipeProvider).currentIndex, 1);
    notifier.farther(2);
    expect(container.read(radarSwipeProvider).currentIndex, 2);
    // At the farthest — idempotent no-op.
    notifier.farther(2);
    expect(container.read(radarSwipeProvider).currentIndex, 2);
  });

  test('nearer decrements the index toward the nearest (clamped at 0)', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.farther(2);
    notifier.farther(2);
    expect(container.read(radarSwipeProvider).currentIndex, 2);

    notifier.nearer();
    expect(container.read(radarSwipeProvider).currentIndex, 1);
    notifier.nearer();
    expect(container.read(radarSwipeProvider).currentIndex, 0);
    // At the nearest — idempotent no-op.
    notifier.nearer();
    expect(container.read(radarSwipeProvider).currentIndex, 0);
  });

  test('farther clamps to a shrunk list ceiling', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    // Advance with a 3-element list, then a later scan shrinks to 1 element
    // (maxIndex 0) — farther can never walk past the new ceiling.
    notifier.farther(2);
    notifier.farther(2);
    expect(container.read(radarSwipeProvider).currentIndex, 2);

    notifier.farther(0);
    expect(container.read(radarSwipeProvider).currentIndex, 0);
  });

  test('reset returns to the nearest (index 0)', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.farther(3);
    notifier.farther(3);
    notifier.reset();
    expect(container.read(radarSwipeProvider).currentIndex, 0);
  });

  test('stopping an active trip resets the index to the nearest', () {
    late _FakeTripRecording fake;
    final container = makeContainer(
      recordingFactory: () {
        fake = _FakeTripRecording(
          const TripRecordingState(phase: TripRecordingPhase.recording),
        );
        return fake;
      },
    );

    // Instantiate the keepAlive notifier so its build()'s ref.listen arms.
    final notifier = container.read(radarSwipeProvider.notifier);
    notifier.farther(3);
    notifier.farther(3);
    expect(container.read(radarSwipeProvider).currentIndex, 2);

    // Flip the active trip to a terminal (inactive) phase → reset fires.
    fake.setPhase(TripRecordingPhase.finished);

    expect(container.read(radarSwipeProvider).currentIndex, 0);
  });
}
