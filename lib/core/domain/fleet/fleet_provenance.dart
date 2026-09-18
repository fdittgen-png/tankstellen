// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../consumption_estimate.dart';

/// The source class every fleet metric must name (#4212, ADR 0025).
///
/// #4212 lists five: `measured_fill_up`, `obd_measured`, `gps_estimated`,
/// `imported`, `derived`. This enum adds **one** — [obdEstimated] —
/// because ADR 0022's [ConsumptionSourceClass.estimated] is a MAF /
/// speed-density litre with the pump gain applied: engine data, but a
/// modelled number. Filing it under [obdMeasured] would be exactly the
/// estimate-to-measured promotion #4219 forbids; filing it under
/// [gpsEstimated] would misstate its inputs. The mapping in
/// [fromConsumptionSourceClass] is exhaustive, so a new consumption
/// class is a compile error here rather than a silent mis-label.
///
/// [wireName] is the snake_case vocabulary #4212 uses; it is what a
/// persisted fleet row carries, never a Dart enum name.
enum FleetMetricSource {
  /// Litres and price from a fill-up the employee entered or confirmed.
  measuredFillUp('measured_fill_up'),

  /// A native ECU fuel reading (PID 9D / A2 / 5E) — observed.
  obdMeasured('obd_measured'),

  /// MAF / speed-density — engine data, but a modelled litre, pump-gain
  /// applied once (ADR 0022).
  obdEstimated('obd_estimated'),

  /// GPS-physics only: no engine data at all.
  gpsEstimated('gps_estimated'),

  /// Asserted by a third party (a fuel-card statement, a CSV) — neither
  /// observed by the app nor modelled by it. It becomes a measured fact
  /// only after the employee confirms it (ADR 0025).
  imported('imported'),

  /// Computed from other metrics; [ClaimedValue.derive] appends it.
  derived('derived');

  const FleetMetricSource(this.wireName);

  /// The #4212 snake_case name a persisted row carries.
  final String wireName;

  /// The source for a #4212 wire name, or null for an unknown string —
  /// a row written by a newer build must not decode as *some* source.
  static FleetMetricSource? fromWireName(String name) {
    for (final s in values) {
      if (s.wireName == name) return s;
    }
    return null;
  }

  /// ADR 0022's branch vocabulary → fleet provenance. Null for
  /// [ConsumptionSourceClass.none]: no figure has no source.
  static FleetMetricSource? fromConsumptionSourceClass(
          ConsumptionSourceClass source) =>
      switch (source) {
        ConsumptionSourceClass.measured => obdMeasured,
        ConsumptionSourceClass.estimated => obdEstimated,
        ConsumptionSourceClass.gpsOnly => gpsEstimated,
        ConsumptionSourceClass.none => null,
      };
}

/// The two predicates the claim rules read.
extension FleetMetricSourceRules on FleetMetricSource {
  /// Observed — by the pump or by the ECU. Only these may back a
  /// [ClaimClass.measuredFact].
  bool get isMeasured =>
      this == FleetMetricSource.measuredFillUp ||
      this == FleetMetricSource.obdMeasured;

  /// Modelled. Anything built on one of these is qualified (`≈`).
  bool get isEstimate =>
      this == FleetMetricSource.obdEstimated ||
      this == FleetMetricSource.gpsEstimated;
}
