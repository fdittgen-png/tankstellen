// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';

// #3132 — import obd2's PUBLIC barrel (the active-trip WAL types + distance
// source are generic, used by both pipelines), not its internals.
import '../../obd2/api.dart';
import '../domain/trip_sample.dart';
import '../domain/trip_summary.dart';

/// #3248 — write-ahead log for GPS-only recordings.
///
/// The OBD2 pipeline persists an [ActiveTripSnapshot] so process death mid-trip
/// is recoverable (#1303), but the dongle-less [GpsOnlyRecordingPipeline]
/// (#2025) held everything in memory — an OS kill (backgrounded, no FGS) lost
/// the WHOLE trip with no forensic trace. This drives the SAME generic
/// active-trip box the OBD2 path + launch recovery already speak, so a killed
/// GPS-only trip is recovered identically.
///
/// Self-contained (its own debounce + Hive box resolution) so it adds no lines
/// to the line-capped pipeline beyond the three thin seed/flush/clear calls,
/// and never throws — a WAL is best-effort and must not derail recording.
class GpsOnlyTripWal {
  GpsOnlyTripWal({ActiveTripRepository? repoOverride})
      : _repoOverride = repoOverride;

  final ActiveTripRepository? _repoOverride;

  /// Debounce so a 1 Hz fix stream costs one Hive write per window, not per
  /// fix — mirrors the OBD2 path's 5 s / 30-sample gate.
  static const Duration _flushInterval = Duration(seconds: 5);
  static const int _flushEveryNSamples = 10;

  String? _id;
  DateTime? _startedAt;
  bool _automatic = false;
  String? _vehicleId;
  DateTime? _lastFlushAt;
  int _sinceFlush = 0;

  ActiveTripRepository? _repo() {
    if (_repoOverride != null) return _repoOverride;
    if (!Hive.isBoxOpen(ActiveTripRepository.boxName)) return null;
    try {
      return ActiveTripRepository(
          box: Hive.box<String>(ActiveTripRepository.boxName));
    } on Object {
      return null;
    }
  }

  /// Seed the initial (0-distance) snapshot so recovery has something on disk
  /// even if the OS kills us before the first sample lands.
  void seed({
    required DateTime startedAt,
    required bool automatic,
    required String? vehicleId,
  }) {
    _id = startedAt.toIso8601String();
    _startedAt = startedAt;
    _automatic = automatic;
    _vehicleId = vehicleId;
    _lastFlushAt = null;
    _sinceFlush = 0;
    _write(const [], _zeroSummary, force: true);
  }

  /// Debounced flush — call after each appended sample.
  void onSample(List<TripSample> samples, TripSummary summary) {
    _sinceFlush++;
    final now = DateTime.now();
    final due = _lastFlushAt == null ||
        now.difference(_lastFlushAt!) >= _flushInterval ||
        _sinceFlush >= _flushEveryNSamples;
    if (due) _write(samples, summary, force: true);
  }

  /// Force a flush now (app backgrounded — OS may kill us next).
  void flushNow(List<TripSample> samples, TripSummary summary) =>
      _write(samples, summary, force: true);

  /// The trip is finished (saved to history) — drop the WAL so launch recovery
  /// never resurrects it.
  void clear() {
    _id = null;
    unawaited(_repo()?.clearSnapshot());
  }

  void _write(List<TripSample> samples, TripSummary summary,
      {required bool force}) {
    final id = _id;
    final startedAt = _startedAt;
    if (id == null || startedAt == null) return;
    final repo = _repo();
    if (repo == null) return;
    _lastFlushAt = DateTime.now();
    _sinceFlush = 0;
    unawaited(repo.saveSnapshot(ActiveTripSnapshot(
      id: id,
      vehicleId: _vehicleId,
      vin: null,
      automatic: _automatic,
      phase: 'recording',
      summary: summary,
      samples: samples,
      odometerStartKm: null,
      odometerLatestKm: null,
      startedAt: startedAt,
      lastFlushedAt: _lastFlushAt!,
    )));
  }

  static const TripSummary _zeroSummary = TripSummary(
    distanceKm: 0,
    maxRpm: 0,
    highRpmSeconds: 0,
    idleSeconds: 0,
    harshBrakes: 0,
    harshAccelerations: 0,
    distanceSource: kDistanceSourceGps,
  );
}
