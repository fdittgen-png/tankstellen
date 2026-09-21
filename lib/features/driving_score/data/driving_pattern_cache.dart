// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4366 — the per-trip totals cache that keeps a driving-pattern
/// comparison off the sample-decoding path on every rebuild.
///
/// ## What invalidates an entry
///
/// The key is the trip id; the entry is only returned when its
/// **fingerprint** still matches. The fingerprint deliberately covers
/// more than the samples:
///
///  * [kDrivingPatternModelVersion] — a changed model or threshold must
///    re-derive, never average two definitions together;
///  * the stored sample count, distance and both timestamps — a trip
///    EDITED or re-finalised no longer matches;
///  * the owning vehicle id — a REASSIGNED trip is a miss, so a
///    reassignment can never be served from the previous owner's cached
///    aggregation.
///
/// A DELETED trip is dropped by [evictMissing], which is handed the ids
/// that still exist. Nothing here touches the selected vehicles or the
/// active vehicle: this cache knows only trips.
library;

import 'dart:collection';

import '../../trips/api.dart';
import '../domain/driving_pattern_evidence.dart';

/// Default ceiling on cached trips. Bounded on purpose: a multi-year
/// history must not pin every trip's totals in memory.
const int kDrivingPatternCacheCapacity = 400;

/// A bounded, fingerprinted LRU of per-trip [DrivingPatternTotals].
class DrivingPatternCache {
  DrivingPatternCache({this.capacity = kDrivingPatternCacheCapacity});

  final int capacity;
  final LinkedHashMap<String, _CacheEntry> _entries =
      LinkedHashMap<String, _CacheEntry>();

  /// Cached totals for [trip], or null on a miss.
  DrivingPatternTotals? read(TripHistoryEntry trip) {
    final entry = _entries[trip.id];
    if (entry == null) return null;
    if (entry.fingerprint != fingerprintOf(trip)) {
      _entries.remove(trip.id);
      return null;
    }
    // Touch: most-recently-used moves to the end.
    _entries
      ..remove(trip.id)
      ..[trip.id] = entry;
    return entry.totals;
  }

  void write(TripHistoryEntry trip, DrivingPatternTotals totals) {
    _entries
      ..remove(trip.id)
      ..[trip.id] = _CacheEntry(fingerprintOf(trip), totals);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Drop every entry whose trip no longer exists (deleted history).
  void evictMissing(Set<String> liveTripIds) {
    _entries.removeWhere((id, _) => !liveTripIds.contains(id));
  }

  void clear() => _entries.clear();

  int get length => _entries.length;
}

/// Everything about [trip] that, if changed, makes cached totals wrong.
String fingerprintOf(TripHistoryEntry trip) {
  final s = trip.summary;
  return [
    kDrivingPatternModelVersion,
    trip.vehicleId ?? '-',
    trip.sampleCount,
    s.distanceKm,
    s.startedAt?.microsecondsSinceEpoch ?? 0,
    s.endedAt?.microsecondsSinceEpoch ?? 0,
    s.coldStartSurcharge,
  ].join('|');
}

class _CacheEntry {
  const _CacheEntry(this.fingerprint, this.totals);
  final String fingerprint;
  final DrivingPatternTotals totals;
}
