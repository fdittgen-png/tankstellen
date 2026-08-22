// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/error_logger.dart';
import '../../consumption/api.dart'
    show TripSample, sampleFromJson, sampleToJson;

/// #3758 — append-only sample WAL for the active trip.
///
/// The previous WAL re-serialized the ENTIRE growing sample list into
/// the Hive snapshot row every ~5 s; past ~33 min (2,000 samples at the
/// 1 Hz decimated cadence) each flush additionally spawned a `compute()`
/// isolate copying the whole list — 12 isolate spawns + full-list
/// serializations per minute, growing linearly. Field result: crashes
/// at ~40 min of recording and elevated background low-memory kills.
///
/// This WAL writes each accepted sample EXACTLY ONCE: one canonical-
/// codec (#3739) JSON line (~200 B) appended to a plain NDJSON file in
/// the app-support dir. Memory cost per flush is O(1); the Hive
/// snapshot row shrinks to meta-only (summary/phase/odometer). Crash
/// durability improves too: the old WAL lost everything since the last
/// 5 s flush, this loses at most the final partial line (tolerated by
/// the reader).
///
/// Never-throws contract: every method swallows and logs — losing WAL
/// lines must never take down the recording it exists to protect. The
/// contract is backed by fault-injection tests (#2349).
class ActiveTripSampleWal {
  ActiveTripSampleWal({Directory Function()? supportDirOverride})
      : _supportDirOverride = supportDirOverride;

  /// Process-wide instance for the production wiring: the recording
  /// provider (writer), the GPS-only WAL (writer) and the launch
  /// recovery phase (reader) must all see the same sink/file. Tests
  /// construct their own with [supportDirOverride].
  static final ActiveTripSampleWal instance = ActiveTripSampleWal();

  /// Test seam — production resolves the platform app-support dir.
  final Directory Function()? _supportDirOverride;

  static const String fileName = 'active_trip_samples.ndjson';

  IOSink? _sink;
  File? _file;
  int _appended = 0;

  /// True while the sink is open — the repository strips samples from
  /// the Hive row ONLY then; a failed open degrades to the legacy fat
  /// row so no sample is ever lost to a broken WAL.
  bool get isWritable => _sink != null;

  /// Samples appended since [openFresh] (telemetry / tests).
  int get appendedCount => _appended;

  Future<File?> _resolveFile() async {
    try {
      final dir = _supportDirOverride?.call() ??
          await getApplicationSupportDirectory();
      return File('${dir.path}/$fileName');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.resolveFile'}));
      return null;
    }
  }

  /// Start a FRESH WAL (truncates any stale file — the caller persists
  /// its meta row first, so a previous crash has already been recovered
  /// or discarded by the recovery services before a new trip starts).
  Future<void> openFresh() async {
    try {
      await close();
      final file = await _resolveFile();
      if (file == null) return;
      _file = file;
      _sink = file.openWrite(mode: FileMode.writeOnly);
      _appended = 0;
    } catch (e, st) {
      _sink = null;
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.openFresh'}));
    }
  }

  /// Re-attach to an EXISTING file in append mode (paused → resumed
  /// across a process restart).
  Future<void> openAppend() async {
    try {
      await close();
      final file = await _resolveFile();
      if (file == null) return;
      _file = file;
      _sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    } catch (e, st) {
      _sink = null;
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.openAppend'}));
    }
  }

  /// Append one accepted sample — a single JSON line, O(1) memory.
  ///
  /// No explicit flush: a file IOSink drains its queue to disk
  /// continuously (flush() would only AWAIT that), and an interleaved
  /// flush actually THROWS on concurrent writes ("StreamSink is bound
  /// to a stream"). A hard kill loses only the unprocessed tail of the
  /// event queue — at 1 Hz effectively the last line at most.
  void append(TripSample sample) {
    final sink = _sink;
    if (sink == null) return;
    try {
      sink.writeln(jsonEncode(sampleToJson(sample)));
      _appended++;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.append'}));
    }
  }

  /// Read every parseable sample line — used by launch recovery after a
  /// process death. Corrupt lines (the possible torn final write) are
  /// skipped. Heavy parsing runs in a background isolate; only the
  /// final sample list crosses the boundary, once.
  Future<List<TripSample>> readAll() async {
    try {
      await _sink?.flush();
    } catch (e, st) {
      // Best-effort pre-read flush: a broken sink must not block
      // reading what is already on disk.
      debugPrint('ActiveTripSampleWal: pre-read flush failed: $e\n$st');
    }
    try {
      final file = _file ?? await _resolveFile();
      if (file == null || !file.existsSync()) return const [];
      return await compute(parseActiveTripWalFile, file.path);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.readAll'}));
      return const [];
    }
  }

  /// Close the sink (flushing) without deleting — used at pause /
  /// process-teardown points.
  Future<void> close() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      await sink.flush();
      await sink.close();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.close'}));
    }
  }

  /// Trip finished/discarded: close and delete the file so launch
  /// recovery never resurrects it.
  Future<void> clear() async {
    await close();
    try {
      final file = _file ?? await _resolveFile();
      _file = null;
      if (file != null && file.existsSync()) await file.delete();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'ActiveTripSampleWal.clear'}));
    }
  }
}

/// Top-level for `compute`: parse the NDJSON WAL at [path] into samples,
/// skipping unparseable lines (torn final write after a hard kill).
List<TripSample> parseActiveTripWalFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return const [];
  final samples = <TripSample>[];
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    try {
      samples.add(
          sampleFromJson((jsonDecode(line) as Map).cast<String, dynamic>()));
    } catch (e, st) {
      // A torn/corrupt line (hard kill mid-write) is EXPECTED once per
      // crash; skipping it is the design — every other sample survives.
      debugPrint('ActiveTripSampleWal: skipping corrupt line: $e\n$st');
    }
  }
  return samples;
}
