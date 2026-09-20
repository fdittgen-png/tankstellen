// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — the recording's transition table, checked as a graph.
///
/// The table is the written-down state machine; these tests are what stop
/// it from quietly becoming decoration: every phase is covered, every
/// active recording can always be ended, and the known-illegal edges the
/// traces tolerate can only ever shrink.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_state.dart';

import '../support/phase_trace.dart';

bool _isActive(TripRecordingPhase p) => TripRecordingState(phase: p).isActive;

Set<TripRecordingPhase> _reachableFrom(TripRecordingPhase start) {
  final seen = <TripRecordingPhase>{start};
  final queue = [start];
  while (queue.isNotEmpty) {
    for (final next in kTripRecordingTransitions[queue.removeLast()]!) {
      if (seen.add(next)) queue.add(next);
    }
  }
  return seen;
}

void main() {
  test('every phase has a row, and no row lists its own phase', () {
    expect(kTripRecordingTransitions.keys.toSet(),
        TripRecordingPhase.values.toSet());
    for (final e in kTripRecordingTransitions.entries) {
      expect(e.value, isNot(contains(e.key)),
          reason: 'a write that keeps the phase is not a transition');
    }
  });

  test('a write that keeps the phase is always allowed', () {
    for (final p in TripRecordingPhase.values) {
      expect(isTripRecordingTransition(p, p), isTrue, reason: p.name);
    }
  });

  test('every phase is reachable from idle', () {
    expect(_reachableFrom(TripRecordingPhase.idle),
        TripRecordingPhase.values.toSet());
  });

  test('every active phase can always be ended, and every phase returns '
      'to idle', () {
    for (final p in TripRecordingPhase.values) {
      final reach = _reachableFrom(p);
      expect(reach, contains(TripRecordingPhase.idle), reason: p.name);
      if (_isActive(p)) {
        expect(reach, contains(TripRecordingPhase.finished), reason: p.name);
        expect(kTripRecordingTransitions[p], contains(TripRecordingPhase.saving),
            reason: '${p.name}: Stop is offered in every active phase');
      }
    }
  });

  test('agrees with isActive: the transient phases never feed each other, '
      'and only a start or a restore makes a recording active', () {
    const transient = {
      TripRecordingPhase.connecting,
      TripRecordingPhase.saving,
    };
    for (final from in transient) {
      expect(_isActive(from), isFalse);
      expect(kTripRecordingTransitions[from]!.intersection(transient), isEmpty,
          reason: from.name);
    }
    for (final e in kTripRecordingTransitions.entries) {
      if (_isActive(e.key)) continue;
      for (final to in e.value.where(_isActive)) {
        expect(
          {TripRecordingPhase.recording, TripRecordingPhase.pausedDueToDrop},
          contains(to),
          reason: '${e.key.name}→${to.name}: an inactive phase becomes '
              'active only by starting, or by restoring a killed trip',
        );
      }
    }
    // The restore edge is idle-only: nothing else hands back a dead trip.
    for (final e in kTripRecordingTransitions.entries) {
      if (_isActive(e.key) || e.key == TripRecordingPhase.idle) continue;
      expect(e.value, isNot(contains(TripRecordingPhase.pausedDueToDrop)),
          reason: e.key.name);
    }
  });

  group('kKnownIllegalEdges (the filed defects the traces tolerate)', () {
    test('holds only edges the table forbids', () {
      for (final e in kKnownIllegalEdges) {
        expect(isTripRecordingTransition(e.$1, e.$2), isFalse,
            reason: '${e.$1.name}→${e.$2.name} is legal — remove it');
      }
    });

    test('may only shrink', () {
      expect(kKnownIllegalEdges.length,
          lessThanOrEqualTo(kKnownIllegalEdgesCeiling),
          reason: 'fix the writer; never tolerate a new illegal edge');
      expect(kKnownIllegalEdgesCeiling, kKnownIllegalEdges.length,
          reason: 'a fix removed an edge — lower the ceiling with it');
    });
  });
}
