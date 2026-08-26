// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Why a stretch of the recorded GPS track has no fixes (#3465).
///
/// A field report of "my trace has holes" was previously unanswerable per
/// trip: the causes were known in aggregate (#3253 tallies, #1458 cadence
/// diagnostics) but never JOINED to the individual gap. Each gap in a
/// [GpsCoverageReport] carries one of these verdicts.
enum GpsGapAttribution {
  /// The gap majority-overlaps a backgrounded stretch of the trip AND the
  /// build ships without the recording foreground service
  /// (`kGpsRecordingForegroundServiceEnabled` off, #3417 pending) — the
  /// OS batched/paused the backgrounded stream. The dominant field cause.
  backgroundThrottle,

  /// A burst of tightly-spaced fixes right after the gap carries roughly
  /// the fixes that should have been spread across it — the OS queued
  /// fixes and delivered them late in one batch (#3253 fix-clock
  /// stamping makes the late delivery visible).
  osBatching,

  /// The gap is flanked by link-down samples on an OBD2 trip (RPM null on
  /// both sides while most of the trip carries RPM): GPS ingest stalled
  /// while an OBD2 reconnect episode monopolised the UI isolate /
  /// serialized transport — the field-observed foreground-gap correlate
  /// (flapping link, one connect cycle every ~9 s).
  linkRecovery,

  /// The #2963/#1979/#3004 distance gates rejected enough fixes/segments
  /// (per the trip's [GpsGateRejectionTally]) to account for the fixes
  /// missing from this gap.
  gateRejected,

  /// #3785 — the fixes bracketing this gap arrived materially LATER
  /// than the receiver stamped them, so the receiver worked and the
  /// app-side delivery path stalled. Scope + limits: [GpsDeliverySkew].
  deliveryStall,

  /// The app was foregrounded and nothing above explains the gap: GPS
  /// reception itself dropped (tunnel, garage, urban canyon).
  ///
  /// A RESIDUAL bucket, not a positive verdict — "no other explanation
  /// matched", which is why #3785 added [deliveryStall] above it.
  signalLoss,

  /// No verdict possible — typically a legacy trip persisted without
  /// lifecycle marks, or a backgrounded gap on an FGS-enabled build
  /// (where backgrounding should NOT throttle, so the cause is unclear).
  unknown,
}
