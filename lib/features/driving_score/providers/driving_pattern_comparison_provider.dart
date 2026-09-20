// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4366 — the read model a driving-pattern comparison surface watches.
///
/// ## What it takes, and what it refuses to own
///
/// The request carries the selected vehicle ids and the period. Both are
/// INPUTS: #4365 owns the vehicle-selection and period flow, and this
/// provider neither reads nor writes the active vehicle. Selecting two
/// vehicles to compare and *switching* the car you drive are different
/// actions, and conflating them is how a comparison screen silently
/// re-targets the whole app.
///
/// ## Why it is async
///
/// The trip list it watches is SUMMARIES-ONLY (`loadSummaries`, #3741),
/// so watching it decodes nothing. Samples are decoded per trip, behind
/// an await, in bounded chunks, and memoised in [DrivingPatternCache].
/// Nothing on this path can run inside a widget `build()`.
library;

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../trips/api.dart';
import '../data/driving_dimensions_calculator.dart';
import '../data/driving_pattern_aggregator.dart';
import '../data/driving_pattern_cache.dart';
import '../domain/driving_pattern_comparison.dart';

part 'driving_pattern_comparison_provider.g.dart';

/// The sample columns the dimension calculator actually reads. Asking
/// for these rather than the whole row keeps a decoded trip small.
const Set<String> kDrivingPatternColumns = {
  's', 'r', 'pp', 'th', 'f', 'al', 'ha', 'be', 'ct', //
};

/// What to compare: which vehicles, over which period.
@immutable
class DrivingPatternComparisonRequest {
  DrivingPatternComparisonRequest({
    required List<String> vehicleIds,
    required this.asOf,
    this.periodStart,
    this.periodEnd,
  }) : vehicleIds = List.unmodifiable(vehicleIds);

  /// The vehicles #4365's selector handed over, in display order.
  final List<String> vehicleIds;

  /// Injected clock. The provider never reads the wall clock itself —
  /// a comparison must replay identically (see `AppClock`, #3660).
  final DateTime asOf;

  final DateTime? periodStart;
  final DateTime? periodEnd;

  @override
  bool operator ==(Object other) =>
      other is DrivingPatternComparisonRequest &&
      other.asOf == asOf &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd &&
      _sameIds(other.vehicleIds, vehicleIds);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(vehicleIds), asOf, periodStart, periodEnd);

  @override
  String toString() => 'DrivingPatternComparisonRequest($vehicleIds, '
      '$periodStart..$periodEnd)';
}

bool _sameIds(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Process-wide memo of per-trip totals (#4366). Bounded and
/// fingerprinted — see [DrivingPatternCache] for what invalidates one.
@Riverpod(keepAlive: true)
DrivingPatternCache drivingPatternCache(Ref ref) => DrivingPatternCache();

/// The comparison for [request].
///
/// Re-runs whenever the trip list changes — a save, an edit, a deletion
/// or a vehicle reassignment all refresh `tripHistoryListProvider` — and
/// the per-trip cache independently misses any trip whose fingerprint or
/// model version moved.
@riverpod
Future<DrivingPatternComparison> drivingPatternComparison(
  Ref ref,
  DrivingPatternComparisonRequest request,
) async {
  final trips = ref.watch(tripHistoryListProvider);
  final repo = ref.watch(tripHistoryRepositoryProvider);
  final cache = ref.watch(drivingPatternCacheProvider);
  cache.evictMissing({for (final t in trips) t.id});

  return aggregateDrivingPatterns(
    selectedVehicleIds: request.vehicleIds,
    summaries: trips,
    asOf: request.asOf,
    periodStart: request.periodStart,
    periodEnd: request.periodEnd,
    loadTotals: (entry) => _totalsFor(entry, repo, cache),
  );
}

/// One trip's typed totals — from the cache when the fingerprint still
/// holds, otherwise by decoding just the columns the calculator reads.
///
/// A decode failure yields null (the trip contributes nothing) rather
/// than taking the whole comparison down: one unreadable row must not
/// blank a year of history.
DrivingPatternTotals? _totalsFor(
  TripHistoryEntry entry,
  TripHistoryRepository? repo,
  DrivingPatternCache cache,
) {
  final hit = cache.read(entry);
  if (hit != null) return hit;
  if (repo == null) return null;
  try {
    final samples = repo.loadSamplesWith(entry.id, kDrivingPatternColumns);
    if (samples.length < 2) return null;
    final totals = computeDrivingDimensions(
      samples,
      secondsBelowOptimalGear: entry.summary.secondsBelowOptimalGear,
    ).totals;
    cache.write(entry, totals);
    return totals;
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.storage, context: {
      'where': 'drivingPatternComparison totals',
      'entity': entry.id,
    });
    return null;
  }
}
