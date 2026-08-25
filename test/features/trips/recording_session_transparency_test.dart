// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// Epic #3794 — recording-session transparency. Until this landed, a
// finished trip carried NO record of how it ended: a user tap, a
// grace-window auto-finalise and an OS process kill produced the same
// silent history row, and a recording killed by the OS was actively
// MISLABELLED as a Bluetooth drop. These tests pin the taxonomy, the
// process-death attribution, the always-on lifecycle timeline and the
// export surfacing.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/process_death_context.dart';
import 'package:tankstellen/features/trips/api.dart';

void main() {
  setUp(ProcessDeathContext.resetForTest);
  tearDown(ProcessDeathContext.resetForTest);

  group('TripTermination taxonomy (#3795)', () {
    test('round-trips by NAME, so reordering the enum cannot silently '
        'reinterpret persisted history', () {
      for (final r in TripTerminationReason.values) {
        final encoded = TripTermination(r, detail: 'why').toJson();
        expect(encoded['r'], r.name,
            reason: 'the wire format must be the name, never the index');
        expect(TripTermination.fromJson(encoded).reason, r);
      }
    });

    test('a value from a NEWER build degrades to unknown instead of '
        'throwing', () {
      final decoded = TripTermination.fromJson({'r': 'somethingFromTheFuture'});
      expect(decoded.reason, TripTerminationReason.unknown);
    });

    test('an empty detail is elided — the class alone is the record', () {
      expect(const TripTermination(TripTerminationReason.userStopped).toJson(),
          isNot(contains('d')));
      expect(
        const TripTermination(TripTerminationReason.userStopped, detail: '')
            .toJson(),
        isNot(contains('d')),
      );
    });
  });

  group('process-death attribution (#3796)', () {
    test('a snapshot written by an EARLIER process proves the app died '
        'while recording', () {
      // An orderly stop always clears the WAL, so a surviving row whose
      // writer is not this process can only mean the writer died.
      expect(ProcessDeathContext.diedWhileRecording('p-some-older-launch'),
          isTrue);
    });

    test('a snapshot written by THIS process is not a death (the normal '
        'in-flight flush)', () {
      expect(
        ProcessDeathContext.diedWhileRecording(ProcessDeathContext.instanceId),
        isFalse,
      );
    });

    test('a snapshot predating the field reads as unknown, never as a '
        'crash', () {
      expect(ProcessDeathContext.diedWhileRecording(null), isFalse,
          reason: 'guessing a crash for a legacy row would invent history');
    });

    test('the OS reason enriches the detail but is never required', () {
      expect(ProcessDeathContext.terminationDetail(), isNull);
      ProcessDeathContext.noteExit(reason: 'low_memory_kill', rssKb: 63080);
      expect(ProcessDeathContext.terminationDetail(),
          'low_memory_kill (rss=63080kB)');
    });
  });

  group('RecordingSessionJournal (#3797)', () {
    test('events are stamped RELATIVE to the start and stay ordered', () {
      var now = DateTime(2026, 8, 25, 19);
      final j = RecordingSessionJournal(now: () => now);
      j.start(at: now);
      now = now.add(const Duration(seconds: 3));
      j.add(RecordingSessionEventKind.linkDrop, detail: 'session:stale');
      now = now.add(const Duration(seconds: 7));
      j.add(RecordingSessionEventKind.linkReady);

      expect(j.events.map((e) => e.kind), [
        RecordingSessionEventKind.started,
        RecordingSessionEventKind.linkDrop,
        RecordingSessionEventKind.linkReady,
      ]);
      expect(j.events.map((e) => e.tMs), [0, 3000, 10000]);
      expect(j.events[1].detail, 'session:stale');
    });

    test('events before start are dropped rather than stamped a '
        'misleading t=0', () {
      final j = RecordingSessionJournal();
      j.add(RecordingSessionEventKind.linkDrop);
      expect(j.events, isEmpty);
      expect(j.isStarted, isFalse);
    });

    test('start is idempotent — a re-entrant start cannot reset the clock',
        () {
      var now = DateTime(2026, 8, 25, 19);
      final j = RecordingSessionJournal(now: () => now);
      j.start(at: now);
      now = now.add(const Duration(seconds: 30));
      j.start(at: now); // ignored
      j.add(RecordingSessionEventKind.linkReady);
      expect(j.events.last.tMs, 30000,
          reason: 'the anchor must stay at the FIRST start');
    });

    test('overflow evicts the oldest but REPORTS the loss, so a truncated '
        'timeline is never mistaken for a quiet one', () {
      final j = RecordingSessionJournal();
      j.start();
      for (var i = 0; i < RecordingSessionJournal.maxEvents + 10; i++) {
        j.add(RecordingSessionEventKind.linkDrop, detail: '$i');
      }
      expect(j.events.length, RecordingSessionJournal.maxEvents);
      expect(j.droppedEvents, greaterThan(0));
      expect(j.toJson()['dr'], j.droppedEvents);
      expect(j.events.last.detail, '${RecordingSessionJournal.maxEvents + 9}',
          reason: 'the NEWEST events are the ones worth keeping');
    });

    test('addDistinct collapses a repeat so a republished state cannot '
        'flood out the interesting history', () {
      final j = RecordingSessionJournal();
      j.start();
      j.addDistinct(RecordingSessionEventKind.linkReady);
      j.addDistinct(RecordingSessionEventKind.linkReady);
      j.addDistinct(RecordingSessionEventKind.linkReady, detail: 'x');
      expect(
        j.events.where((e) => e.kind == RecordingSessionEventKind.linkReady),
        hasLength(2),
      );
    });

    test('round-trips through JSON', () {
      final j = RecordingSessionJournal();
      j.start();
      j.add(RecordingSessionEventKind.protocolVerdict, detail: 'answered');
      final back = RecordingSessionJournal.fromJson(j.toJson());
      expect(back.events, j.events);
    });
  });

  group('GPS delivery skew (#3785)', () {
    // Six ~24.5 s "signalLoss" gaps on a FOREGROUND trip were the field
    // shape that motivated this: `signalLoss` is a RESIDUAL bucket, so an
    // app-side delivery stall (a saturated looper coalescing fixes) was
    // indistinguishable from genuinely lost reception. The two clocks
    // make it distinguishable — and they disagreed per pipeline before,
    // so a trip could not even be compared with itself.
    test('a stalled delivery shows a growing skew; lost reception does not',
        () {
      final fix = DateTime(2026, 8, 25, 19, 3);
      // Real reception loss: the receiver produced nothing, so when it
      // resumes both clocks have skipped together — no skew.
      final lostReception = [
        for (var i = 0; i < 3; i++)
          GpsSampleDiagnostic(
            timestamp: fix.add(Duration(seconds: i * 25)),
            lifecycleState: 'resumed',
            index: i,
            fixAt: fix.add(Duration(seconds: i * 25)),
          ),
      ];
      expect(lostReception.map((d) => d.deliverySkew!.inSeconds), [0, 0, 0],
          reason: 'a gap the RECEIVER caused leaves both clocks aligned');
      // Delivery stall: the receiver kept stamping fixes 1 s apart while
      // delivery lagged further and further behind.
      final stalled = [
        for (var i = 0; i < 3; i++)
          GpsSampleDiagnostic(
            timestamp: fix.add(Duration(seconds: i + 10 * i)),
            lifecycleState: 'resumed',
            index: i,
            fixAt: fix.add(Duration(seconds: i)),
          ),
      ];
      expect(stalled.map((d) => d.deliverySkew!.inSeconds), [0, 10, 20],
          reason: 'a growing arrival-vs-fix skew is the positive '
              'signature of an app-side stall');
    });

    test('the skew is unknown — never zero — when the fix clock was not '
        'recorded (legacy entries)', () {
      final d = GpsSampleDiagnostic(
        timestamp: DateTime(2026, 8, 25),
        lifecycleState: 'resumed',
        index: 0,
      );
      expect(d.deliverySkew, isNull,
          reason: 'reporting 0 would assert perfect delivery we never '
              'measured');
    });

    test('fixAt round-trips and is elided when absent', () {
      final withFix = GpsSampleDiagnostic(
        timestamp: DateTime(2026, 8, 25, 19, 3, 24),
        lifecycleState: 'resumed',
        index: 7,
        fixAt: DateTime(2026, 8, 25, 19, 3),
      );
      expect(GpsSampleDiagnostic.fromJson(withFix.toJson()).fixAt,
          withFix.fixAt);
      final without = GpsSampleDiagnostic(
        timestamp: DateTime(2026, 8, 25),
        lifecycleState: 'resumed',
        index: 0,
      );
      expect(without.toJson(), isNot(contains('f')));
      expect(GpsSampleDiagnostic.fromJson(without.toJson()).fixAt, isNull);
    });
  });

  group('persistence on the trip row (#3795/#3797/#3798)', () {
    TripHistoryEntry entryWith({
      TripTermination? termination,
      RecordingSessionJournal? journal,
    }) =>
        TripHistoryEntry(
          id: 't1',
          vehicleId: 'v1',
          summary: const TripSummary(
            distanceKm: 1.0,
            maxRpm: 0,
            highRpmSeconds: 0,
            idleSeconds: 0,
            harshBrakes: 0,
            harshAccelerations: 0,
          ),
          termination: termination,
          sessionJournal: journal,
        );

    test('termination + journal survive a save/load round-trip', () {
      final j = RecordingSessionJournal();
      j.start();
      j.add(RecordingSessionEventKind.linkDrop, detail: 'classic:stale');

      final back = TripHistoryEntry.fromJson(entryWith(
        termination: const TripTermination(
          TripTerminationReason.recoveredAfterProcessDeath,
          detail: 'low_memory_kill',
        ),
        journal: j,
      ).toJson());

      expect(back.termination?.reason,
          TripTerminationReason.recoveredAfterProcessDeath);
      expect(back.termination?.detail, 'low_memory_kill');
      expect(back.sessionJournal?.events.map((e) => e.kind), [
        RecordingSessionEventKind.started,
        RecordingSessionEventKind.linkDrop,
      ]);
    });

    test('a legacy row (neither key) decodes with nulls, not defaults', () {
      final legacy = {
        'id': 't-old',
        'vehicleId': null,
        'summary': entryWith().toJson()['summary'],
      };
      final back = TripHistoryEntry.fromJson(legacy);
      expect(back.termination, isNull,
          reason: 'an unrecorded end must stay honestly unknown');
      expect(back.sessionJournal, isNull);
    });

    test('both keys are elided when empty, so existing rows gain no bytes',
        () {
      final json = entryWith(journal: RecordingSessionJournal()).toJson();
      expect(json, isNot(contains('term')));
      expect(json, isNot(contains('sj')),
          reason: 'a journal with no events must not be written');
    });

    test('the summary-only decode carries the termination (the history '
        'list flags a crash-truncated trip without a full decode)', () {
      final full = entryWith(
        termination:
            const TripTermination(TripTerminationReason.graceWindowExpiry),
      ).toJson();
      final back = TripHistoryEntry.summaryFromJson(full);
      expect(back.termination?.reason, TripTerminationReason.graceWindowExpiry);
    });
  });
}
