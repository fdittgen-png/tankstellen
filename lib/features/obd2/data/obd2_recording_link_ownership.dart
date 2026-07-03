// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'obd2_link_arbiter.dart';

/// #3386 → #3420 — THIN SHIM over [Obd2LinkArbiter].
///
/// The original latch let the recording pipeline claim the adapter so the
/// app-wide #3019 reconnector stood down. #3415's field evidence proved a
/// boolean latch cannot carry that responsibility (claim/release race
/// windows at the trip edges; no gate at all between auto-record and
/// #3019), so ownership moved into the [Obd2LinkArbiter] session lease.
///
/// This shim preserves the latch API for its existing tests and any legacy
/// caller: [claim]/[release] acquire/release a RECORDING lease on the
/// arbiter, and [active]/[recordingOwnsLink] mirror "a recording lease is
/// held" (including one acquired directly on the arbiter, e.g. by
/// `Obd2RecordingPipeline.start`). Scheduled for deletion in #3424 once
/// the regression suite proves nothing references it.
class Obd2RecordingLinkOwnership {
  Obd2RecordingLinkOwnership._();

  /// Process-wide instance.
  static final Obd2RecordingLinkOwnership instance =
      Obd2RecordingLinkOwnership._();

  Obd2LinkLease? _legacyLease;

  /// True while a trip recording owns the adapter. Notifies on every
  /// change. Owned by the arbiter — reflects ANY recording lease, however
  /// acquired.
  ValueNotifier<bool> get recordingOwnsLink =>
      Obd2LinkArbiter.instance.recordingOwnsLink;

  /// Whether a recording currently owns the adapter.
  bool get active => Obd2LinkArbiter.instance.recordingLeaseHeld;

  /// A recording now owns the adapter (legacy path — the pipeline itself
  /// acquires its lease on the arbiter directly).
  void claim() =>
      _legacyLease ??= Obd2LinkArbiter.instance.tryAcquire(
        'legacy-latch',
        Obd2LinkPriority.recording,
        onPreempted: () => _legacyLease = null,
      );

  /// The recording released the adapter.
  void release() {
    _legacyLease?.release();
    _legacyLease = null;
  }

  /// Reset to the unowned state (tests) — clears any held lease on the
  /// arbiter, whoever acquired it.
  @visibleForTesting
  void resetForTest() {
    _legacyLease = null;
    // Shim-to-arbiter delegation: both ends are @visibleForTesting.
    // ignore: invalid_use_of_visible_for_testing_member
    Obd2LinkArbiter.instance.resetForTest();
  }
}
