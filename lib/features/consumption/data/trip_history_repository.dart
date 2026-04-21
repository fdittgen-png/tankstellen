import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/trip_recorder.dart';

/// One finalised trip as shown in the Trip history list (#726).
///
/// Wraps a [TripSummary] with the persisted bookkeeping fields — a
/// stable id so list widgets can key on it, and the vehicleId so the
/// list can be filtered down the road. The summary already carries
/// `startedAt` / `endedAt`; we don't duplicate those here.
@immutable
class TripHistoryEntry {
  final String id;
  final String? vehicleId;
  final TripSummary summary;

  const TripHistoryEntry({
    required this.id,
    required this.vehicleId,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': _summaryToJson(summary),
      };

  static TripHistoryEntry fromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: _summaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
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

/// Hive-backed list of finalised trips (#726).
///
/// Stores at most [cap] entries keyed by a stable trip id (ISO start
/// timestamp). Oldest entries drop off when the cap is hit — trip
/// history is a rolling log, not an archive. The box holds one JSON
/// payload per entry so a single corrupt write can be skipped without
/// killing the whole list.
class TripHistoryRepository {
  final Box<String> _box;
  final int cap;

  TripHistoryRepository({
    required Box<String> box,
    this.cap = 100,
  }) : _box = box;

  /// Box name used by the production wiring.
  static const String boxName = 'obd2_trip_history';

  /// Persist [entry]. Drops the oldest trip when the box reaches
  /// [cap]. Errors are logged but swallowed — losing one rolling-log
  /// entry shouldn't propagate up into the trip-stop flow.
  Future<void> save(TripHistoryEntry entry) async {
    try {
      await _box.put(entry.id, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('TripHistoryRepository.save: $e');
      return;
    }
    await _trim();
  }

  /// Return every persisted trip, sorted newest-first. Corrupt
  /// payloads are silently skipped so one bad write doesn't hide the
  /// whole list.
  List<TripHistoryEntry> loadAll() {
    final result = <TripHistoryEntry>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
        result.add(TripHistoryEntry.fromJson(json));
      } catch (e) {
        debugPrint('TripHistoryRepository.loadAll: skipping $key: $e');
      }
    }
    result.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax); // newest first
    });
    return result;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> _trim() async {
    if (_box.length <= cap) return;
    final entries = loadAll(); // newest-first
    final toDrop = entries.skip(cap).map((e) => e.id).toList();
    for (final id in toDrop) {
      await _box.delete(id);
    }
  }
}
