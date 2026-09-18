// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — TankSync's session phases, checked as a graph and as a
/// function.
///
/// The table is the written-down state machine; these tests stop it from
/// quietly becoming decoration: every phase is covered and reachable,
/// every phase can be left for `off`, [phaseOf] is total over every
/// combination of its facts, and the known-illegal anomalies the
/// lifecycle suites tolerate can only ever shrink.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/tanksync_session_phase.dart';

import 'support/session_phase_trace.dart';

Set<TankSyncSessionPhase> _reachableFrom(TankSyncSessionPhase start) {
  final seen = <TankSyncSessionPhase>{start};
  final queue = [start];
  while (queue.isNotEmpty) {
    for (final next in kTankSyncSessionTransitions[queue.removeLast()]!) {
      if (seen.add(next)) queue.add(next);
    }
  }
  return seen;
}

/// Every combination of the boolean facts, with the string facts drawn
/// from a small alphabet that includes agreement and disagreement.
Iterable<SessionFacts> _allFacts() sync* {
  const hosts = [null, 'a.supabase.co', 'b.supabase.co'];
  for (var bits = 0; bits < 1 << 9; bits++) {
    bool b(int i) => bits & (1 << i) != 0;
    for (final sdkHost in hosts) {
      for (final backendHost in hosts) {
        yield SessionFacts(
          syncEnabled: b(0),
          consent: b(1),
          hasCredentials: b(2),
          clientInitialized: b(3),
          sdkInitialized: b(4),
          sdkHost: sdkHost,
          backendHost: backendHost,
          configuredHost: 'a.supabase.co',
          sessionUserId: b(5) ? 'u1' : null,
          storedUserId: 'u1',
          relinkFlag: b(6),
          configEnabled: b(7),
          initInFlight: b(8),
          retryPending: b(8) && b(0),
        );
      }
    }
  }
}

void main() {
  test('every phase has a row, and no row lists its own phase', () {
    expect(kTankSyncSessionTransitions.keys.toSet(),
        TankSyncSessionPhase.values.toSet());
    for (final e in kTankSyncSessionTransitions.entries) {
      expect(e.value, isNot(contains(e.key)),
          reason: 'a write that keeps the phase is not a transition');
    }
  });

  test('a write that keeps the phase is always allowed', () {
    for (final p in TankSyncSessionPhase.values) {
      expect(isTankSyncSessionTransition(p, p), isTrue, reason: p.name);
    }
  });

  test('every phase is reachable from off, and every phase can return to '
      'off', () {
    expect(_reachableFrom(TankSyncSessionPhase.off),
        TankSyncSessionPhase.values.toSet());
    for (final p in TankSyncSessionPhase.values) {
      expect(_reachableFrom(p), contains(TankSyncSessionPhase.off),
          reason: '${p.name}: disconnect must always be possible');
    }
  });

  test('consent can be withdrawn from every set-up phase, and granted '
      'again only resumes — it never jumps into a failure phase', () {
    for (final p in TankSyncSessionPhase.values) {
      if (p == TankSyncSessionPhase.off ||
          p == TankSyncSessionPhase.consentWithdrawn) {
        continue;
      }
      expect(kTankSyncSessionTransitions[p],
          contains(TankSyncSessionPhase.consentWithdrawn),
          reason: p.name);
    }
    expect(
        kTankSyncSessionTransitions[TankSyncSessionPhase.consentWithdrawn],
        isNot(anyOf(contains(TankSyncSessionPhase.sessionLost),
            contains(TankSyncSessionPhase.initFailed))));
  });

  test('a live session is never lost silently: ready leads to no '
      'unflagged session loss (#4338)', () {
    expect(kTankSyncSessionTransitions[TankSyncSessionPhase.ready],
        isNot(contains(TankSyncSessionPhase.sessionLost)));
    expect(kTankSyncSessionTransitions[TankSyncSessionPhase.ready],
        contains(TankSyncSessionPhase.relinkRequired));
  });

  group('phaseOf', () {
    test('is total: every combination maps to a phase', () {
      var count = 0;
      for (final facts in _allFacts()) {
        expect(() => phaseOf(facts), returnsNormally, reason: '$facts');
        count++;
      }
      expect(count, greaterThan(4000));
    });

    test('off wins while sync is not set up, whatever else is live', () {
      for (final facts in _allFacts()) {
        if (!facts.syncEnabled || !facts.hasCredentials) {
          expect(phaseOf(facts), TankSyncSessionPhase.off, reason: '$facts');
        }
      }
    });

    test('no phase but consentWithdrawn describes a set-up session without '
        'consent', () {
      for (final facts in _allFacts()) {
        if (facts.syncEnabled && facts.hasCredentials && !facts.consent) {
          expect(phaseOf(facts), TankSyncSessionPhase.consentWithdrawn,
              reason: '$facts');
        }
      }
    });

    test('the named phases, one representative each', () {
      const base = SessionFacts(
        syncEnabled: true,
        consent: true,
        hasCredentials: true,
      );
      expect(phaseOf(base), TankSyncSessionPhase.configured);
      expect(
          phaseOf(const SessionFacts(
              syncEnabled: true,
              consent: true,
              hasCredentials: true,
              initInFlight: true)),
          TankSyncSessionPhase.initializing);
      expect(
          phaseOf(const SessionFacts(
              syncEnabled: true,
              consent: true,
              hasCredentials: true,
              clientInitialized: true,
              sessionUserId: 'u1')),
          TankSyncSessionPhase.ready);
      expect(
          phaseOf(const SessionFacts(
              syncEnabled: true,
              consent: true,
              hasCredentials: true,
              clientInitialized: true)),
          TankSyncSessionPhase.sessionLost);
      expect(
          phaseOf(const SessionFacts(
              syncEnabled: true,
              consent: true,
              hasCredentials: true,
              clientInitialized: true,
              relinkFlag: true)),
          TankSyncSessionPhase.relinkRequired);
      expect(
          phaseOf(const SessionFacts(
              syncEnabled: true,
              consent: true,
              hasCredentials: true,
              retryPending: true)),
          TankSyncSessionPhase.initFailed);
    });
  });

  group('SessionInvariant', () {
    test('clientMatchesBackend: a live client must be the SDK client of the '
        'configured backend (#4336)', () {
      const i = SessionInvariant.clientMatchesBackend;
      expect(i.holdsFor(const SessionFacts()), isTrue,
          reason: 'no client, nothing to disagree');
      expect(
          i.holdsFor(const SessionFacts(
              clientInitialized: true,
              sdkInitialized: true,
              sdkHost: 'a',
              backendHost: 'a')),
          isTrue);
      expect(
          i.holdsFor(const SessionFacts(
              clientInitialized: true,
              sdkInitialized: true,
              sdkHost: 'a',
              backendHost: 'b')),
          isFalse,
          reason: 'the SDK skipped the second initialize');
      expect(
          i.holdsFor(const SessionFacts(
              syncEnabled: true,
              configuredHost: 'b',
              clientInitialized: true,
              sdkInitialized: true,
              sdkHost: 'a',
              backendHost: 'a')),
          isFalse,
          reason: 'settings say b, the live client is a');
      expect(
          i.holdsFor(const SessionFacts(
              sdkInitialized: true, sdkHost: 'a', backendHost: 'b')),
          isTrue,
          reason: 'an SDK left initialised behind a signed-out client is '
              'harmless until the client is used');
    });

    test('noCloudWithoutConsent: no published enabled flag and no signed-in '
        'client without the consent (#4337)', () {
      const i = SessionInvariant.noCloudWithoutConsent;
      expect(i.holdsFor(const SessionFacts()), isTrue);
      expect(i.holdsFor(const SessionFacts(configEnabled: true)), isFalse);
      expect(
          i.holdsFor(const SessionFacts(
              clientInitialized: true, sessionUserId: 'u1')),
          isFalse);
      expect(
          i.holdsFor(const SessionFacts(clientInitialized: true)), isTrue,
          reason: 'a live client with no session sends nothing as the user');
      expect(
          i.holdsFor(const SessionFacts(
              consent: true,
              configEnabled: true,
              clientInitialized: true,
              sessionUserId: 'u1')),
          isTrue);
    });
  });

  group('kKnownSessionAnomalies (the filed defects the suites tolerate)', () {
    test('holds only illegal edges and invariants', () {
      for (final a in kKnownSessionAnomalies) {
        switch (a) {
          case (final TankSyncSessionPhase from, final TankSyncSessionPhase to):
            expect(isTankSyncSessionTransition(from, to), isFalse,
                reason: '${from.name}→${to.name} is legal — remove it');
          case SessionInvariant _:
            break;
          default:
            fail('not an anomaly: $a');
        }
      }
    });

    test('may only shrink', () {
      expect(kKnownSessionAnomalies.length,
          lessThanOrEqualTo(kKnownSessionAnomaliesCeiling),
          reason: 'fix the writer; never tolerate a new anomaly');
      expect(kKnownSessionAnomaliesCeiling, kKnownSessionAnomalies.length,
          reason: 'a fix removed an anomaly — lower the ceiling with it');
    });
  });
}
