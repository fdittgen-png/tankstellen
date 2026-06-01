// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/approach/providers/radar_swipe_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #2633 — the LIFO ignore stack behind the swipe-to-page radar card.
/// The card derives the current candidate as the first ranked station
/// not in [RadarSwipeState.ignoredStationIds]; these unit tests assert
/// the stack semantics and the trip-stop reset.

/// Mirrors the card's derivation of the "current" candidate: the first
/// ranked station whose id is NOT on the ignore stack.
Station? _current(List<Station> candidates, List<String> ignored) =>
    candidates.firstWhereOrNull((s) => !ignored.contains(s.id));

const _s1 = Station(
  id: 's1',
  name: 'One',
  brand: 'Aral',
  street: 'a',
  postCode: '10000',
  place: 'X',
  lat: 1,
  lng: 1,
  e10: 1.5,
  isOpen: true,
);
const _s2 = Station(
  id: 's2',
  name: 'Two',
  brand: 'Shell',
  street: 'b',
  postCode: '10001',
  place: 'X',
  lat: 2,
  lng: 2,
  e10: 1.6,
  isOpen: true,
);
const _s3 = Station(
  id: 's3',
  name: 'Three',
  brand: 'Total',
  street: 'c',
  postCode: '10002',
  place: 'X',
  lat: 3,
  lng: 3,
  e10: 1.7,
  isOpen: true,
);

const _candidates = [_s1, _s2, _s3];

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

  test('starts with an empty ignore stack → current is the first ranked',
      () {
    final container = makeContainer();
    final ignored =
        container.read(radarSwipeProvider).ignoredStationIds;
    expect(ignored, isEmpty);
    expect(_current(_candidates, ignored), _s1);
  });

  test('ignore pushes the id → derived current advances to the next', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.ignore('s1');
    var ignored = container.read(radarSwipeProvider).ignoredStationIds;
    expect(ignored, ['s1']);
    expect(_current(_candidates, ignored), _s2);

    notifier.ignore('s2');
    ignored = container.read(radarSwipeProvider).ignoredStationIds;
    expect(ignored, ['s1', 's2']);
    expect(_current(_candidates, ignored), _s3);
  });

  test('restore pops LIFO → brings the last-ignored station back', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.ignore('s1');
    notifier.ignore('s2');
    expect(_current(_candidates,
            container.read(radarSwipeProvider).ignoredStationIds),
        _s3);

    // Pop s2 first (LIFO) → current returns to s2.
    notifier.restore();
    var ignored = container.read(radarSwipeProvider).ignoredStationIds;
    expect(ignored, ['s1']);
    expect(_current(_candidates, ignored), _s2);

    // Pop s1 → back to the top of the list.
    notifier.restore();
    ignored = container.read(radarSwipeProvider).ignoredStationIds;
    expect(ignored, isEmpty);
    expect(_current(_candidates, ignored), _s1);
  });

  test('restore on an empty stack is a no-op', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.restore();
    expect(container.read(radarSwipeProvider).ignoredStationIds, isEmpty);
  });

  test('reset empties the stack', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.ignore('s1');
    notifier.ignore('s2');
    notifier.reset();
    expect(container.read(radarSwipeProvider).ignoredStationIds, isEmpty);
  });

  test('exhausted (every candidate ignored) → derived current is null', () {
    final container = makeContainer();
    final notifier = container.read(radarSwipeProvider.notifier);

    notifier.ignore('s1');
    notifier.ignore('s2');
    notifier.ignore('s3');
    final ignored = container.read(radarSwipeProvider).ignoredStationIds;
    expect(_current(_candidates, ignored), isNull);
  });

  test('stopping an active trip resets the ignore stack', () {
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
    notifier.ignore('s1');
    notifier.ignore('s2');
    expect(container.read(radarSwipeProvider).ignoredStationIds,
        ['s1', 's2']);

    // Flip the active trip to a terminal (inactive) phase → reset fires.
    fake.setPhase(TripRecordingPhase.finished);

    expect(container.read(radarSwipeProvider).ignoredStationIds, isEmpty);
  });
}
