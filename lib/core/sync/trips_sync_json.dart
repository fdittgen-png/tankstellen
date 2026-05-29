// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../features/consumption/data/trip_history_repository.dart';

/// Trip-sync JSON payload shapers, split out of `trips_sync.dart` so the
/// wire/merge class stays under the file-length cap (#2319). Both are
/// pure functions over [TripHistoryEntry.toJson].

/// Strips the per-tick `samples` and GPS-diagnostics arrays from a
/// [TripHistoryEntry]'s JSON form so the upload payload stays under the
/// 1 KB target for `public.trip_summaries.data` (#1479 phase 2). The
/// full-detail blob (samples + gpsd) lands in `public.trip_details` via
/// [tripDetailsJson] instead.
Map<String, dynamic> compactSummaryJson(TripHistoryEntry entry) {
  final json = entry.toJson();
  json.remove('samples');
  json.remove('gpsd');
  return json;
}

/// Mirror of [compactSummaryJson] for the heavy blob: returns just
/// `samples` + `gpsd` for the `trip_details.data` payload. Empty arrays
/// are emitted explicitly so a future fetch round-trips through
/// `TripHistoryEntry.fromJson` cleanly even when only one of the two
/// arrays was populated at recording time.
Map<String, dynamic> tripDetailsJson(TripHistoryEntry entry) {
  final json = entry.toJson();
  return {
    'samples': json['samples'] ?? const [],
    'gpsd': json['gpsd'] ?? const [],
  };
}
