// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'consumption_providers.dart';

/// #3762 — the plein-to-plein window helpers of [FillUpList], split out
/// of `consumption_providers.dart` as a `part` mixin to satisfy the
/// #1680 file-length ratchet. Move-only: behaviour preserved verbatim.
mixin _FillUpListWindows on _$FillUpList {
  /// Compute the trip-history ids recorded for [fillUp.vehicleId]
  /// in the OPEN plein-to-plein window that ends at [fillUp].
  ///
  /// Window semantics (#1361):
  ///   - upper bound: `fillUp.date` (inclusive).
  ///   - lower bound: most-recent prior plein (exclusive) for the
  ///     same vehicle, or — when no prior plein exists — the first
  ///     same-vehicle fill-up's date (inclusive).
  ///
  /// Returns an empty list when the fill-up has no vehicle bound,
  /// the trip-history repository isn't available, or no trips fall
  /// in the window.
  List<String> _linkedTripIdsForWholeWindow(FillUp fillUp) {
    // #3138 — the plein-to-plein window math is the pure [FillUpTripLinker];
    // the notifier only supplies the loaded trip history + sibling fills.
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return const <String>[];
    return const FillUpTripLinker().linkedTripIdsInWindow(
      fillUp: fillUp,
      history: repo.loadSummaries(), // #3613 — linker reads ids+summaries
      allFills: ref.read(fillUpRepositoryProvider).getAll(),
    );
  }

  /// After saving [closing], propagate its `linkedTripIds` to every
  /// other fill in the same open plein-to-plein window so the
  /// derived relationship is the same on each fill (#1361). This is
  /// the whole-window semantic the user requested: "the trajets
  /// since then are related to all fill-ups since then".
  ///
  /// The window is the same one [_linkedTripIdsForWholeWindow]
  /// computed for [closing]; when [closing] is a plein, we cover the
  /// fills between the previous plein and the closing one (the
  /// partials), and when [closing] is itself a partial, we still
  /// cover the open window so the prior partial picks up the new
  /// trips.
  Future<void> _relinkOpenWindow(FillUp closing) async {
    final repo = ref.read(fillUpRepositoryProvider);
    // #3138 — same window math as [_linkedTripIdsForWholeWindow], via the
    // shared [FillUpTripLinker]: the partials in [closing]'s open window.
    final inWindow = const FillUpTripLinker()
        .siblingsInWindow(fillUp: closing, allFills: repo.getAll());
    final newIds = closing.linkedTripIds;
    for (final f in inWindow) {
      // Merge — preserve any pre-existing ids, add the new set.
      final merged = <String>{...f.linkedTripIds, ...newIds}.toList();
      if (merged.length == f.linkedTripIds.length &&
          merged.toSet().difference(f.linkedTripIds.toSet()).isEmpty) {
        continue;
      }
      // #3122 — the trip-link set changed: stamp so LWW propagates it.
      await repo.save(f.copyWith(
        linkedTripIds: merged,
        updatedAt: DateTime.now().toUtc(),
      ));
    }
  }


  /// Sum the [TripSummary.distanceKm] across every trip in the same
  /// plein-to-plein window the [Reconciler] uses. Inlined here so the
  /// reconciler can stay pure and free of the L/100 km derivation.
  double _windowDistanceKm({
    required FillUp closingPlein,
    required List<FillUp> allFillUpsForVehicle,
    required List<TripSummary> tripsForVehicle,
  }) {
    final vehicleId = closingPlein.vehicleId;
    final sameVehicleFills = allFillUpsForVehicle
        .where(
          (f) =>
              f.vehicleId == vehicleId &&
              !f.isCorrection &&
              f.id != closingPlein.id,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    FillUp? previousPlein;
    for (final f in sameVehicleFills) {
      if (!f.date.isBefore(closingPlein.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }
    DateTime windowStart;
    bool inclusiveLower;
    if (previousPlein != null) {
      windowStart = previousPlein.date;
      inclusiveLower = false;
    } else {
      windowStart = sameVehicleFills.isEmpty
          ? closingPlein.date
          : sameVehicleFills.first.date;
      inclusiveLower = true;
    }
    double sum = 0;
    for (final t in tripsForVehicle) {
      final when = t.startedAt;
      if (when == null) continue;
      final afterStart = inclusiveLower
          ? !when.isBefore(windowStart)
          : when.isAfter(windowStart);
      if (!afterStart) continue;
      if (when.isAfter(closingPlein.date)) continue;
      sum += t.distanceKm;
    }
    return sum;
  }
}
