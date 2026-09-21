// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// Extracted from `trip_summary.dart` (#4233 — keeps that file under the
// 400-line guard); re-exported from there so importers are unaffected.

/// Distinguishes a trajet recorded with OBD2 telemetry from one
/// recorded with GPS alone (#2025). Drives the confidence-tier label
/// on the calibration UI (#2027) and the recording-screen layout
/// (#2026) — gpsOnly trips have no instantaneous L/100 km, so they
/// fall back to a "vs your average %" indicator.
enum TripKind {
  /// GPS samples were recorded but no OBD2 adapter contributed any
  /// telemetry. Used for users who haven't paired a dongle, or whose
  /// dongle disconnected before any sample landed.
  gpsOnly,

  /// At least one sample carried OBD2 telemetry (RPM > 0 or a fuel
  /// rate reading). This is the historical default for every trip
  /// recorded before #2025 landed.
  gpsPlusObd2;

  /// Stable string used in JSON / backup XML. Avoids `name` because
  /// future-Dart enum rename safety relies on the string being chosen
  /// deliberately rather than tracking the declaration.
  String get wireName => switch (this) {
        TripKind.gpsOnly => 'gpsOnly',
        TripKind.gpsPlusObd2 => 'gpsPlusObd2',
      };

  /// Parses [s] back to a [TripKind]. Returns [gpsPlusObd2] for
  /// unknown / null inputs so legacy backups + JSON without the key
  /// land on the historical default.
  static TripKind fromWireName(String? s) => switch (s) {
        'gpsOnly' => TripKind.gpsOnly,
        _ => TripKind.gpsPlusObd2,
      };

  /// Derives the kind from the actual sample data — the mid-trip
  /// upgrade rule baked into #2025's acceptance: a trip that started
  /// in GPS-only mode but later received OBD2 telemetry should be
  /// classified as `gpsPlusObd2`.
  ///
  /// Heuristic: any sample with `rpm > 0` OR `fuelRateLPerHour != null`
  /// is an OBD2 sample (GPS-only samples carry `rpm: null` (#2692 C4-G;
  /// formerly `0`) and a null fuel rate by construction — the
  /// `?? 0` below maps null to 0 so the gate is unchanged). One such
  /// sample flips the whole trip — that's the "subsequent samples carry
  /// OBD2 fields" clause from the issue.
  ///
  /// Returns [gpsPlusObd2] for an empty iterable so the historical
  /// default holds when called against legacy data that doesn't
  /// thread its samples through.
  static TripKind fromSamples(Iterable<dynamic> samples) {
    var sawAny = false;
    for (final s in samples) {
      sawAny = true;
      final rpm = (s as dynamic).rpm as num? ?? 0;
      final fuelRate =
          (s as dynamic).fuelRateLPerHour as double?;
      if (rpm > 0 || fuelRate != null) return TripKind.gpsPlusObd2;
    }
    if (!sawAny) return TripKind.gpsPlusObd2;
    return TripKind.gpsOnly;
  }
}
