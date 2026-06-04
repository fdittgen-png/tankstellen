// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/trip_recorder.dart';
import 'trip_history_repository.dart';

/// Drops ghost / duplicate trip records (#2833).
///
/// A "ghost" trip is a 0-sample summary-only record persisted ~1–2 s
/// before its full-sample twin, carrying an **identical summary** (the
/// real backup's pairs match `idleSeconds` to 15 decimal places). It is
/// a finalisation double-save artefact (a summary written without
/// samples, then the full trip) — never a real second drive — so it
/// inflates the trip count and double-counts distance / fuel / harsh
/// events on any list-based total.
///
/// The de-dupe rule: when a 0-sample entry shares an [_summaryKey] with
/// a sampled entry **and** their `startedAt` instants fall within
/// [ghostStartedAtTolerance], the 0-sample entry is the ghost and is
/// dropped. The sampled twin (the record that actually carries the
/// drive's telemetry) is always the survivor.
///
/// Pure + order-independent: callers (`TripHistoryRepository.loadAll`,
/// the backup importer) pass the raw list and get back the de-duped one
/// in the same relative order, with ghosts removed.

/// Two entries whose `startedAt` differ by at most this are candidate
/// twins (#2833). The real backup's ghost pairs were 1–2 s apart; 2 s
/// is the smallest tolerance that catches every observed pair without
/// risking collapsing two genuinely distinct back-to-back drives (which
/// would also have to carry byte-identical summaries to match — a
/// practical impossibility for real telemetry).
const Duration ghostStartedAtTolerance = Duration(seconds: 2);

/// Return [entries] with ghost 0-sample duplicates removed (#2833).
///
/// For every 0-sample entry, if a *different* entry exists that (a) has
/// at least one sample, (b) shares the same [_summaryKey], and (c)
/// started within [ghostStartedAtTolerance], the 0-sample entry is
/// dropped. All other entries pass through untouched and in their
/// original order.
List<TripHistoryEntry> dedupeGhostTrips(List<TripHistoryEntry> entries) {
  if (entries.length < 2) return entries;

  // Index the sampled entries by their summary key so the membership
  // test is O(1) per candidate ghost rather than O(n²) overall.
  final sampledByKey = <String, List<TripHistoryEntry>>{};
  for (final e in entries) {
    if (e.samples.isEmpty) continue;
    (sampledByKey[_summaryKey(e.summary)] ??= <TripHistoryEntry>[]).add(e);
  }
  if (sampledByKey.isEmpty) return entries;

  final result = <TripHistoryEntry>[];
  for (final e in entries) {
    if (e.samples.isEmpty && _hasSampledTwin(e, sampledByKey)) {
      // Drop the ghost — its full-sample twin survives.
      continue;
    }
    result.add(e);
  }
  return result;
}

/// Guards the finalisation double-save before a write (#2833). Returns
/// true when the caller should SKIP the write (a redundant 0-sample
/// ghost whose sampled twin is already in [existing]); as a side effect
/// it deletes — via [deleteById] — any stored 0-sample ghost the
/// incoming sampled [entry] supersedes, so the real record is the sole
/// survivor. False (write normally) for a sampled entry or a ghost with
/// no twin.
Future<bool> guardGhostDoubleSave({
  required TripHistoryEntry entry,
  required List<TripHistoryEntry> existing,
  required Future<void> Function(String id) deleteById,
}) async {
  if (entry.samples.isEmpty) {
    final survivors = dedupeGhostTrips([...existing, entry]);
    return !survivors.any((e) => identical(e, entry) || e.id == entry.id);
  }
  for (final other in existing) {
    if (other.id == entry.id || other.samples.isNotEmpty) continue;
    final survivors = dedupeGhostTrips([entry, other]);
    if (!survivors.any((e) => e.id == other.id)) {
      await deleteById(other.id);
    }
  }
  return false;
}

/// True when [ghost] (a 0-sample entry) has a sampled twin in
/// [sampledByKey] with a matching summary and a `startedAt` within
/// [ghostStartedAtTolerance].
bool _hasSampledTwin(
  TripHistoryEntry ghost,
  Map<String, List<TripHistoryEntry>> sampledByKey,
) {
  final twins = sampledByKey[_summaryKey(ghost.summary)];
  if (twins == null) return false;
  final ghostStart = ghost.summary.startedAt;
  for (final twin in twins) {
    if (identical(twin, ghost)) continue;
    final twinStart = twin.summary.startedAt;
    // Both null → no time signal, but the summary key already matched
    // every metric, so treat them as twins. Otherwise require both to
    // be present and within tolerance.
    if (ghostStart == null && twinStart == null) return true;
    if (ghostStart == null || twinStart == null) continue;
    if (ghostStart.difference(twinStart).abs() <= ghostStartedAtTolerance) {
      return true;
    }
  }
  return false;
}

/// Stable identity of a trip's summary for twin detection (#2833).
///
/// Folds the metrics a real ghost pair matches to full precision —
/// distance, fuel, idle / high-RPM seconds, peak RPM and the harsh
/// counters. `startedAt` is deliberately EXCLUDED (the ghost twin is
/// 1–2 s off, handled by the tolerance gate); the full-precision
/// `toString()` of each double keeps the "15 decimals" fidelity the
/// issue describes without floating-point rounding.
String _summaryKey(TripSummary s) => [
      s.distanceKm,
      s.maxRpm,
      s.highRpmSeconds,
      s.idleSeconds,
      s.harshBrakes,
      s.harshAccelerations,
      s.avgLPer100Km,
      s.fuelLitersConsumed,
    ].map((v) => v?.toString() ?? 'null').join('|');
