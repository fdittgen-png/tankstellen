// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What identifies ONE historical vehicle comparison (#4365, Epic #4358
/// work package F) — the cache key #4366 and #4367 reuse.
///
/// A comparison is not "the comparison"; it is a question asked of a
/// fixed set of vehicles over a fixed window of recorded history, by a
/// named version of the aggregation rules. Change any of the three and
/// the answer is a different answer, so all three are in the key:
///
///  1. **which vehicles** — normalised (deduped, sorted), so selecting
///     A then B and selecting B then A is one cached result, not two;
///  2. **which period** — including the boundary rule, because a window
///     that straddles the period edge is counted under a POLICY and two
///     policies give two legitimate numbers;
///  3. **which rules** — [kVehicleComparisonEvidenceVersion] moves when
///     the aggregation changes, so a stored or replayed result can never
///     be mistaken for one the current code would produce.
///
/// The report instant is deliberately NOT in the key. `asOf` decides
/// only whether an observation is presented as current or stale, and
/// folding a wall-clock instant into a cache key would defeat the cache
/// every second. It is passed to the builder instead — through the
/// `AppClock` seam, never read from the wall clock.
library;

import 'package:meta/meta.dart';

/// Bumped whenever the aggregation rules change shape. Part of the key:
/// a result built by older rules is a different result.
const String kVehicleComparisonEvidenceVersion = 'vehicle-history/1';

/// A measured observation older than this is presented as stale rather
/// than current (#4364 [ComparisonQualification.staleBasis]).
const Duration kComparisonStaleAfter = Duration(days: 180);

/// Fewer closed windows than this cannot win a ranking — a short
/// history is not a confident winner (#4365).
const int kMinComparableWindows = 2;

/// How a closed fill window that straddles the period boundary is
/// counted.
///
/// A full-to-full window is the app's atom of measured consumption: the
/// litres it burned are known only for the whole window. Splitting one
/// at an arbitrary calendar date would mean inventing an allocation
/// nothing measured, so neither policy does that — they differ only in
/// which side of the boundary the WHOLE window falls.
enum BoundaryWindowPolicy {
  /// A window counts in the period that contains its CLOSING fill.
  ///
  /// The default. A window that opened before the period start is
  /// counted whole, carrying its pre-period opening tank with it — the
  /// litres are real and the distance is real, and the alternative is
  /// discarding a measurement because the calendar cut it.
  closingFillInPeriod,

  /// Only windows whose opening AND closing fills both fall inside the
  /// period count. Stricter, and it discards real measurements at both
  /// edges; the discarded count is reported, never hidden.
  whollyContained,
}

/// The stretch of recorded history a comparison speaks for.
@immutable
final class ComparisonPeriod {
  const ComparisonPeriod({
    this.start,
    this.end,
    this.boundaryPolicy = BoundaryWindowPolicy.closingFillInPeriod,
  });

  /// Everything on record, under the default boundary policy.
  static const ComparisonPeriod allHistory = ComparisonPeriod();

  /// Inclusive lower bound, or null for "from the first record".
  final DateTime? start;

  /// Inclusive upper bound, or null for "to the last record".
  final DateTime? end;

  final BoundaryWindowPolicy boundaryPolicy;

  bool get isAllHistory => start == null && end == null;

  /// Whether [at] falls inside the period (both bounds inclusive).
  bool contains(DateTime at) {
    final from = start;
    final to = end;
    if (from != null && at.isBefore(from)) return false;
    if (to != null && at.isAfter(to)) return false;
    return true;
  }

  /// A stable, human-readable identity for this period.
  String get signature => '${start?.toIso8601String() ?? '*'}'
      '..${end?.toIso8601String() ?? '*'}/${boundaryPolicy.name}';

  @override
  bool operator ==(Object other) =>
      other is ComparisonPeriod &&
      other.start == start &&
      other.end == end &&
      other.boundaryPolicy == boundaryPolicy;

  @override
  int get hashCode => Object.hash(start, end, boundaryPolicy);

  @override
  String toString() => 'ComparisonPeriod($signature)';
}

/// The identity of one comparison: which vehicles, over which period,
/// under which version of the rules.
@immutable
final class VehicleComparisonKey {
  /// Normalises [vehicleIds] — blanks dropped, duplicates removed, the
  /// rest sorted — so two selections of the same cars are one key.
  factory VehicleComparisonKey({
    required Iterable<String> vehicleIds,
    ComparisonPeriod period = ComparisonPeriod.allHistory,
    String evidenceVersion = kVehicleComparisonEvidenceVersion,
  }) {
    final ids = <String>{
      for (final id in vehicleIds)
        if (id.trim().isNotEmpty) id.trim(),
    }.toList(growable: false)
      ..sort();
    return VehicleComparisonKey._(
        List.unmodifiable(ids), period, evidenceVersion);
  }

  const VehicleComparisonKey._(
      this.vehicleIds, this.period, this.evidenceVersion);

  /// The compared vehicles, deduped and sorted. Order here is the
  /// CACHE order; the display order is the user's selection order and
  /// belongs to the surface, not the key.
  final List<String> vehicleIds;

  final ComparisonPeriod period;

  /// The aggregation-rule version the result was built by.
  final String evidenceVersion;

  /// True once there is something to compare against.
  bool get isComparable => vehicleIds.length >= 2;

  /// A stable string identity — safe as a map key, a log line or a
  /// widget `Key`.
  String get signature =>
      '${vehicleIds.join("+")}|${period.signature}|$evidenceVersion';

  /// The same key over [ids] instead.
  VehicleComparisonKey withVehicles(Iterable<String> ids) =>
      VehicleComparisonKey(
          vehicleIds: ids, period: period, evidenceVersion: evidenceVersion);

  /// The same vehicles over [next] instead.
  VehicleComparisonKey withPeriod(ComparisonPeriod next) =>
      VehicleComparisonKey(
          vehicleIds: vehicleIds,
          period: next,
          evidenceVersion: evidenceVersion);

  @override
  bool operator ==(Object other) {
    if (other is! VehicleComparisonKey) return false;
    if (other.period != period ||
        other.evidenceVersion != evidenceVersion ||
        other.vehicleIds.length != vehicleIds.length) {
      return false;
    }
    for (var i = 0; i < vehicleIds.length; i++) {
      if (other.vehicleIds[i] != vehicleIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(vehicleIds), period, evidenceVersion);

  @override
  String toString() => 'VehicleComparisonKey($signature)';
}
