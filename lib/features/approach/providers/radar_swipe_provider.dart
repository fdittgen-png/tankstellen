// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/providers/trip_recording_provider.dart';

part 'radar_swipe_provider.freezed.dart';
part 'radar_swipe_provider.g.dart';

/// LIFO ignore stack for the swipe-to-page radar card (#2633).
///
/// The card itself never stores a "current index": the active candidate
/// is DERIVED from [radarCandidateListProvider] as the first station NOT
/// in [ignoredStationIds]. This state only records which stations the
/// driver has swiped past, in order, so a swipe-right can pop the last
/// one back.
@freezed
abstract class RadarSwipeState with _$RadarSwipeState {
  const factory RadarSwipeState({
    /// Stations the driver swiped LEFT past, most-recent last (the stack
    /// top). The derived "current" candidate is the first ranked station
    /// whose id is NOT in this list.
    @Default(<String>[]) List<String> ignoredStationIds,
  }) = _RadarSwipeState;
}

/// Holds the swipe-to-page ignore stack for the trip-recording radar
/// card (#2633).
///
/// `keepAlive` so the stack survives the card rebuilding on every
/// approach-state / candidate-list tick (otherwise an autoDispose
/// notifier would reset the moment the list re-runs). The stack is
/// cleared when the trip stops so the next trip starts fresh — there is
/// no persistence across trajets.
@Riverpod(keepAlive: true)
class RadarSwipe extends _$RadarSwipe {
  @override
  RadarSwipeState build() {
    // Reset the ignore stack when an active trip ends — the page-set is
    // scoped to a single trajet, never carried over to the next one.
    ref.listen(tripRecordingProvider, (prev, next) {
      if (prev?.isActive == true && !next.isActive) {
        state = const RadarSwipeState();
      }
    });
    return const RadarSwipeState();
  }

  /// Swipe-LEFT: push [id] onto the ignore stack so the derived current
  /// candidate advances to the next ranked station.
  void ignore(String id) {
    state = RadarSwipeState(
      ignoredStationIds: [...state.ignoredStationIds, id],
    );
  }

  /// Swipe-RIGHT: pop the most-recently-ignored station back. No-op when
  /// nothing has been ignored yet (a swipe-right with an empty stack does
  /// nothing).
  void restore() {
    final stack = state.ignoredStationIds;
    if (stack.isEmpty) return;
    state = RadarSwipeState(
      ignoredStationIds: stack.sublist(0, stack.length - 1),
    );
  }

  /// Clear the ignore stack — used when the ranked list is exhausted
  /// (every candidate ignored) so the card recovers to the nearest
  /// station rather than going blank (#2583).
  void reset() => state = const RadarSwipeState();
}
