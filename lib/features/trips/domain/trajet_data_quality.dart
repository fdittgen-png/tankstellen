// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'trip_recorder.dart' show TripKind;

/// How much of what a trajet PROMISED at start it actually delivered (#3835).
///
/// The trajets list already separated GPS-only (blue) from OBD2 (green), but
/// keyed on [TripKind], which is decided when the recording starts. A trip
/// that began with the adapter connected and then lost it — adapter drop,
/// silent ECU, protocol never established — kept the green stripe and was
/// indistinguishable from a clean recording. That is the exact failure the
/// #3775 epic was about, and the list could not show it.
enum TrajetDataQuality {
  /// No OBD2 was ever involved. Nothing is wrong; this is a normal GPS trip.
  gpsOnly,

  /// OBD2 recorded properly — engine data across the trip.
  obd2Healthy,

  /// Started on OBD2 and ended up mostly GPS. The ONLY state that says
  /// something went wrong, and the one that previously looked like success.
  obd2Degraded,
}

/// Share of engine-bearing samples at or above which a trip counts as
/// properly instrumented. Mirrors `Obd2EngineCoverage.fullShareFloor`, so
/// the list badge and the trip detail can never disagree.
const double kObd2HealthyShareFloor = 0.9;

/// Classify a trajet from what the history LIST has: no samples are
/// materialised there, so this takes the persisted counts, never a sample
/// list.
///
/// [engineShare] is `engineSampleCount / sampleCount` (null on rows written
/// before that was persisted). [hadAdapter] is true when the trip recorded
/// an adapter identity — the evidence that OBD2 was actually attempted.
/// [maxRpm] is the summary fallback for legacy rows: RPM can only come from
/// the adapter, so a non-zero value proves engine data arrived even when the
/// share is unknown.
TrajetDataQuality classifyTrajetQuality({
  required TripKind kind,
  required bool hadAdapter,
  double? engineShare,
  double maxRpm = 0,
}) {
  // OBD2 was attempted if the trip was started as such OR an adapter was
  // recorded. Either alone is enough: the kind can be gpsPlusObd2 with the
  // adapter identity missing, and an auto-record trip can pick the adapter
  // up without the kind being set at start.
  final attempted = kind == TripKind.gpsPlusObd2 || hadAdapter;
  if (!attempted) return TrajetDataQuality.gpsOnly;

  if (engineShare != null) {
    return engineShare >= kObd2HealthyShareFloor
        ? TrajetDataQuality.obd2Healthy
        : TrajetDataQuality.obd2Degraded;
  }

  // Legacy row: no persisted share. Fall back to the summary rather than
  // guessing — reporting a false "degraded" on every old trip would be
  // worse than the green-for-everything it replaces. RPM only ever comes
  // from the adapter, so treat its presence as a healthy recording and its
  // absence as a genuine failure to deliver.
  return maxRpm > 0
      ? TrajetDataQuality.obd2Healthy
      : TrajetDataQuality.obd2Degraded;
}
