// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_arbiter.dart';

/// #3424 — the pinned coverage of the deleted #3386/#3387 latch shim
/// (`Obd2RecordingLinkOwnership`), ported onto the [Obd2LinkArbiter] that
/// absorbed it (#3420): the recording-ownership mirror must flip + notify
/// on lease acquire/release exactly as the latch did, because read-only
/// listeners still key off [Obd2LinkArbiter.recordingOwnsLink].
void main() {
  setUp(Obd2LinkArbiter.instance.resetForTest);
  tearDown(Obd2LinkArbiter.instance.resetForTest);

  test('defaults to no recording lease', () {
    expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isFalse);
    expect(Obd2LinkArbiter.instance.recordingOwnsLink.value, isFalse);
  });

  test('a recording lease flips recordingOwnsLink and notifies listeners',
      () {
    final seen = <bool>[];
    void listener() =>
        seen.add(Obd2LinkArbiter.instance.recordingOwnsLink.value);
    Obd2LinkArbiter.instance.recordingOwnsLink.addListener(listener);
    addTearDown(() =>
        Obd2LinkArbiter.instance.recordingOwnsLink.removeListener(listener));

    final lease = Obd2LinkArbiter.instance
        .tryAcquire('recording', Obd2LinkPriority.recording);
    expect(lease, isNotNull);
    expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isTrue);
    lease!.release();
    expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isFalse);

    expect(seen, [true, false],
        reason: 'the mirror must notify on every recording-ownership '
            'transition, exactly like the latch it replaced');
  });

  test('a NON-recording lease does not flip the recording mirror', () {
    final lease = Obd2LinkArbiter.instance
        .tryAcquire('picker', Obd2LinkPriority.interactive);
    expect(lease, isNotNull);
    expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isFalse);
    lease!.release();
  });

  group('#3495 F1 — recording-over-recording newest-wins', () {
    test(
        'a new recording acquire PREEMPTS a stale recording lease instead of '
        'being refused (the stop()-in-teardown race)', () {
      var oldPreempted = false;
      final stale = Obd2LinkArbiter.instance.tryAcquire(
        'recording',
        Obd2LinkPriority.recording,
        onPreempted: () => oldPreempted = true,
      );
      expect(stale, isNotNull);

      // The previous trip's stop() still holds its lease through the final
      // disconnect when the next trip starts. Refusing here left the NEW
      // recording lease-less — its drops routed to the idle loop (the war,
      // resurrected). Newest-wins: the fresh claim is granted.
      final fresh = Obd2LinkArbiter.instance
          .tryAcquire('recording', Obd2LinkPriority.recording);
      expect(fresh, isNotNull,
          reason: 'a recording acquire must NEVER silently fail — the '
              'pipeline claims it before its first await and does not '
              'null-check (#3495 F1)');
      expect(oldPreempted, isTrue);
      expect(stale!.isActive, isFalse);
      expect(Obd2LinkArbiter.instance.holder, same(fresh));
      expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isTrue);

      // The stale holder's own release (stop() finishing later) is the
      // idempotent no-op release of a revoked lease — the fresh holder keeps
      // the link.
      stale.release();
      expect(Obd2LinkArbiter.instance.holder, same(fresh));
      expect(Obd2LinkArbiter.instance.recordingLeaseHeld, isTrue);
      fresh!.release();
    });

    test('auto-record-over-auto-record is still refused (loops must not '
        'tear each other down)', () {
      final first = Obd2LinkArbiter.instance
          .tryAcquire('auto-record', Obd2LinkPriority.autoRecord);
      expect(first, isNotNull);
      final second = Obd2LinkArbiter.instance
          .tryAcquire('auto-record', Obd2LinkPriority.autoRecord);
      expect(second, isNull,
          reason: 'newest-wins is deliberate for user-driven kinds only '
              '(interactive, recording); loops retry on their own schedule');
      first!.release();
    });
  });
}
