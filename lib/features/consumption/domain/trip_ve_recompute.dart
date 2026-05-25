// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Retroactive volumetric-efficiency (η_v) recompute (#1858).
//
// When a vehicle's η_v is corrected, every stored trip that recorded
// the η_v its fuel was integrated with (`TripSummary.volumetricEfficiencyUsed`,
// #1858 part A) can be recomputed: speed-density fuel scales linearly
// with η_v, so the corrected figure is
// `fuelLitersConsumed × (newVe / volumetricEfficiencyUsed)`, and
// `avgLPer100Km` rescales by the same factor.
//
// A trip with a null `volumetricEfficiencyUsed` is not recalculable —
// a legacy trip, or one whose fuel came (even partly) from PID 5E or
// the MAF branch, neither of which uses η_v — and is returned
// untouched. Returning the same instance in that case lets callers
// cheaply detect "nothing changed" with `identical`.

import '../data/trip_history_repository.dart';

/// Recompute one trip for a corrected [newVe].
///
/// Returns [entry] unchanged (the identical instance) when it carries
/// no η_v provenance, when [newVe] already matches the stamped value,
/// or when either η_v is non-positive (defensive — a stamped value is
/// always a real 0.6–0.95-ish efficiency).
TripHistoryEntry recomputeTripForVe(TripHistoryEntry entry, double newVe) {
  final used = entry.summary.volumetricEfficiencyUsed;
  if (used == null || used <= 0 || newVe <= 0 || used == newVe) {
    return entry;
  }
  final factor = newVe / used;
  final s = entry.summary;
  return entry.copyWith(
    summary: s.copyWith(
      fuelLitersConsumed:
          s.fuelLitersConsumed == null ? null : s.fuelLitersConsumed! * factor,
      avgLPer100Km:
          s.avgLPer100Km == null ? null : s.avgLPer100Km! * factor,
      // Re-stamp so a later η_v change rescales from the new basis.
      volumetricEfficiencyUsed: newVe,
    ),
  );
}

/// Recompute every trip in [trips] for [newVe]. Order is preserved;
/// not-recalculable trips pass through untouched (same instance).
List<TripHistoryEntry> recomputeTripsForVe(
  List<TripHistoryEntry> trips,
  double newVe,
) =>
    [for (final t in trips) recomputeTripForVe(t, newVe)];
