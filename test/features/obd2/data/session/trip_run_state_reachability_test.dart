// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — which recording flag combinations are actually reachable,
/// written down and proven.
///
/// `TripRunState` carries five booleans: 32 combinations. The previous
/// version of this test could not fail — its "closure" reset every state
/// through raw setters, so it explored combinations no caller can make,
/// and it asserted only that a total function returned an enum value. Its
/// "kill" called `end()`, which a kill never does.
///
/// This walk uses only the transitions production performs, each behind
/// the guard its real caller applies (named on every entry), so the set it
/// finds IS the reachable set. It must be exactly eight tuples.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/trip_run_state.dart';

/// (started, stopped, paused, drop, degraded) as a 5-character bit string.
String bits(TripRunState s) => [
      s.started,
      s.stopped,
      s.paused,
      s.pausedDueToDrop,
      s.degradedGpsOnly,
    ].map((b) => b ? '1' : '0').join();

/// Every way production moves the flags, with its caller's guard.
final Map<String, void Function(TripRunState)> realTransitions = {
  // TripRecordingController.start: `if (_run.started) return;`
  'start': (s) {
    if (!s.started) s.begin();
  },
  // .start with the engine off at start (#3858): begin, then the
  // engine-off wait sets the degrade.
  'start engine-off': (s) {
    if (s.started) return;
    s
      ..begin()
      ..setDegradedGpsOnly(true);
  },
  // .stop — unconditional.
  'stop': (s) => s.end(),
  // .pause → TripRunState.pauseByUser (its own guard).
  'pause': (s) => s.pauseByUser(),
  // .resume: `if (!_run.isPaused) return;` then clears the drop, then the
  // user pause.
  'resume': (s) {
    if (!s.isPaused) return;
    if (s.pausedDueToDrop) s.clearDropPause();
    s.clearUserPause();
  },
  // DroppedSessionManager.handleDrop, GPS alive (#2565): returns while
  // dropped or degraded; drops are only detected on a running loop.
  'drop, GPS alive → degrade': (s) {
    if (!s.started || s.pausedDueToDrop || s.degradedGpsOnly) return;
    s.setDegradedGpsOnly(true);
  },
  // .handleDrop, GPS dead → _enterVisibleDrop (directly, or after the
  // #1904 silent window — whose escalation also refuses when stopped).
  'drop, GPS dead → pause': (s) {
    if (!s.started || s.pausedDueToDrop || s.degradedGpsOnly) return;
    s.setPausedDueToDrop(true);
  },
  // .escalateDegradedToPaused: GPS died too.
  'degraded, GPS dies → pause': (s) {
    if (!s.degradedGpsOnly || s.stopped) return;
    s
      ..setDegradedGpsOnly(false)
      ..setPausedDueToDrop(true);
  },
  // .onEngineData (#4196) / .onEngineRunning(linkAlive) (#3859).
  'engine data returns → leave degrade': (s) {
    if (s.stopped || !s.degradedGpsOnly) return;
    s.setDegradedGpsOnly(false);
  },
  // ._onGraceWindowElapsed: `if (!_host.pausedDueToDrop) return;`
  'grace window expires': (s) {
    if (s.pausedDueToDrop) s.end();
  },
  // .finaliseParked (#3862): `if (_host.stopped) return;`
  'parked auto-finalise': (s) {
    if (!s.stopped) s.end();
  },
};

/// Replays [path] from a fresh state.
TripRunState replay(List<String> path) {
  final s = TripRunState();
  for (final step in path) {
    realTransitions[step]!(s);
  }
  return s;
}

/// Breadth-first over real transitions: every reachable tuple, with the
/// shortest path that reaches it.
Map<String, List<String>> reachable() {
  final found = <String, List<String>>{bits(TripRunState()): const []};
  final queue = <List<String>>[const []];
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    for (final step in realTransitions.keys) {
      final next = [...path, step];
      final key = bits(replay(next));
      if (found.containsKey(key)) continue;
      found[key] = next;
      queue.add(next);
    }
  }
  return found;
}

TripRunPhase phaseOfBits(String b) => tripRunPhaseOf(
      started: b[0] == '1',
      stopped: b[1] == '1',
      paused: b[2] == '1',
      pausedDueToDrop: b[3] == '1',
      degradedGpsOnly: b[4] == '1',
    );

void main() {
  final found = reachable();

  test('exactly eight flag tuples are reachable', () {
    expect(found.keys.toSet(), {
      '00000', // idle
      '10000', // running
      '10100', // paused by the user
      '10010', // paused by a drop
      '10001', // degraded onto GPS
      '01000', // finished
      '10101', // a user pause taken while degraded
      '10110', // a drop escalating under a user pause (#1904 window)
    }, reason: 'paths: $found');
  });

  test('a drop pause and a degrade never coexist, and a finished or '
      'unstarted trip carries no pause or degrade', () {
    for (final b in found.keys) {
      expect(b[3] == '1' && b[4] == '1', isFalse, reason: b);
      if (b[0] == '0') {
        expect(b.substring(2), '000', reason: '$b via ${found[b]}');
      }
    }
  });

  test('every reachable tuple has a name, and the name is what the UI '
      'shows', () {
    const expected = {
      '00000': TripRunPhase.idle,
      '10000': TripRunPhase.running,
      '10100': TripRunPhase.pausedByUser,
      '10010': TripRunPhase.pausedByDrop,
      '10001': TripRunPhase.degradedGpsOnly,
      '01000': TripRunPhase.finished,
      // The pauses outrank the degrade: no samples flow during a user
      // pause, so this must not read as recording (#4162 — the enum used
      // to disagree with the controller's currentState here).
      '10101': TripRunPhase.pausedByUser,
      '10110': TripRunPhase.pausedByDrop,
    };
    for (final e in found.entries) {
      final s = replay(e.value);
      expect(s.phase, expected[e.key], reason: '${e.key} via ${e.value}');
      expect(
        s.isRecording,
        s.phase == TripRunPhase.running ||
            s.phase == TripRunPhase.degradedGpsOnly,
        reason: e.key,
      );
    }
  });

  test('the phase function is total over all 32 combinations', () {
    for (var n = 0; n < 32; n++) {
      final b = n.toRadixString(2).padLeft(5, '0');
      expect(() => phaseOfBits(b), returnsNormally, reason: b);
    }
    // finished outranks everything, even combinations no caller makes.
    expect(phaseOfBits('11111'), TripRunPhase.finished);
    expect(phaseOfBits('00111'), TripRunPhase.idle);
  });

  test('RESTART after a finish is never "stopped and started at once"', () {
    final s = replay(['start', 'stop', 'start']);
    expect(bits(s), '10000');
  });
}
