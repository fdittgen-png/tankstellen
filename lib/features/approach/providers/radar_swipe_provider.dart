// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/providers/trip_recording_provider.dart';

part 'radar_swipe_provider.freezed.dart';
part 'radar_swipe_provider.g.dart';

/// Distance-pagination index for the swipe-to-page Fuel Station Radar card
/// (#2661, replacing the #2633 ignore stack).
///
/// The card pages over the distance-RANKED [radarCandidateListProvider]
/// list (index 0 = the nearest priced station). This state holds only the
/// position in that list: swiping LEFT moves toward the nearer end
/// (decrement), swiping RIGHT moves toward the farther end (increment).
/// There is no per-station memory — paging is a pure index walk, so it is
/// idempotent at both ends and self-heals when the underlying list shrinks
/// (the card clamps the index against the live `candidates.length`).
@freezed
abstract class RadarSwipeState with _$RadarSwipeState {
  const factory RadarSwipeState({
    /// Index into the distance-ranked candidate list. 0 = the nearest
    /// station. The card clamps this against the live list length on every
    /// build, so a stale index from a shrunk list never points past the end.
    @Default(0) int currentIndex,
  }) = _RadarSwipeState;
}

/// Holds the swipe-to-page distance index for the trip-recording radar
/// card (#2661).
///
/// `keepAlive` so the index survives the card rebuilding on every
/// approach-state / candidate-list tick (otherwise an autoDispose notifier
/// would reset the moment the list re-runs). The index is reset to the
/// nearest station (0) when the trip stops so the next trip starts fresh —
/// there is no persistence across trajets.
@Riverpod(keepAlive: true)
class RadarSwipe extends _$RadarSwipe {
  @override
  RadarSwipeState build() {
    // Reset to the nearest station when an active trip ends — the page
    // position is scoped to a single trajet, never carried over.
    ref.listen(tripRecordingProvider, (prev, next) {
      if (prev?.isActive == true && !next.isActive) {
        state = const RadarSwipeState();
      }
    });
    return const RadarSwipeState();
  }

  /// Swipe-LEFT — page toward the NEARER station (decrement, clamped at the
  /// nearest, index 0). Idempotent once already at the nearest.
  void nearer() {
    final next = state.currentIndex - 1;
    state = RadarSwipeState(currentIndex: next < 0 ? 0 : next);
  }

  /// Swipe-RIGHT — page toward the FARTHER station (increment, clamped at
  /// [maxIndex] = `candidates.length - 1`). The caller passes the live list
  /// length so the notifier — which doesn't watch the list — never walks
  /// past the end. Idempotent once already at the farthest.
  void farther(int maxIndex) {
    final ceiling = maxIndex < 0 ? 0 : maxIndex;
    final next = state.currentIndex + 1;
    state = RadarSwipeState(currentIndex: next > ceiling ? ceiling : next);
  }

  /// Reset to the nearest station (index 0).
  void reset() => state = const RadarSwipeState();
}
