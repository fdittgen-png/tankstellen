// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/trip_recorder.dart';
import 'trip_sample_codec.dart';
import '../../../core/logging/error_logger.dart';

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

  /// Stable BLE remote-id / Classic MAC of the OBD2 adapter that was
  /// connected when this trip was recorded (#1312). Lets the trip
  /// detail summary card name the suspect device when the user files
  /// a bug report about adapter-specific PID gaps. Null for trips
  /// recorded before #1312 landed and for any trip whose connect path
  /// didn't stamp the service (e.g. test fakes).
  final String? adapterMac;
  /// Friendly device name advertised by the OBD2 adapter, falling
  /// back to the registry's display label when the advertisement was
  /// empty (#1312). Same null-semantics as [adapterMac].
  final String? adapterName;
  /// ELM327 firmware string returned by `ATI` during the init
  /// sequence, when the connect path captured one (#1312). Currently
  /// always null in production; persisted as a forward-compat field
  /// so a future enhancement that snapshots `ATI` doesn't have to
  /// migrate the trip-history schema again.
  final String? adapterFirmware;

  /// Per-sample GPS cadence diagnostics captured under phone-sleep
  /// conditions (#1458 phase 2). Records the wall-clock timestamp and
  /// app-lifecycle state at every position fix, plus a monotonic index
  /// — lets a future diagnostics sheet (or a power user inspecting
  /// the persisted entry) reconstruct exactly when the OS throttled or
  /// paused the GPS stream during an unpinned recording. Empty for
  /// trips recorded before #1458 phase 2 landed and for trips whose
  /// `Feature.gpsTripPath` flag was off at recording start.
  final List<GpsSampleDiagnostic> gpsSampleDiagnostics;

  const TripHistoryEntry({
    required this.id,
    required this.vehicleId,
    required this.summary,
    this.automatic = false,
    this.samples = const [],
    this.adapterMac,
    this.adapterName,
    this.adapterFirmware,
    this.gpsSampleDiagnostics = const [],
  });

  /// Returns a copy with the given fields replaced (#1858). The
  /// retroactive η_v recompute uses it to swap in a rescaled [summary]
  /// while leaving the id / vehicle / samples / adapter identity
  /// untouched.
  TripHistoryEntry copyWith({TripSummary? summary}) => TripHistoryEntry(
        id: id,
        vehicleId: vehicleId,
        summary: summary ?? this.summary,
        automatic: automatic,
        samples: samples,
        adapterMac: adapterMac,
        adapterName: adapterName,
        adapterFirmware: adapterFirmware,
        gpsSampleDiagnostics: gpsSampleDiagnostics,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': _summaryToJson(summary),
        if (automatic) 'automatic': true,
        if (samples.isNotEmpty)
          'samples': samples.map(sampleToJson).toList(growable: false),
        // #1312 — adapter identity. Compact keys so the per-trip JSON
        // payload doesn't balloon (most trips carry one MAC + one
        // name; firmware stays null until the connect path captures
        // it). Each key is omitted when null so legacy entries
        // round-trip unchanged.
        if (adapterMac != null) 'adapterMac': adapterMac,
        if (adapterName != null) 'adapterName': adapterName,
        if (adapterFirmware != null) 'adapterFirmware': adapterFirmware,
        // #1458 phase 2 — GPS cadence diagnostics. Compact key 'gpsd'
        // keeps the per-trip JSON tight; emitted only when at least one
        // diagnostic was recorded so legacy trips and flag-off trips
        // round-trip unchanged.
        if (gpsSampleDiagnostics.isNotEmpty)
          'gpsd': gpsSampleDiagnostics
              .map((d) => d.toJson())
              .toList(growable: false),
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
                    (e) => sampleFromJson((e as Map).cast<String, dynamic>()))
                .toList(growable: false) ??
            const [],
        // #1312 — adapter identity. Reads as `String?` so legacy
        // entries written before this field landed deserialise with
        // null rather than throwing (mirrors the schema-drift lesson
        // from #1301).
        adapterMac: json['adapterMac'] as String?,
        adapterName: json['adapterName'] as String?,
        adapterFirmware: json['adapterFirmware'] as String?,
        // #1458 phase 2 — GPS cadence diagnostics. Missing key →
        // empty list so trips recorded before this PR (and flag-off
        // trips that never recorded a diagnostic) deserialise cleanly.
        gpsSampleDiagnostics: (json['gpsd'] as List?)
                ?.map((e) => GpsSampleDiagnostic.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
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
      // #1262 phase 2: cold-start surcharge bit. Compact key 'cs'
      // because every trip carries this and we'd rather not pay six
      // bytes per record. Legacy trips without the key default false.
      'cs': s.coldStartSurcharge,
      // #1263 phase 2: seconds spent below the optimal gear (gear-
      // inference coaching metric). Compact key 'sblog' (Seconds
      // Below Low-Optimal Gear). Omitted when null — most trips on
      // pre-#1263 builds, EVs, and combustion trips with insufficient
      // gear-inference data carry no value, so parsimony saves bytes.
      if (s.secondsBelowOptimalGear != null)
        'sblog': s.secondsBelowOptimalGear,
      // #1858: η_v recompute provenance. Compact key 'veUsed'. Omitted
      // when null — legacy trips and non-recalculable trips (any PID 5E
      // / MAF fuel) carry no value, so parsimony saves bytes.
      if (s.volumetricEfficiencyUsed != null)
        'veUsed': s.volumetricEfficiencyUsed,
      // #2025 — trajet kind. Omitted when gpsPlusObd2 (the historical
      // default) so legacy trips round-trip with zero bytes added.
      if (s.kind != TripKind.gpsPlusObd2) 'kind': s.kind.wireName,
      // #2029: per-event harsh-brake / harsh-accel detail with
      // timestamp + magnitude + speed. Compact key 'he'. Omitted when
      // empty so legacy trips and event-free trips round-trip with
      // zero bytes added.
      if (s.harshEvents.isNotEmpty)
        'he': s.harshEvents.map((e) => e.toJson()).toList(growable: false),
      // #2444: synthetic reconciliation trajet flag. Compact key 'virt'.
      // Omitted when false (every real trip) so legacy trips round-trip
      // with zero bytes added.
      if (s.isVirtual) 'virt': true,
      // #2760: IMU-detected aggregate event counts for dongle-less
      // (GPS+IMU) trips. THREE scalars only — never the raw ~50 Hz sample
      // stream (the aggregate-only / disk-efficient constraint). Compact
      // keys 'iha' / 'ihb' / 'sc'; each omitted when 0 so OBD2 trips and
      // every legacy trip round-trip with zero bytes added.
      if (s.imuHardAccelCount != 0) 'iha': s.imuHardAccelCount,
      if (s.imuHardBrakeCount != 0) 'ihb': s.imuHardBrakeCount,
      if (s.sharpCornerCount != 0) 'sc': s.sharpCornerCount,
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
      // #1263 phase 2: gear-inference coaching metric. Legacy trips
      // (and EV / no-inference trips) carry no key → null.
      secondsBelowOptimalGear: (j['sblog'] as num?)?.toDouble(),
      // #1858: η_v recompute provenance. Legacy trips and trips whose
      // fuel was not 100% speed-density carry no key → null, which
      // correctly reads as "not recalculable".
      volumetricEfficiencyUsed: (j['veUsed'] as num?)?.toDouble(),
      // #2025: trajet kind. Missing key → gpsPlusObd2 because every
      // recording before this field landed required an OBD2 connection.
      kind: TripKind.fromWireName(j['kind'] as String?),
      // #2029: per-event harsh-brake / harsh-accel detail. Missing
      // key → empty list so legacy trips fall back to the bare
      // [harshBrakes] / [harshAccelerations] integer counters.
      harshEvents: (j['he'] as List?)
              ?.map((e) =>
                  HarshEvent.fromJson((e as Map).cast<String, dynamic>()))
              .toList(growable: false) ??
          const [],
      // #2444: synthetic reconciliation trajet flag. Missing key →
      // false so every real trip and every legacy trip deserialises
      // as a normal, fully-counted trajet.
      isVirtual: (j['virt'] as bool?) ?? false,
      // #2760: IMU aggregate event counts. Missing key → 0 for OBD2 trips
      // and every legacy trip recorded before IMU fusion landed.
      imuHardAccelCount: (j['iha'] as num?)?.toInt() ?? 0,
      imuHardBrakeCount: (j['ihb'] as num?)?.toInt() ?? 0,
      sharpCornerCount: (j['sc'] as num?)?.toInt() ?? 0,
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
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'TripHistoryRepository.save'}));
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
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'TripHistoryRepository.save onSavedHook'}));
      }
    }
  }

  /// Deserialise the row stored under [key], or null when absent or
  /// corrupt (a single bad write is logged + skipped, never thrown).
  TripHistoryEntry? _decode(Object key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      return TripHistoryEntry.fromJson(json);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'TripHistoryRepository._decode: skipping $key'}));
      return null;
    }
  }

  /// Return every persisted trip, sorted newest-first. Corrupt
  /// payloads are silently skipped so one bad write doesn't hide the
  /// whole list.
  List<TripHistoryEntry> loadAll() {
    final result = <TripHistoryEntry>[];
    for (final key in _box.keys) {
      final entry = _decode(key);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax); // newest first
    });
    return result;
  }

  /// O(1) lookup of one persisted trip by [id] (#2304) — the box is keyed
  /// by `entry.id`, so this avoids the deserialise-everything + sort that
  /// `loadAll().firstWhere` paid just to fetch one row on trip stop.
  TripHistoryEntry? loadById(String id) => _decode(id);

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Wipe every persisted trip (#2571). Used by the full-backup RESTORE
  /// flow in [BackupImportMode.replace] before the backup's trips are
  /// written back. A no-op-equivalent when the box is already empty.
  Future<void> clearAll() async {
    await _box.clear();
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
