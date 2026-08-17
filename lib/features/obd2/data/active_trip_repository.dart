// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

// #3739 — the canonical codec functions come through the consumption
// feature's public api.dart barrel (the feature-boundary contract);
// `show` keeps this file's dependency surface explicit.
import '../../consumption/api.dart'
    show
        kTripSaveComputeSampleThreshold,
        sampleFromJson,
        sampleToJson,
        tripSummaryFromJson,
        tripSummaryToJson;
import '../../consumption/domain/trip_recorder.dart';
import 'paused_trip_repository.dart';
import '../../../core/logging/error_logger.dart';

/// Snapshot of an in-progress OBD2 recording that is healthy — i.e.
/// the BT transport is alive and samples are still arriving — but
/// might disappear if Android kills the process under memory
/// pressure (#1303).
///
/// Distinct from [PausedTripEntry], which captures an *unhealthy*
/// session (BT dropped, grace timer ticking). The active snapshot
/// is written through every few seconds while the user is driving
/// and erased on `stop()` / `reset()` / clean handoff to the paused
/// path. On launch [ActiveTripRecoveryService] picks it up if the
/// app died while it was still on disk.
///
/// Schema mirrors [PausedTripEntry] for the easy fields (id,
/// vehicleId, summary, odometer reads) and adds:
///  - `samplesJson`: the controller's per-tick captured-samples
///    buffer, JSON-encoded with the same compact key idiom the
///    [TripHistoryEntry] uses, so a recovered trip can be replayed
///    into the trip-detail charts.
///  - `phase`: the controller's logical phase at flush time; the
///    recovery service uses this to decide whether to bring the
///    user back into a "live recording" UI or an "interrupted /
///    resume?" prompt.
///  - `lastFlushedAt`: timestamp of the most recent write-through;
///    used by the recovery service's staleness check (default
///    24 h — entries older than that are discarded as abandoned).
@immutable
class ActiveTripSnapshot {
  /// Stable session id (ISO start timestamp). Matches the primary
  /// key used by [TripHistoryEntry] and [PausedTripEntry] so a
  /// crash → recover transition keeps the row identity intact.
  final String id;

  final String? vehicleId;
  final String? vin;

  /// Whether this recording was kicked off by the hands-free
  /// auto-record path (#1004). Persists across recovery so the
  /// launcher-icon badge bookkeeping stays consistent.
  final bool automatic;

  /// Whether the controller was paused / in pausedDueToDrop / live
  /// recording when the snapshot was written. The recovery service
  /// promotes any non-stopped state back into the user's hands as
  /// `pausedDueToDrop` so they have to consciously resume — we never
  /// silently rewire the BT polling loop on cold start.
  final String phase;

  /// Trip summary frozen at flush time. Reconstructed verbatim into
  /// the recovery state.
  final TripSummary summary;

  /// Per-tick captured samples (the buffer the trip-detail charts
  /// read back). Same compact JSON encoding as
  /// `TripHistoryEntry.samples`.
  final List<TripSample> samples;

  final double? odometerStartKm;
  final double? odometerLatestKm;

  /// Wall-clock when the trip began. Drives elapsed-time math in
  /// the recovered live reading.
  final DateTime startedAt;

  /// Wall-clock of the most recent write-through. Used by the
  /// staleness check on launch — anything older than 24 h is
  /// treated as abandoned (the user gave up; nothing meaningful to
  /// recover) and dropped.
  final DateTime lastFlushedAt;

  const ActiveTripSnapshot({
    required this.id,
    required this.vehicleId,
    required this.vin,
    required this.automatic,
    required this.phase,
    required this.summary,
    required this.samples,
    required this.odometerStartKm,
    required this.odometerLatestKm,
    required this.startedAt,
    required this.lastFlushedAt,
  });

  ActiveTripSnapshot copyWith({
    String? phase,
    TripSummary? summary,
    List<TripSample>? samples,
    double? odometerStartKm,
    double? odometerLatestKm,
    DateTime? lastFlushedAt,
  }) =>
      ActiveTripSnapshot(
        id: id,
        vehicleId: vehicleId,
        vin: vin,
        automatic: automatic,
        phase: phase ?? this.phase,
        summary: summary ?? this.summary,
        samples: samples ?? this.samples,
        odometerStartKm: odometerStartKm ?? this.odometerStartKm,
        odometerLatestKm: odometerLatestKm ?? this.odometerLatestKm,
        startedAt: startedAt,
        lastFlushedAt: lastFlushedAt ?? this.lastFlushedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (vin != null) 'vin': vin,
        if (automatic) 'automatic': true,
        'phase': phase,
        'summary': tripSummaryToJson(summary),
        'samples':
            samples.map(sampleToJson).toList(growable: false),
        if (odometerStartKm != null) 'odometerStartKm': odometerStartKm,
        if (odometerLatestKm != null) 'odometerLatestKm': odometerLatestKm,
        'startedAt': startedAt.toIso8601String(),
        'lastFlushedAt': lastFlushedAt.toIso8601String(),
      };

  static ActiveTripSnapshot fromJson(Map<String, dynamic> json) =>
      ActiveTripSnapshot(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        vin: json['vin'] as String?,
        automatic: (json['automatic'] as bool?) ?? false,
        phase: (json['phase'] as String?) ?? 'recording',
        summary: tripSummaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        samples: (json['samples'] as List?)
                ?.map((e) =>
                    sampleFromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false) ??
            const [],
        odometerStartKm: (json['odometerStartKm'] as num?)?.toDouble(),
        odometerLatestKm: (json['odometerLatestKm'] as num?)?.toDouble(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        lastFlushedAt: DateTime.parse(json['lastFlushedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// #3739 — the former private compact-key JSON helpers lived here and had
// silently drifted from the canonical codec: 13 summary keys (eAvg, eFuel,
// ergs, he, ier, ierd, iha, ihb, ima, kind, sc, veUsed, virt) and every
// post-#3251 sample key were missing, so a trip recovered from a crash
// snapshot lost its IMU counters, estimated-consumption figures and kind.
// The snapshot now delegates to `trip_summary_codec.dart` /
// `trip_sample_codec.dart` (via the consumption api.dart barrel) — ONE
// codec for the history, WAL and paused paths.
// ---------------------------------------------------------------------------

/// Hive-backed singleton store for the live, in-progress trip
/// snapshot (#1303).
///
/// At most ONE active snapshot is ever stored at a time — the
/// in-progress trip is, by definition, unique within the app. The
/// box is keyed on a single fixed sentinel ([_singletonKey]) so
/// every flush overwrites the previous payload. We deliberately
/// don't key on the session id: if the app is killed and the user
/// starts a *new* trip on relaunch, the recovery service for the
/// crashed session must still find it, and a stable key is the
/// simplest way to guarantee that.
///
/// Errors are logged but swallowed — losing one snapshot write is
/// preferable to throwing back into the controller's emit callback.
class ActiveTripRepository {
  final Box<String> _box;

  ActiveTripRepository({required Box<String> box}) : _box = box;

  /// Hive box name used by the production wiring. Matches
  /// `HiveBoxes.obd2ActiveTrip`.
  static const String boxName = 'obd2_active_trip';

  static const String _singletonKey = 'active';

  /// Persist [snapshot]. Overwrites any previous payload — the
  /// active-trip box only ever holds one entry.
  ///
  /// #3741 — mirrors [TripHistoryRepository.save]'s #3613 pattern: the
  /// WAL flush runs every ~5 s DURING the drive, on the isolate
  /// rendering the 4 Hz gauges, and `jsonEncode` over the whole growing
  /// sample list is O(n) per flush. Above
  /// [kTripSaveComputeSampleThreshold] samples the encode hops to a
  /// background isolate via `compute()` (`toJson()` runs synchronously
  /// first, so the map crossing the isolate boundary is plain JSON-safe
  /// data and the live buffer view can't mutate mid-encode); smaller
  /// payloads stay inline because the ~10 ms isolate hand-off dominates.
  Future<void> saveSnapshot(ActiveTripSnapshot snapshot) async {
    try {
      final json = snapshot.toJson();
      final encoded =
          snapshot.samples.length > kTripSaveComputeSampleThreshold
              ? await compute(jsonEncode, json)
              : jsonEncode(json);
      await _box.put(_singletonKey, encoded);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'ActiveTripRepository.saveSnapshot'}));
    }
  }

  /// Read the current active snapshot, or null when none is on disk
  /// or the payload can't be parsed. A corrupt row returns null and
  /// the caller treats it as "no active trip" — losing a single
  /// crash recovery is acceptable; corrupt parsing is not.
  ActiveTripSnapshot? loadSnapshot() {
    final raw = _box.get(_singletonKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return ActiveTripSnapshot.fromJson(json);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'ActiveTripRepository.loadSnapshot'}));
      return null;
    }
  }

  /// Drop the active snapshot. Called on `stop()` / `reset()` so
  /// the recovery service doesn't surface a phantom on next launch.
  Future<void> clearSnapshot() async {
    try {
      await _box.delete(_singletonKey);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'ActiveTripRepository.clearSnapshot'}));
    }
  }

  /// Helper for the recovery service: returns true when [snapshot]
  /// is older than [olderThan] relative to [now]. Encapsulates the
  /// staleness rule so the repo + service share one source of truth
  /// (default 24 h).
  static bool isStale(
    ActiveTripSnapshot snapshot, {
    required DateTime now,
    Duration olderThan = const Duration(hours: 24),
  }) {
    return now.difference(snapshot.lastFlushedAt) > olderThan;
  }
}
