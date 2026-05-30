// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'harsh_event.dart';

export 'harsh_event.dart';

/// Aggregated metrics for a single driving trip (#718).
///
/// Extracted from `trip_recorder.dart` (#1927 — keeps that file under
/// the 400-line guard); re-exported from there so existing importers
/// are unaffected.
class TripSummary {
  final double distanceKm;
  final double maxRpm;
  final double highRpmSeconds;
  final double idleSeconds;
  final int harshBrakes;
  final int harshAccelerations;
  /// Average fuel consumption in L/100 km. Null when the trip carried
  /// no fuel-rate samples (cars without PID 5E / MAF).
  final double? avgLPer100Km;
  /// Estimated fuel burned during the trip, in litres. Null when the
  /// trip carried no fuel-rate samples. This is what the "save as
  /// fill-up" flow pre-fills into the liters field (#726).
  final double? fuelLitersConsumed;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Provenance flag for [distanceKm] (#800). Either `'real'` — the
  /// value came from the car's odometer (`odometerLatest -
  /// odometerStart`) — or `'virtual'` — the value is the trapezoidal
  /// integration of speed samples from [VirtualOdometer]. UI /
  /// analytics use this to decide whether to trust the km figure as a
  /// ground truth (fuel-reconciliation denominator) or flag it as an
  /// estimate. Defaults to `'virtual'` because the recorder
  /// integrates speed even when an odometer is available — legacy
  /// trips before this flag landed keep that honest label.
  final String distanceSource;

  /// Whether this trip likely paid a cold-start fuel surcharge
  /// (#1262 phase 2). Flipped true when the coolant temperature
  /// telemetry suggests the engine was warming up for a meaningful
  /// portion of the trip — short trips that never reached operating
  /// temperature, trips where the coolant max stayed below 70 °C, or
  /// trips that only crossed 70 °C in the second half. Cars without
  /// PID 0x05 produce no coolant samples, so the flag stays false to
  /// avoid false positives on absent data. UI surfaces (Phase 3)
  /// render a chip on the trip card based on this bit.
  final bool coldStartSurcharge;

  /// Seconds during the trip the engine was in a lower gear than
  /// optimal — heuristic: in-gear-N when N+1 would let RPM drop below
  /// `optimalRpmCeiling` (≈ 2200 RPM). Computed from
  /// `gear_inference.dart` outputs at trip end. Null = no inference
  /// (no centroids, EV, insufficient samples).
  final double? secondsBelowOptimalGear;

  /// Whether the fuel-rate samples that produced [fuelLitersConsumed]
  /// / [avgLPer100Km] tripped the cross-check sanity bounds at a
  /// meaningful rate during the trip (#1395). Set true at trip end
  /// when the breadcrumb collector reports
  /// `suspiciousSampleCount / totalSampleCount > 0.3` — i.e. more
  /// than 30 % of samples were either implausibly low (RPM > 1500
  /// AND L/h < 0.3) or showed > 50 % divergence between PID 5E and
  /// the MAF-derived rate. Stays false when no samples or no flagged
  /// samples were recorded; UI surfaces (#1395 phase 4) render a chip
  /// on the trip summary card based on this bit.
  final bool fuelRateSuspect;

  /// Fuel-weighted mean volumetric efficiency (η_v) the trip's fuel was
  /// integrated with (#1858), or null when the trip is **not**
  /// η_v-recalculable.
  ///
  /// Speed-density fuel scales linearly with η_v, so a stored trip can
  /// be retroactively recomputed for a corrected η_v by
  /// `fuelLitersConsumed × (newVe / volumetricEfficiencyUsed)` — but
  /// only when *every* litre was speed-density-derived. This field is
  /// non-null exactly then: it carries the fuel-weighted mean of the
  /// per-tick η_v actually applied. It is null when any fuel came from
  /// PID 5E or the MAF branch (neither uses η_v — rescaling would
  /// corrupt that portion), when the trip burned no fuel, and for
  /// legacy trips recorded before #1858. A null value means "not
  /// recalculable" and such trips are left untouched by a recompute.
  final double? volumetricEfficiencyUsed;

  /// Kind of trajet — whether the recorder collected OBD2 telemetry
  /// alongside GPS, or GPS only (#2025). Trips upgrade in-place from
  /// `gpsOnly` to `gpsPlusObd2` the moment an OBD2 adapter starts
  /// supplying samples mid-recording. Legacy trips deserialise as
  /// `gpsPlusObd2` because every recording before this field landed
  /// required an OBD2 connection.
  final TripKind kind;

  /// Timestamped per-event harsh-brake / harsh-accel detail (#2029).
  /// Replaces the bare [harshBrakes] / [harshAccelerations] counters
  /// for post-trip coaching ("harsh brake at 14:23, 0.45 g while
  /// doing 80 km/h"). The counters remain populated alongside the
  /// list — every legacy consumer keeps working unchanged; new UI
  /// reads from [harshEvents] directly. Legacy trips deserialise with
  /// an empty list, in which case rendering falls back to the bare
  /// counters.
  final List<HarshEvent> harshEvents;

  /// Whether this is a SYNTHETIC reconciliation trajet injected by the
  /// guided reconciliation workflow's Path B (#2444 / Epic #2439) — a
  /// stand-in for unrecorded driving the user confirmed happened. It
  /// carries [fuelLitersConsumed] = the reconciliation gap and a
  /// user-supplied [distanceKm], and is rendered distinctly in the
  /// Trajets list (like the orange correction fill-up).
  ///
  /// Treated specially everywhere that would otherwise double-count or
  /// corrupt calibration:
  /// - counts on the TRAJETS side of [reconciliationBasis] (it's an
  ///   explicit stand-in for unrecorded burn), so the window reconciles;
  /// - EXCLUDED from the η_v learner (it carries no real OBD2 samples,
  ///   so rescaling η_v against it would be meaningless);
  /// - EXCLUDED from the NEXT window's recorded `consumed` so a re-run
  ///   doesn't double-count the gap (mirrors how correction fill-ups
  ///   are excluded from `pumped`).
  ///
  /// Defaults `false` so every real trip — and every legacy trip
  /// recorded before this field landed — deserialises as a normal,
  /// fully-counted trajet.
  final bool isVirtual;

  const TripSummary({
    required this.distanceKm,
    required this.maxRpm,
    required this.highRpmSeconds,
    required this.idleSeconds,
    required this.harshBrakes,
    required this.harshAccelerations,
    this.avgLPer100Km,
    this.fuelLitersConsumed,
    this.startedAt,
    this.endedAt,
    this.distanceSource = 'virtual',
    this.coldStartSurcharge = false,
    this.secondsBelowOptimalGear,
    this.fuelRateSuspect = false,
    this.volumetricEfficiencyUsed,
    this.kind = TripKind.gpsPlusObd2,
    this.harshEvents = const [],
    this.isVirtual = false,
  });

  /// Returns a copy with the given fields replaced (#1858). Used by the
  /// retroactive η_v recompute to rescale `fuelLitersConsumed` /
  /// `avgLPer100Km` and re-stamp `volumetricEfficiencyUsed`. A passed
  /// null keeps the existing value — the recompute never needs to
  /// *clear* a field, so the simple form is sufficient.
  TripSummary copyWith({
    double? distanceKm,
    double? maxRpm,
    double? highRpmSeconds,
    double? idleSeconds,
    int? harshBrakes,
    int? harshAccelerations,
    double? avgLPer100Km,
    double? fuelLitersConsumed,
    DateTime? startedAt,
    DateTime? endedAt,
    String? distanceSource,
    bool? coldStartSurcharge,
    double? secondsBelowOptimalGear,
    bool? fuelRateSuspect,
    double? volumetricEfficiencyUsed,
    TripKind? kind,
    List<HarshEvent>? harshEvents,
    bool? isVirtual,
  }) =>
      TripSummary(
        distanceKm: distanceKm ?? this.distanceKm,
        maxRpm: maxRpm ?? this.maxRpm,
        highRpmSeconds: highRpmSeconds ?? this.highRpmSeconds,
        idleSeconds: idleSeconds ?? this.idleSeconds,
        harshBrakes: harshBrakes ?? this.harshBrakes,
        harshAccelerations: harshAccelerations ?? this.harshAccelerations,
        avgLPer100Km: avgLPer100Km ?? this.avgLPer100Km,
        fuelLitersConsumed: fuelLitersConsumed ?? this.fuelLitersConsumed,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        distanceSource: distanceSource ?? this.distanceSource,
        coldStartSurcharge: coldStartSurcharge ?? this.coldStartSurcharge,
        secondsBelowOptimalGear:
            secondsBelowOptimalGear ?? this.secondsBelowOptimalGear,
        fuelRateSuspect: fuelRateSuspect ?? this.fuelRateSuspect,
        volumetricEfficiencyUsed:
            volumetricEfficiencyUsed ?? this.volumetricEfficiencyUsed,
        kind: kind ?? this.kind,
        harshEvents: harshEvents ?? this.harshEvents,
        isVirtual: isVirtual ?? this.isVirtual,
      );
}

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
  /// is an OBD2 sample (GPS-only samples carry `rpm: 0` and a null
  /// fuel rate by construction). One such sample flips the whole
  /// trip — that's the "subsequent samples carry OBD2 fields" clause
  /// from the issue.
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
