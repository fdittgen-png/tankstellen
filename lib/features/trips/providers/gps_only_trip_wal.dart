// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';

// #3132 — import obd2's PUBLIC barrel (the active-trip WAL types + distance
// source are generic, used by both pipelines), not its internals.
import '../../obd2/api.dart';
import '../domain/trip_sample.dart';
import '../domain/trip_summary.dart';
import '../../../core/telemetry/process_death_context.dart';

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
  GpsOnlyTripWal({this._repoOverride});

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

  /// #3878 — samples captured since the last flush (appended to the WAL
  /// at the next write), and — ONLY when the WAL is not writable — the
  /// whole trip, so the legacy fat-row path still saves every sample.
  final List<TripSample> _pending = <TripSample>[];
  final List<TripSample> _fallbackAll = <TripSample>[];

  ActiveTripRepository? _repo() {
    if (_repoOverride != null) return _repoOverride;
    if (!Hive.isBoxOpen(ActiveTripRepository.boxName)) return null;
    try {
      return ActiveTripRepository(
          sampleWal: ActiveTripSampleWal.instance,
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
    // #3758 — fresh trip, fresh append-only sample WAL.
    _pending.clear();
    _fallbackAll.clear();
    unawaited(_repo()?.sampleWal?.openFresh());
    _write(_zeroSummary, force: true);
  }

  /// #3878 — true while the append-only WAL sink is open: the pipeline
  /// may then keep only its live window in memory.
  bool get walWritable => _repo()?.sampleWal?.isWritable ?? false;

  /// Debounced flush — call after each captured sample (#3878: the
  /// sample itself is queued here; the pipeline keeps no full list).
  void onSample(TripSample sample, TripSummary summary) {
    _pending.add(sample);
    if (!walWritable) _fallbackAll.add(sample);
    _sinceFlush++;
    final now = DateTime.now();
    final due = _lastFlushAt == null ||
        now.difference(_lastFlushAt!) >= _flushInterval ||
        _sinceFlush >= _flushEveryNSamples;
    if (due) _write(summary, force: true);
  }

  /// Force a flush now (app backgrounded — OS may kill us next).
  void flushNow(TripSummary summary) => _write(summary, force: true);

  /// #3878 — every sample of the trip for the stop path: flush the
  /// pending tail, then read the WAL back (one isolate hop); the
  /// in-memory fallback list when the WAL was never writable.
  Future<List<TripSample>> readAll() async {
    _write(_zeroSummary, force: true, metaOnly: true);
    final wal = _repo()?.sampleWal;
    if (wal == null || !wal.isWritable) return List.unmodifiable(_fallbackAll);
    final fromDisk = await wal.readAll();
    return fromDisk.length >= _fallbackAll.length ? fromDisk : _fallbackAll;
  }

  /// The trip is finished (saved to history) — drop the WAL so launch recovery
  /// never resurrects it.
  void clear() {
    _id = null;
    unawaited(_repo()?.clearSnapshot());
  }

  void _write(TripSummary summary,
      {required bool force, bool metaOnly = false}) {
    final id = _id;
    final startedAt = _startedAt;
    if (id == null || startedAt == null) return;
    final repo = _repo();
    if (repo == null) return;
    _lastFlushAt = DateTime.now();
    _sinceFlush = 0;
    // #3758/#3878 — the pending samples once each into the append WAL;
    // the snapshot row below is meta-only via the repo whenever the WAL
    // is writable, else it carries the whole trip (legacy fat row).
    final wal = repo.sampleWal;
    if (wal != null && wal.isWritable) {
      for (final s in _pending) {
        wal.append(s);
      }
    }
    _pending.clear();
    if (metaOnly) return;
    final samples =
        (wal != null && wal.isWritable) ? const <TripSample>[] : _fallbackAll;
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
      // #3796 — whose process wrote this WAL row.

      processInstanceId: ProcessDeathContext.instanceId,
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
