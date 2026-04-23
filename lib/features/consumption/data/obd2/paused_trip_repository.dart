import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../domain/trip_recorder.dart';

/// Snapshot of an in-progress OBD2 recording that was paused because
/// the Bluetooth transport dropped (#797 phase 1).
///
/// Stored verbatim to the `obd2_paused_trips` Hive box so the user can
/// resume right where they left off once the adapter reconnects. The
/// serialised payload carries everything the
/// [TripRecordingController] needs to rehydrate its internal
/// accumulators:
///   - trip identity (id = ISO start timestamp, vehicleId, VIN),
///   - the current [TripSummary] (distance, max RPM, idle/harsh
///     counters, fuel estimate so far, start + end timestamps),
///   - the last-known odometer reads,
///   - the timestamp the drop was detected (used for grace-window
///     bookkeeping).
@immutable
class PausedTripEntry {
  /// ISO 8601 start timestamp — matches the id used by the finalised
  /// [TripHistoryEntry] so a paused→finalised transition keeps the
  /// same primary key.
  final String id;

  final String? vehicleId;
  final String? vin;
  final TripSummary summary;
  final double? odometerStartKm;
  final double? odometerLatestKm;
  final DateTime pausedAt;

  const PausedTripEntry({
    required this.id,
    required this.vehicleId,
    required this.vin,
    required this.summary,
    required this.odometerStartKm,
    required this.odometerLatestKm,
    required this.pausedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (vin != null) 'vin': vin,
        'summary': _summaryToJson(summary),
        if (odometerStartKm != null) 'odometerStartKm': odometerStartKm,
        if (odometerLatestKm != null) 'odometerLatestKm': odometerLatestKm,
        'pausedAt': pausedAt.toIso8601String(),
      };

  static PausedTripEntry fromJson(Map<String, dynamic> json) =>
      PausedTripEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        vin: json['vin'] as String?,
        summary: _summaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        odometerStartKm: (json['odometerStartKm'] as num?)?.toDouble(),
        odometerLatestKm: (json['odometerLatestKm'] as num?)?.toDouble(),
        pausedAt: DateTime.parse(json['pausedAt'] as String),
      );
}

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
    );

/// Hive-backed store for paused OBD2 trips (#797 phase 1).
///
/// Mirrors the very small API surface the
/// [TripRecordingController] needs — save, load, list, delete. Like
/// [TripHistoryRepository], errors are logged but swallowed so a
/// single corrupt write doesn't take down the pause/resume flow.
class PausedTripRepository {
  final Box<String> _box;

  PausedTripRepository({required Box<String> box}) : _box = box;

  /// Hive box name used by the production wiring. Kept in sync with
  /// [HiveBoxes.obd2PausedTrips].
  static const String boxName = 'obd2_paused_trips';

  /// Persist [entry]. Overwrites any previous payload at the same id
  /// (ISO start timestamp) so repeated drops during a single session
  /// keep converging on the most recent partial.
  Future<void> save(PausedTripEntry entry) async {
    try {
      await _box.put(entry.id, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('PausedTripRepository.save: $e');
    }
  }

  /// Read a specific paused trip by id, or null when it's missing or
  /// unparseable. Corrupt rows are dropped so one bad write never
  /// blocks a resume.
  PausedTripEntry? load(String id) {
    final raw = _box.get(id);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return PausedTripEntry.fromJson(json);
    } catch (e) {
      debugPrint('PausedTripRepository.load: $e');
      return null;
    }
  }

  /// Return every paused trip, newest-first. Corrupt payloads are
  /// silently skipped.
  List<PausedTripEntry> loadAll() {
    final result = <PausedTripEntry>[];
    for (final key in _box.keys) {
      final entry = load(key as String);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) => b.pausedAt.compareTo(a.pausedAt));
    return result;
  }

  /// Drop [id] from the paused-trips box. Call this on resume or
  /// after the grace window auto-finalises the entry into
  /// [obd2_trip_history].
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      debugPrint('PausedTripRepository.delete: $e');
    }
  }
}
