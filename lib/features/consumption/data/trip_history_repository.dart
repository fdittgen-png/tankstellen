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

  /// Whether this trip was captured by the auto-record path
  /// (#1004 phase 4). Drives the badge-decrement call when the user
  /// opens the detail screen — manual trips don't decrement because
  /// they were never counted as "unseen". Defaults to false so all
  /// pre-#1004 entries deserialise as manual.
  final bool automatic;

  const TripHistoryEntry({
    required this.id,
    required this.vehicleId,
    required this.summary,
    this.automatic = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': _summaryToJson(summary),
        if (automatic) 'automatic': true,
      };

  static TripHistoryEntry fromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: _summaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        automatic: (json['automatic'] as bool?) ?? false,
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
      // #800: provenance of distanceKm — `'real'` for odometer-backed
      // trips, `'virtual'` for speed-integrated estimates. Older trips
      // serialised before this field landed deserialise as `'virtual'`
      // to match the recorder's historical behaviour.
      'distanceSource': s.distanceSource,
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
      // Default to 'virtual' for pre-#800 trips — that's the honest
      // label for legacy recordings, which integrated speed samples
      // regardless of whether an odometer was available.
      distanceSource: (j['distanceSource'] as String?) ?? 'virtual',
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
