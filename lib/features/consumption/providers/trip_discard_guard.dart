// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../obd2/api.dart';
import '../domain/trip_summary.dart';

/// Decides whether a finalised trip is a stub / ghost that should be
/// discarded rather than persisted to history. Extracted from
/// `trip_recording_provider.dart` (#2692 C4-H) so the provider stays under
/// its line guard; the logic is pure + side-effect free so it can be unit
/// tested directly with the false-green-fakes lesson in mind.
///
/// A trip is discarded when EITHER:
///
/// 1. **#1923 / #2509 no-movement guard** — zero distance AND no meaningful
///    signal at all (no start time, OR no samples and no GPS fixes). A real
///    GPS-tracked drive whose OBD2 link was dead the whole session still
///    persists because its distance ≥ 0.01 km (the #2509 fix turned the old
///    disjunction into this conjunction so such drives are no longer lost).
///
/// 2. **#2692 C4-H virtual-ghost guard** — a trip whose ONLY distance came
///    from the virtual dead-reckoning odometer while the recorder never saw a
///    single sample (`startedAt == null`), with NO captured samples and NO
///    GPS fixes, discarded *regardless of distance*. The 10 empty trips in the
///    77-trip field backup escaped guard (1) via a virtual distance ≥ 0.01 km:
///    the 5 Hz speed path fed the dead-reckoning odometer but the emit loop
///    never produced a [TripSample], so the recorder's `startedAt` stayed
///    null. The `startedAt == null` clause is the discriminator that keeps a
///    real virtual-distance drive — whose recorder DID integrate samples
///    (startedAt set), even if chart-decimation left `capturedSamples` thin —
///    from being mistaken for a ghost. A trip with real/GPS distance, any
///    captured sample, any GPS fix, OR a non-null `startedAt` is never caught
///    here.
bool shouldDiscardAsNoMovement({
  required TripSummary summary,
  required int sampleCount,
  required int gpsFixCount,
}) {
  final hasNoSignal =
      summary.startedAt == null || (sampleCount == 0 && gpsFixCount == 0);
  final virtualGhost = summary.startedAt == null &&
      sampleCount == 0 &&
      gpsFixCount == 0 &&
      summary.distanceSource == kDistanceSourceVirtual;
  return (summary.distanceKm < 0.01 && hasNoSignal) || virtualGhost;
}
