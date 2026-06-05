// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../search/domain/entities/fuel_type.dart';

part 'fuel_type_efficiency_stats.freezed.dart';

/// Per-fuel-type efficiency stats for one vehicle (Epic #2881).
///
/// A derived VIEW over a vehicle's fill-ups, produced by
/// `FuelTypeEfficiencyAggregator.byFuelType`. The dominant-fuel attribution
/// model is frozen in `docs/decisions/per-fuel-efficiency-attribution.md`:
/// each closed plein-to-plein interval is attributed, whole, to the fuel that
/// contributed the most litres among its non-correction fills.
///
/// This is a read-only projection (never cached, never persisted), so it
/// carries no JSON serialization — only [freezed] for value equality and
/// `copyWith`.
@freezed
abstract class FuelTypeEfficiencyStats with _$FuelTypeEfficiencyStats {
  const factory FuelTypeEfficiencyStats({
    /// The fuel this row aggregates (grouped by [FuelType.apiValue]).
    required FuelType fuelType,

    /// Average litres / 100 km over this fuel's dominant-attributed
    /// intervals. `null` when [attributedIntervalCount] is 0 — the fuel
    /// never dominated a closed interval (only a minority in mixed tanks,
    /// or only present in the opening fill / open tail).
    double? avgL100km,

    /// Average cost per km (store currency) over this fuel's
    /// dominant-attributed intervals. `null` under the same condition as
    /// [avgL100km].
    double? avgCostPerKm,

    /// Σ `totalCost` of EVERY non-correction fill of this fuel, across all
    /// intervals (incl. the opening fill and the open tail). A per-fill
    /// fact, independent of interval attribution — "how much I have spent
    /// on this fuel in total".
    required double totalSpent,

    /// Count of all non-correction fills of this fuel.
    required int fillCount,

    /// Number of closed plein-to-plein intervals attributed to this fuel
    /// under the dominant-fuel rule. 0 ⇒ [avgL100km] / [avgCostPerKm] null.
    required int attributedIntervalCount,

    /// Of [attributedIntervalCount], how many intervals actually contained
    /// more than one fuel among their contributing non-correction fills.
    /// Drives the "N of M tanks were mixed" transparency footnote.
    required int mixedIntervalCount,
  }) = _FuelTypeEfficiencyStats;
}
