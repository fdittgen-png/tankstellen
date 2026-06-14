// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../data/trip_history_repository.dart';
import '../entities/fill_up.dart';

/// The plein-to-plein window a fill-up's linked trips fall in (#1361).
///
/// * [upper] — `fillUp.date` (inclusive).
/// * [start] — the lower bound; `null` means "no lower bound" (everything
///   before [upper] qualifies, the legacy #888 semantics for a first fill).
/// * [inclusiveLower] — whether [start] itself is in the window: exclusive
///   after a prior plein, inclusive at the earliest same-vehicle fill.
class FillUpLinkWindow {
  const FillUpLinkWindow({
    required this.start,
    required this.inclusiveLower,
    required this.upper,
  });

  final DateTime? start;
  final bool inclusiveLower;
  final DateTime upper;

  /// Whether [when] falls inside the window.
  bool contains(DateTime when) {
    final lower = start;
    if (lower != null) {
      final afterStart =
          inclusiveLower ? !when.isBefore(lower) : when.isAfter(lower);
      if (!afterStart) return false;
    }
    return !when.isAfter(upper);
  }
}

/// #3138 — the pure fill-up ↔ OBD2-trip linking logic, extracted out of the
/// `FillUpList` notifier where the same window math (find the previous plein →
/// derive the lower bound → test membership) was duplicated across the
/// "compute this fill's links" and "re-link the open window" paths.
///
/// It is a pure function over the data the caller has already loaded — no
/// Riverpod, no repository I/O, no side effects — so the plein-to-plein window
/// semantics (#1361 / #888) are unit-testable in isolation. The notifier keeps
/// the I/O (load the trip history + sibling fills, save the merged links).
class FillUpTripLinker {
  const FillUpTripLinker();

  /// The trip-history ids recorded for [fillUp]'s vehicle inside the open
  /// plein-to-plein window that ends at [fillUp]. [history] is the full
  /// trip-history list; [allFills] is every persisted fill-up (the linker
  /// filters to the same vehicle itself). Empty when [fillUp] has no vehicle
  /// bound or no trips fall in the window.
  List<String> linkedTripIdsInWindow({
    required FillUp fillUp,
    required List<TripHistoryEntry> history,
    required List<FillUp> allFills,
  }) {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return const <String>[];
    final window = windowFor(fillUp, allFills);
    final ids = <String>[];
    for (final entry in history) {
      if (entry.vehicleId != vehicleId) continue;
      final when = entry.summary.startedAt;
      if (when == null) continue;
      if (!window.contains(when)) continue;
      ids.add(entry.id);
    }
    return List.unmodifiable(ids);
  }

  /// The OTHER same-vehicle fills inside [fillUp]'s window — the partials the
  /// closing plein's link set propagates onto (#1361 whole-window semantics).
  List<FillUp> siblingsInWindow({
    required FillUp fillUp,
    required List<FillUp> allFills,
  }) {
    final window = windowFor(fillUp, allFills);
    return _siblings(fillUp, allFills)
        .where((f) => window.contains(f.date))
        .toList(growable: false);
  }

  /// The plein-to-plein window that ends at [fillUp].
  ///
  /// Lower bound: the most-recent prior **plein** (exclusive); failing that the
  /// earliest same-vehicle fill (inclusive); failing that no lower bound.
  FillUpLinkWindow windowFor(FillUp fillUp, List<FillUp> allFills) {
    final siblings = _siblings(fillUp, allFills);
    FillUp? previousPlein;
    for (final f in siblings) {
      if (!f.date.isBefore(fillUp.date)) continue;
      if (!f.isFullTank) continue;
      if (previousPlein == null || f.date.isAfter(previousPlein.date)) {
        previousPlein = f;
      }
    }
    if (previousPlein != null) {
      return FillUpLinkWindow(
        start: previousPlein.date,
        inclusiveLower: false,
        upper: fillUp.date,
      );
    }
    if (siblings.isNotEmpty) {
      return FillUpLinkWindow(
        start: siblings.first.date,
        inclusiveLower: true,
        upper: fillUp.date,
      );
    }
    return FillUpLinkWindow(
      start: null,
      inclusiveLower: true,
      upper: fillUp.date,
    );
  }

  /// Same-vehicle fills other than [fillUp], excluding corrections, oldest
  /// first. Empty when [fillUp] has no vehicle bound.
  List<FillUp> _siblings(FillUp fillUp, List<FillUp> allFills) {
    final vehicleId = fillUp.vehicleId;
    if (vehicleId == null) return const <FillUp>[];
    return allFills
        .where((f) =>
            f.vehicleId == vehicleId && f.id != fillUp.id && !f.isCorrection)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
