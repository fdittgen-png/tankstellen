// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_sample.dart';
import 'trip_history_entry.dart';

/// #3882 — the column-set helpers of [TripHistoryEntry.columnsPresent]
/// (split out of `trip_history_entry.dart`, 400-line cap).
extension TripHistoryEntryColumns on TripHistoryEntry {
  /// The same entry with [TripHistoryEntry.columnsPresent] attached.
  TripHistoryEntry withColumnsPresent(Set<String>? cols) => cols == null
      ? this
      : TripHistoryEntry(
          id: id,
          vehicleId: vehicleId,
          summary: summary,
          automatic: automatic,
          samples: samples,
          sampleCount: sampleCount,
          adapterMac: adapterMac,
          adapterName: adapterName,
          adapterFirmware: adapterFirmware,
          gpsSampleDiagnostics: gpsSampleDiagnostics,
          lifecycleMarks: lifecycleMarks,
          obd2Diagnostic: obd2Diagnostic,
          verdict: verdict,
          termination: termination,
          sessionJournal: sessionJournal,
          engineSampleCount: engineSampleCount,
          envelopeSampleCount: envelopeSampleCount,
          columnsPresent: cols,
        );

  /// True when [column] (a codec key) carries a value somewhere in the
  /// trip — O(1) on a v2 row, a scan of `samples` otherwise.
  bool hasColumn(String column, bool Function(TripSample s) probe) =>
      columnsPresent?.contains(column) ?? samples.any(probe);
}
