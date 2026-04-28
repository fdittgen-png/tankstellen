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

  /// Per-tick recording profile used by the trip-detail charts (#1040).
  ///
  /// Captured by [TripRecordingController] at ~1 Hz throughout the
  /// recording — the speed / RPM / fuel-rate fields render the
  /// speed / fuel-rate / RPM line charts in the trip-detail screen.
  /// Empty for legacy trips written before #1040 landed: the charts
  /// fall back to the shared "No samples recorded" caption in that
  /// case, which is the honest answer for trips whose buffer was
  /// never persisted.
  ///
  /// Storage budget: ~1 Hz × 8 fields, so a 39-min trip is roughly
  /// 19 KB compressed. A year of daily commutes is around 7 MB —
  /// well below the rolling-log cap.
  final List<TripSample> samples;

  const TripHistoryEntry({
    required this.id,
    required this.vehicleId,
    required this.summary,
    this.automatic = false,
    this.samples = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': _summaryToJson(summary),
        if (automatic) 'automatic': true,
        if (samples.isNotEmpty)
          'samples': samples.map(_sampleToJson).toList(growable: false),
      };

  static TripHistoryEntry fromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: _summaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        automatic: (json['automatic'] as bool?) ?? false,
        samples: (json['samples'] as List?)
                ?.map(
                    (e) => _sampleFromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false) ??
            const [],
      );
}

/// Serialise a single [TripSample]. Compact key names
/// ('t','s','r','f','th','el','ct') keep per-trip JSON small — a
/// 39-min trip × 1 Hz lands around 19 KB compressed at this density.
/// Use millisecondsSinceEpoch for the timestamp so the JSON parses
/// fast and round-trips precisely. The optional `'th'` (#1261),
/// `'el'` and `'ct'` (#1262) keys are only emitted when the
/// corresponding PID was actually read — legacy trips written before
/// each key landed deserialise with the field null.
Map<String, dynamic> _sampleToJson(TripSample s) => {
      't': s.timestamp.millisecondsSinceEpoch,
      's': s.speedKmh,
      'r': s.rpm,
      if (s.fuelRateLPerHour != null) 'f': s.fuelRateLPerHour,
      if (s.throttlePercent != null) 'th': s.throttlePercent,
      if (s.engineLoadPercent != null) 'el': s.engineLoadPercent,
      if (s.coolantTempC != null) 'ct': s.coolantTempC,
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
    );

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
      // #1262 phase 2: cold-start surcharge bit. Compact key 'cs'
      // because every trip carries this and we'd rather not pay six
      // bytes per record. Legacy trips without the key default false.
      'cs': s.coldStartSurcharge,
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
      // #1262 phase 2: pre-existing trips were persisted before the
      // cold-start surcharge heuristic landed; default false rather
      // than retroactively flag them.
      coldStartSurcharge: (j['cs'] as bool?) ?? false,
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

  /// Optional hook fired after a successful [save] when the saved
  /// entry's `vehicleId` is non-null (#1193 phase 2). Production wires
  /// this from `app_initializer.dart` to dispatch a vehicle-aggregate
  /// recompute via [VehicleAggregateUpdater]; tests inject a fake to
  /// observe the call.
  ///
  /// IMPORTANT — the hook MUST NOT throw. It's invoked synchronously
  /// from inside [save] and any throw is caught and logged via
  /// `errorLogger.log(ErrorLayer.background, ...)` so the save flow is
  /// never derailed by an aggregator failure. The hook itself should
  /// fire-and-forget any async work it kicks off (use `unawaited(...)`
  /// at the call site).
  void Function(String vehicleId)? onSavedHook;

  TripHistoryRepository({
    required Box<String> box,
    this.cap = 100,
    this.onSavedHook,
  }) : _box = box;

  /// Box name used by the production wiring.
  static const String boxName = 'obd2_trip_history';

  /// Persist [entry]. Drops the oldest trip when the box reaches
  /// [cap]. Errors are logged but swallowed — losing one rolling-log
  /// entry shouldn't propagate up into the trip-stop flow.
  Future<void> save(TripHistoryEntry entry) async {
    try {
      await _box.put(entry.id, jsonEncode(entry.toJson()));
    } catch (e, st) {
      debugPrint('TripHistoryRepository.save: $e\n$st');
      return;
    }
    await _trim();

    // Fire the post-save hook for vehicle-attributed trips. Wrapped in
    // a try/catch because the hook is user code (production: an
    // aggregator dispatch) and a failure there must not propagate up
    // into the trip-save flow — the trip already persisted. The hook
    // is responsible for fire-and-forget on its own async work.
    final vehicleId = entry.vehicleId;
    final hook = onSavedHook;
    if (vehicleId != null && hook != null) {
      try {
        hook(vehicleId);
      } catch (e, st) {
        debugPrint('TripHistoryRepository.save onSavedHook: $e\n$st');
      }
    }
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
      } catch (e, st) {
        debugPrint('TripHistoryRepository.loadAll: skipping $key: $e\n$st');
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
