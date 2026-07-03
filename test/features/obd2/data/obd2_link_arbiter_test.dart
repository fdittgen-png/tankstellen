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
}
