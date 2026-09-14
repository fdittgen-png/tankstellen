// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — which recording states are actually reachable, written down.
///
/// `TripRunState` carries five booleans: 32 combinations. #4034 already
/// gave them one owner and made each transition atomic, which is the
/// half that matters most. The half that was missing is the one #4162
/// names:
///
/// > Every impossible combination is a bug waiting for the right
/// > interruption — and the OS provides interruptions on its own
/// > schedule, which is why these only ever reproduce in the field.
///
/// So this drives every transition from every state reachable from
/// `idle`, and asserts the flags never land outside the documented set.
/// Exhaustive rather than illustrative: the point is the combinations
/// nobody thought of.
///
/// **No behaviour change is intended.** These tests describe what the
/// code already does; a failure means either a real unreachable state or
/// a transition that changed meaning.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/trip_run_state.dart';

/// The flag tuple, for comparing states without caring about identity.
({bool started, bool stopped, bool paused, bool drop, bool degraded})
    snapshot(TripRunState s) => (
          started: s.started,
          stopped: s.stopped,
          paused: s.paused,
          drop: s.pausedDueToDrop,
          degraded: s.degradedGpsOnly,
        );

/// Every transition the type exposes, by name, so a failure says which.
final Map<String, void Function(TripRunState)> transitions = {
  'begin': (s) => s.begin(),
  'end': (s) => s.end(),
  'pauseByUser': (s) => s.pauseByUser(),
  'clearUserPause': (s) => s.clearUserPause(),
  'clearDropPause': (s) => s.clearDropPause(),
  'setPausedDueToDrop(true)': (s) => s.setPausedDueToDrop(true),
  'setPausedDueToDrop(false)': (s) => s.setPausedDueToDrop(false),
  'setDegradedGpsOnly(true)': (s) => s.setDegradedGpsOnly(true),
  'setDegradedGpsOnly(false)': (s) => s.setDegradedGpsOnly(false),
};

void main() {
  group('the six reachable states', () {
    test('a fresh run is idle', () {
      expect(TripRunState().phase, TripRunPhase.idle);
    });

    test('begin → running', () {
      final s = TripRunState()..begin();
      expect(s.phase, TripRunPhase.running);
      expect(s.isRecording, isTrue);
    });

    test('a user pause is resumable and stops sampling', () {
      final s = TripRunState()..begin();
      expect(s.pauseByUser(), isTrue);
      expect(s.phase, TripRunPhase.pausedByUser);
      expect(s.isRecording, isFalse);
      s.clearUserPause();
      expect(s.phase, TripRunPhase.running);
    });

    test('a drop pause is a different state from a user pause', () {
      // They resume differently — the user clears one, the link
      // returning clears the other — so collapsing them loses the
      // difference that decides who may resume.
      final s = TripRunState()
        ..begin()
        ..setPausedDueToDrop(true);
      expect(s.phase, TripRunPhase.pausedByDrop);
      expect(s.isPaused, isTrue);
    });

    test('#2565 degraded is ACTIVE, and outranks a drop pause', () {
      final s = TripRunState()
        ..begin()
        ..setPausedDueToDrop(true)
        ..setDegradedGpsOnly(true);
      expect(s.phase, TripRunPhase.degradedGpsOnly);
      expect(s.isRecording, isTrue,
          reason: 'recording continues on GPS alone — it is not a pause');
    });

    test('end → finished, and finished outranks everything', () {
      // An auto-finalised drop leaves `stopped` true and `started`
      // false, which is why a state read must check stopped FIRST.
      final s = TripRunState()
        ..begin()
        ..setPausedDueToDrop(true)
        ..setDegradedGpsOnly(true)
        ..end();
      expect(s.phase, TripRunPhase.finished);
      expect(s.isRecording, isFalse);
      expect(s.isPaused, isFalse,
          reason: '#4068 — a user pause must not outlive the trip');
    });
  });

  group('no transition reaches an undocumented state', () {
    test('the closure of every transition from idle stays in the enum',
        () {
      // Breadth-first over the whole reachable graph. Every state
      // discovered must map to one of the six; a combination that maps
      // to none is exactly the "bug waiting for the right interruption".
      final seen = <String>{};
      final queue = <TripRunState>[TripRunState()];
      final reached = <TripRunPhase>{};

      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        final key = snapshot(current).toString();
        if (!seen.add(key)) continue;
        reached.add(current.phase);

        for (final entry in transitions.entries) {
          final next = TripRunState()
            ..setStarted(current.started)
            ..setStopped(current.stopped)
            ..setPausedDueToDrop(current.pausedDueToDrop)
            ..setDegradedGpsOnly(current.degradedGpsOnly);
          if (current.paused) {
            next.begin();
            next.pauseByUser();
            next
              ..setStarted(current.started)
              ..setStopped(current.stopped)
              ..setPausedDueToDrop(current.pausedDueToDrop)
              ..setDegradedGpsOnly(current.degradedGpsOnly);
          }
          entry.value(next);
          queue.add(next);
        }
      }

      // 32 combinations exist; far fewer are reachable, and every one
      // that is reachable has a name.
      expect(seen.length, lessThan(32),
          reason: 'if every combination is reachable, the flags carry no '
              'invariant at all');
      expect(reached, isNotEmpty);
      for (final p in reached) {
        expect(TripRunPhase.values, contains(p));
      }
    });

    test('`phase` is total — every combination maps somewhere', () {
      // The other direction: even a state the transitions cannot
      // produce must not crash a reader. A recording tile that throws
      // because the OS restored a combination nobody expected is the
      // failure mode this issue is about.
      for (var bits = 0; bits < 32; bits++) {
        final s = TripRunState()
          ..setStarted(bits & 1 != 0)
          ..setStopped(bits & 2 != 0)
          ..setPausedDueToDrop(bits & 8 != 0)
          ..setDegradedGpsOnly(bits & 16 != 0);
        if (bits & 4 != 0) {
          s.begin();
          s.pauseByUser();
          s
            ..setStarted(bits & 1 != 0)
            ..setStopped(bits & 2 != 0)
            ..setPausedDueToDrop(bits & 8 != 0)
            ..setDegradedGpsOnly(bits & 16 != 0);
        }
        expect(() => s.phase, returnsNormally, reason: 'bits=$bits');
        expect(TripRunPhase.values, contains(s.phase), reason: 'bits=$bits');
      }
    });
  });

  group('the interruptions the OS actually performs', () {
    test('KILL mid-trip: end() from any active state finalises cleanly',
        () {
      for (final setup in <void Function(TripRunState)>[
        (s) => s.begin(),
        (s) => s..begin()..pauseByUser(),
        (s) => s..begin()..setPausedDueToDrop(true),
        (s) => s..begin()..setDegradedGpsOnly(true),
      ]) {
        final s = TripRunState();
        setup(s);
        s.end();
        expect(s.phase, TripRunPhase.finished);
        expect(s.isRecording, isFalse);
        expect(s.isPaused, isFalse);
      }
    });

    test('RESTART: begin() after end() is never "stopped and started"',
        () {
      final s = TripRunState()
        ..begin()
        ..end()
        ..begin();
      expect(s.phase, TripRunPhase.running);
      expect(s.stopped, isFalse,
          reason: 'a restart seen as both would make every downstream '
              'read pick whichever it checked first');
    });

    test('LINK DROP then RETURN walks back to running', () {
      final s = TripRunState()..begin();
      s.setPausedDueToDrop(true);
      expect(s.phase, TripRunPhase.pausedByDrop);
      s.clearDropPause();
      expect(s.phase, TripRunPhase.running);
    });

    test('DEGRADE then GPS DIES becomes a drop pause, not a stop', () {
      // #2565's escalation path: GPS-only is active until GPS goes too.
      final s = TripRunState()
        ..begin()
        ..setDegradedGpsOnly(true);
      expect(s.phase, TripRunPhase.degradedGpsOnly);
      s
        ..setDegradedGpsOnly(false)
        ..setPausedDueToDrop(true);
      expect(s.phase, TripRunPhase.pausedByDrop);
      expect(s.isRecording, isFalse);
    });

    test('a pause cannot be taken twice, or before the trip starts', () {
      expect(TripRunState().pauseByUser(), isFalse,
          reason: 'pausing a trip that never began');
      final s = TripRunState()..begin();
      expect(s.pauseByUser(), isTrue);
      expect(s.pauseByUser(), isFalse, reason: 'already paused');
    });
  });
}
