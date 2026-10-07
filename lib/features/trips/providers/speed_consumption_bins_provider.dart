// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/trip_history_repository.dart';
import '../domain/services/speed_consumption_histogram.dart';
import 'trip_history_provider.dart';

part 'speed_consumption_bins_provider.g.dart';

/// The two sample columns the histogram reads: speed and fuel rate.
const _speedFuelKeys = {'s', 'f'};

/// The speed-vs-consumption histogram of the carbon Charts tab, over the
/// trips [vehicleId] may claim (every trip when null; a trip with no
/// vehicle counts for every vehicle).
///
/// Every stored sample of every such trip is decoded, so the decode AND
/// the fold run on ONE worker isolate — the tab used to decode them all
/// on the UI isolate inside its `build`. Recomputes when the list changes.
@riverpod
Future<List<SpeedConsumptionBin>> speedConsumptionBins(
    Ref ref, String? vehicleId) async {
  final trips = ref.watch(tripHistoryListProvider);
  final ids = [
    for (final t in trips)
      if (t.sampleCount > 0 &&
          (vehicleId == null || t.vehicleId == null || t.vehicleId == vehicleId))
        t.id,
  ];
  final repo = ref.watch(tripHistoryRepositoryProvider);
  if (repo == null) {
    // No box (fixture-driven widget tests): the list's entries are the data.
    return aggregateSpeedConsumption([
      for (final id in ids)
        ...?ref.watch(tripHistoryDetailProvider(id))?.samples,
    ]);
  }
  if (ids.isEmpty) return aggregateSpeedConsumption(const []);
  return compute(speedConsumptionBinsFromSources, repo.columnSources(ids));
}

/// Decode + fold for [speedConsumptionBins] — a top-level `compute` entry.
@visibleForTesting
List<SpeedConsumptionBin> speedConsumptionBinsFromSources(
        List<TripColumnSource> sources) =>
    aggregateSpeedConsumption([
      for (final src in sources)
        ...samplesFromColumns(
            decodeTripColumnSource(src, _speedFuelKeys), _speedFuelKeys),
    ]);
