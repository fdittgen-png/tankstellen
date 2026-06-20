// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_recording_link_ownership.dart';

/// #3386 — the latch that lets a trip recording claim the adapter so the
/// app-wide #3019 reconnect controller stands down (single in-trip authority).
void main() {
  setUp(Obd2RecordingLinkOwnership.instance.resetForTest);
  tearDown(Obd2RecordingLinkOwnership.instance.resetForTest);

  test('defaults to unowned', () {
    expect(Obd2RecordingLinkOwnership.instance.active, isFalse);
  });

  test('claim() / release() flip active and notify listeners', () {
    final seen = <bool>[];
    void listener() =>
        seen.add(Obd2RecordingLinkOwnership.instance.recordingOwnsLink.value);
    Obd2RecordingLinkOwnership.instance.recordingOwnsLink.addListener(listener);
    addTearDown(() => Obd2RecordingLinkOwnership.instance.recordingOwnsLink
        .removeListener(listener));

    Obd2RecordingLinkOwnership.instance.claim();
    expect(Obd2RecordingLinkOwnership.instance.active, isTrue);
    Obd2RecordingLinkOwnership.instance.release();
    expect(Obd2RecordingLinkOwnership.instance.active, isFalse);

    expect(seen, [true, false]);
  });
}
