// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../trip_summary.dart';

/// Minimum GPS distance before a trip can be classed as transport
/// (#3599) — a short adapter-connected shuffle around a car park must
/// never be flagged.
const double kTransportMinDistanceKm = 2.0;

/// Engine-running share BELOW which an OBD2 trip counts as transport.
/// The 76.5 km field tow ran the engine ~2% of the trip; a real drive
/// with start-stop still idles/runs the vast majority. 15% leaves a
/// wide margin on both sides.
const double kTransportMaxEngineShare = 0.15;

/// Whether [summary] records the car being MOVED without driving —
/// towed, on a flatbed, on a train (#3599): the ECU kept answering
/// (so the trip classified as OBD2), yet the engine ran for almost
/// none of a real distance covered at GPS level.
///
/// Conservative by construction:
///  * only `gpsPlusObd2` trips qualify — a GPS-only trip has no engine
///    signal to be "off";
///  * legacy trips (null [TripSummary.engineRunningSeconds], recorded
///    before the field existed) are never flagged;
///  * sub-[kTransportMinDistanceKm] trips are never flagged.
///
/// Consumers: [tripConsumedLitersOrNull] returns null for transport
/// trips (excluded from every fuel aggregate at the one chokepoint),
/// and the lessons registry replaces coaching with a single info note.
bool isEngineOffTransport(TripSummary summary) {
  if (summary.kind != TripKind.gpsPlusObd2) return false;
  final running = summary.engineRunningSeconds;
  final start = summary.startedAt;
  final end = summary.endedAt;
  if (running == null || start == null || end == null) return false;
  final durationSec =
      end.difference(start).inMicroseconds / Duration.microsecondsPerSecond;
  if (durationSec <= 0) return false;
  return summary.distanceKm > kTransportMinDistanceKm &&
      running < durationSec * kTransportMaxEngineShare;
}
