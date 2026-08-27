// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

// #3739 — the canonical codec functions come through the trips
// feature's public api.dart barrel (the feature-boundary contract).
import '../../trips/api.dart';
import '../../../core/logging/error_logger.dart';

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

  /// Whether the recording that produced this paused snapshot was
  /// kicked off by the hands-free auto-record path (#1004 phase 4-WAL).
  ///
  /// Carried so the [PausedTripRecoveryService] knows whether to bump
  /// the launcher-icon badge when a stale entry is finalised on next
  /// app launch — manual trips never counted toward the unseen-badge
  /// counter and must not retroactively start counting just because
  /// the app was killed before the disconnect-save timer fired.
  ///
  /// Defaults to `false` so legacy serialised rows (written before
  /// this field landed) round-trip cleanly via the `?? false` read in
  /// [fromJson].
  final bool automatic;

  const PausedTripEntry({
    required this.id,
    required this.vehicleId,
    required this.vin,
    required this.summary,
    required this.odometerStartKm,
    required this.odometerLatestKm,
    required this.pausedAt,
    this.automatic = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (vin != null) 'vin': vin,
        'summary': tripSummaryToJson(summary),
        if (odometerStartKm != null) 'odometerStartKm': odometerStartKm,
        if (odometerLatestKm != null) 'odometerLatestKm': odometerLatestKm,
        'pausedAt': pausedAt.toIso8601String(),
        if (automatic) 'automatic': true,
      };

  static PausedTripEntry fromJson(Map<String, dynamic> json) =>
      PausedTripEntry(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String?,
        vin: json['vin'] as String?,
        summary: tripSummaryFromJson(
          (json['summary'] as Map).cast<String, dynamic>(),
        ),
        odometerStartKm: (json['odometerStartKm'] as num?)?.toDouble(),
        odometerLatestKm: (json['odometerLatestKm'] as num?)?.toDouble(),
        pausedAt: DateTime.parse(json['pausedAt'] as String),
        automatic: (json['automatic'] as bool?) ?? false,
      );
}

// #3739 — the former private summary codec lived here and was the most
// drifted of the three: 16 canonical keys missing, including
// `distanceSource` (so every paused→finalised trip fell back to the
// suspicious `'virtual'` default flagged in earlier field sessions) and
// `kind`, `cs`, `sblog` plus all the #3576/#2760/#3589 fields. The entry
// now delegates to the canonical `trip_summary_codec.dart` (via the
// consumption api.dart barrel) — ONE codec for history, WAL and paused.

/// Hive-backed store for paused OBD2 trips (#797 phase 1).
///
/// Mirrors the very small API surface the
/// [TripRecordingController] needs — save, load, list, delete. Like
/// [TripHistoryRepository], errors are logged but swallowed so a
/// single corrupt write doesn't take down the pause/resume flow.
class PausedTripRepository {
  final Box<String> _box;

  PausedTripRepository({required this._box});

  /// Hive box name used by the production wiring. Kept in sync with
  /// [HiveBoxes.obd2PausedTrips].
  static const String boxName = 'obd2_paused_trips';

  /// Persist [entry]. Overwrites any previous payload at the same id
  /// (ISO start timestamp) so repeated drops during a single session
  /// keep converging on the most recent partial.
  Future<void> save(PausedTripEntry entry) async {
    try {
      await _box.put(entry.id, jsonEncode(entry.toJson()));
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'PausedTripRepository.save'}));
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'PausedTripRepository.load'}));
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'PausedTripRepository.delete'}));
    }
  }
}
