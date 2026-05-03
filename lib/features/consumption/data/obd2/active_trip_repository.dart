import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/trip_recorder.dart';
import 'paused_trip_repository.dart';

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
        'summary': _summaryToJson(summary),
        'samples':
            samples.map(_sampleToJson).toList(growable: false),
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
        summary: _summaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        samples: (json['samples'] as List?)
                ?.map((e) =>
                    _sampleFromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false) ??
            const [],
        odometerStartKm: (json['odometerStartKm'] as num?)?.toDouble(),
        odometerLatestKm: (json['odometerLatestKm'] as num?)?.toDouble(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        lastFlushedAt: DateTime.parse(json['lastFlushedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Compact-key JSON helpers — kept private to this file so the schema
// stays grep-able alongside the snapshot it serialises. The shape is
// intentionally aligned with `trip_history_repository.dart` so a
// recovered trip's samples deserialise identically when the user
// completes the trip.
// ---------------------------------------------------------------------------

Map<String, dynamic> _summaryToJson(TripSummary s) => {
      'distanceKm': s.distanceKm,
      'maxRpm': s.maxRpm,
      'highRpmSeconds': s.highRpmSeconds,
      'idleSeconds': s.idleSeconds,
      'harshBrakes': s.harshBrakes,
      'harshAccelerations': s.harshAccelerations,
      if (s.avgLPer100Km != null) 'avgLPer100Km': s.avgLPer100Km,
      if (s.fuelLitersConsumed != null)
        'fuelLitersConsumed': s.fuelLitersConsumed,
      if (s.startedAt != null) 'startedAt': s.startedAt!.toIso8601String(),
      if (s.endedAt != null) 'endedAt': s.endedAt!.toIso8601String(),
      'distanceSource': s.distanceSource,
      'cs': s.coldStartSurcharge,
      if (s.secondsBelowOptimalGear != null)
        'sblog': s.secondsBelowOptimalGear,
    };

TripSummary _summaryFromJson(Map<String, dynamic> j) => TripSummary(
      distanceKm: (j['distanceKm'] as num).toDouble(),
      maxRpm: (j['maxRpm'] as num).toDouble(),
      highRpmSeconds: (j['highRpmSeconds'] as num).toDouble(),
      idleSeconds: (j['idleSeconds'] as num).toDouble(),
      harshBrakes: (j['harshBrakes'] as num).toInt(),
      harshAccelerations: (j['harshAccelerations'] as num).toInt(),
      avgLPer100Km: (j['avgLPer100Km'] as num?)?.toDouble(),
      fuelLitersConsumed: (j['fuelLitersConsumed'] as num?)?.toDouble(),
      startedAt: j['startedAt'] == null
          ? null
          : DateTime.parse(j['startedAt'] as String),
      endedAt: j['endedAt'] == null
          ? null
          : DateTime.parse(j['endedAt'] as String),
      distanceSource: (j['distanceSource'] as String?) ?? 'virtual',
      coldStartSurcharge: (j['cs'] as bool?) ?? false,
      secondsBelowOptimalGear: (j['sblog'] as num?)?.toDouble(),
    );

Map<String, dynamic> _sampleToJson(TripSample s) => {
      't': s.timestamp.millisecondsSinceEpoch,
      's': s.speedKmh,
      'r': s.rpm,
      if (s.fuelRateLPerHour != null) 'f': s.fuelRateLPerHour,
      if (s.throttlePercent != null) 'th': s.throttlePercent,
      if (s.engineLoadPercent != null) 'el': s.engineLoadPercent,
      if (s.coolantTempC != null) 'ct': s.coolantTempC,
      // #1374 phase 1: GPS fix mirror keys. Aligned with
      // `trip_history_repository.dart` so a recovered active trip's
      // samples deserialise identically when the user finishes it.
      if (s.latitude != null) 'la': s.latitude,
      if (s.longitude != null) 'lo': s.longitude,
    };

TripSample _sampleFromJson(Map<String, dynamic> j) => TripSample(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['t'] as num).toInt(),
      ),
      speedKmh: (j['s'] as num).toDouble(),
      rpm: (j['r'] as num).toDouble(),
      fuelRateLPerHour: (j['f'] as num?)?.toDouble(),
      throttlePercent: (j['th'] as num?)?.toDouble(),
      engineLoadPercent: (j['el'] as num?)?.toDouble(),
      coolantTempC: (j['ct'] as num?)?.toDouble(),
      // #1374 phase 1: legacy active-trip snapshots written before
      // this PR carry no GPS keys → null on both fields.
      latitude: (j['la'] as num?)?.toDouble(),
      longitude: (j['lo'] as num?)?.toDouble(),
    );

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
  Future<void> saveSnapshot(ActiveTripSnapshot snapshot) async {
    try {
      await _box.put(_singletonKey, jsonEncode(snapshot.toJson()));
    } catch (e, st) {
      debugPrint('ActiveTripRepository.saveSnapshot: $e\n$st');
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
      debugPrint('ActiveTripRepository.loadSnapshot: $e\n$st');
      return null;
    }
  }

  /// Drop the active snapshot. Called on `stop()` / `reset()` so
  /// the recovery service doesn't surface a phantom on next launch.
  Future<void> clearSnapshot() async {
    try {
      await _box.delete(_singletonKey);
    } catch (e, st) {
      debugPrint('ActiveTripRepository.clearSnapshot: $e\n$st');
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
