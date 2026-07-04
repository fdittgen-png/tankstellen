// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/entities/gps_sample_diagnostic.dart';
import '../domain/entities/recording_lifecycle_mark.dart';
import '../domain/trip_recorder.dart';
import '../../obd2/api.dart';
import 'trip_dedup.dart';
import 'trip_sample_codec.dart';
import 'trip_summary_codec.dart';
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

  /// Foreground↔background transitions observed during the recording,
  /// windowed to the trip (#3465). A tiny list (one entry per transition,
  /// led by a clamped trip-start anchor — see
  /// `RecordingLifecycleMarksRecorder.marksForWindow`) that lets the
  /// post-hoc GPS coverage report attribute a track gap to OS background
  /// throttling on a no-FGS build. Empty for legacy trips recorded before
  /// this field landed.
  final List<RecordingLifecycleMark> lifecycleMarks;

  /// OBD2 communication-health diagnostic snapshotted at trip finish
  /// (#2912, Epic #2904). The dev-only trip-detail comm-health card was
  /// **always empty** because it read the process-wide in-memory
  /// `Obd2CommDiagnostics.instance` singleton — wiped on restart and never
  /// tied to a trip — instead of the viewed trip's own diagnostic. This
  /// field persists the per-trip snapshot (connection attempts + the #2905
  /// reconnect timeline / session-state transitions / fallback markers,
  /// captured even when the adapter never connected) so the card can render
  /// THIS trip's health after a restart.
  ///
  /// Null for GPS-only trips that never touched OBD2, for production builds
  /// (the collector is disarmed unless `Feature.debugMode` is on), and for
  /// every legacy trip recorded before this field landed — in all of which
  /// the card keeps self-hiding. Round-trips via the existing JSON
  /// persistence under the compact key `'obd2d'`; the nested freezed model
  /// carries its own `toJson`/`fromJson` (heeding the #2776 round-trip
  /// lesson — it is a real serialised field, not `@JsonKey`-excluded).
  final Obd2SessionDiagnostic? obd2Diagnostic;

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
    this.lifecycleMarks = const [],
    this.obd2Diagnostic,
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
        lifecycleMarks: lifecycleMarks,
        obd2Diagnostic: obd2Diagnostic,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'summary': tripSummaryToJson(summary),
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
        // #3465 — recording lifecycle marks. Compact key 'lcm', emitted
        // only when at least one mark was captured, so legacy trips
        // round-trip unchanged (the mq/ep additive-optional precedent).
        if (lifecycleMarks.isNotEmpty)
          'lcm':
              lifecycleMarks.map((m) => m.toJson()).toList(growable: false),
        // #2912 — per-trip OBD2 comm-health diagnostic. Compact key 'obd2d'.
        // Emitted only when a diagnostic was captured (debug-mode trips that
        // touched OBD2), so production / GPS-only / legacy trips round-trip
        // with zero bytes added. The nested freezed model serialises itself
        // via its own short-keyed toJson, so the persisted snapshot reloads
        // intact (NOT @JsonKey-dropped — #2776 lesson).
        if (obd2Diagnostic != null) 'obd2d': obd2Diagnostic!.toJson(),
      };

  static TripHistoryEntry fromJson(Map<String, dynamic> json) =>
      TripHistoryEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        summary: tripSummaryFromJson(
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
        // #3465 — recording lifecycle marks. Missing key → empty list so
        // legacy trips deserialise cleanly (and the coverage report reads
        // "no marks" as its honest unknown-attribution input).
        lifecycleMarks: (json['lcm'] as List?)
                ?.map((e) => RecordingLifecycleMark.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
        // #2912 — per-trip OBD2 comm-health diagnostic. Missing key → null
        // so legacy trips, GPS-only trips and production (gate-off) trips
        // deserialise cleanly and the card keeps self-hiding for them.
        obd2Diagnostic: json['obd2d'] == null
            ? null
            : Obd2SessionDiagnostic.fromJson(
                (json['obd2d'] as Map).cast<String, dynamic>(),
              ),
      );
}

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

  /// Persist [entry]. Drops the oldest trip when the box reaches [cap].
  /// Errors are logged but swallowed. #2833 — a 0-sample ghost whose
  /// sampled twin already exists is a no-op; a sampled twin deletes any
  /// pre-existing 0-sample ghost (see [guardGhostDoubleSave]).
  Future<void> save(TripHistoryEntry entry) async {
    try {
      // A guard hiccup must never block the save — fall through to a write.
      final skip = await guardGhostDoubleSave(
        entry: entry,
        existing: loadAll(dedupe: false),
        deleteById: _box.delete,
      );
      if (skip) return;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'TripHistoryRepository.save ghost-guard'}));
    }
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

  /// Return every persisted trip, sorted newest-first. Corrupt payloads
  /// are silently skipped. #2833 — by default ghost 0-sample duplicates
  /// are removed so the list, the aggregates (`loadAll().length`) and the
  /// re-export see the de-duped truth; `dedupe: false` is the raw set.
  List<TripHistoryEntry> loadAll({bool dedupe = true}) {
    final result = <TripHistoryEntry>[];
    for (final key in _box.keys) {
      final entry = _decode(key as Object);
      if (entry != null) result.add(entry);
    }
    result.sort((a, b) {
      final ax = a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bx = b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bx.compareTo(ax); // newest first
    });
    return dedupe ? dedupeGhostTrips(result) : result;
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
