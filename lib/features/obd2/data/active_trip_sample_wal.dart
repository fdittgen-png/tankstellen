// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../trips/api.dart'
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
///
/// #4357 — swallowing is not the same as hiding. An [IOSink] reports a
/// write failure on its `done` future and NOWHERE else: `writeln` is
/// fire-and-forget by construction, so a disk that fills up, an iOS
/// file-protection refusal before first unlock, or a deleted container
/// used to leave `isWritable` true and `appendedCount` climbing while
/// nothing reached the file. Every fault now lands in [lastFault] and
/// on the [faults] stream, and [isDurable] — not [isWritable] — is the
/// predicate that may be read as "what was appended is on disk".
class ActiveTripSampleWal {
  ActiveTripSampleWal({this._supportDirOverride});

  /// Process-wide instance for the production wiring: the recording
  /// provider (writer), the GPS-only WAL (writer) and the launch
  /// recovery phase (reader) must all see the same sink/file. Tests
  /// construct their own with [supportDirOverride].
  static final ActiveTripSampleWal instance = ActiveTripSampleWal();

  /// Test seam — production resolves the platform app-support dir.
  final Directory Function()? _supportDirOverride;

  static const String fileName = 'active_trip_samples.ndjson';

  /// #4357 — upper bound on a flush/close. An [IOSink] whose underlying
  /// open failed never completes its flush, and the stop path awaits
  /// this; without the bound a failed WAL hangs the save.
  static const Duration _flushTimeout = Duration(seconds: 5);

  IOSink? _sink;
  File? _file;
  int _appended = 0;
  ActiveTripWalFault? _lastFault;

  final StreamController<ActiveTripWalFault> _faults =
      StreamController<ActiveTripWalFault>.broadcast();

  /// True while the sink is open — the repository strips samples from
  /// the Hive row ONLY then; a failed open degrades to the legacy fat
  /// row so no sample is ever lost to a broken WAL.
  ///
  /// A ROUTING answer ("is there a sink to append to"), not a
  /// durability claim — see [isDurable].
  bool get isWritable => _sink != null;

  /// #4357 — the honest durability predicate: a sink is open AND no
  /// write has failed since it was opened.
  ///
  /// The seam S6's persistence observation consumes. It is deliberately
  /// separate from [isWritable]: flipping [isWritable] on a mid-trip
  /// fault would make the stop path fall back to an in-memory list that
  /// only starts at the fault, discarding the lines that DID reach the
  /// file. Routing [isDurable] into the snapshot-strip and read-back
  /// decisions is S6's work; what this slice owes is that the failure
  /// is observable and that nothing here calls a failed write durable.
  bool get isDurable => _sink != null && _lastFault == null;

  /// The last write/close/open fault, or null while the WAL is healthy.
  /// Cleared by a successful [openFresh] / [openAppend].
  ActiveTripWalFault? get lastFault => _lastFault;

  /// Every fault as it happens. Broadcast, so a late observer sees
  /// nothing — read [lastFault] for the state it missed.
  Stream<ActiveTripWalFault> get faults => _faults.stream;

  /// Samples appended since [openFresh] (telemetry / tests).
  ///
  /// Counts lines a HEALTHY sink accepted. Once a fault is recorded,
  /// [append] stops writing and this stops climbing — the number no
  /// longer drifts away from what is on disk.
  int get appendedCount => _appended;

  void _recordFault(ActiveTripWalFaultKind kind, String where, Object error,
      StackTrace stack) {
    final fault = ActiveTripWalFault(kind: kind, where: where, error: error);
    _lastFault = fault;
    log.error(error, stack,
        layer: ErrorLayer.storage, context: {'where': where});
    if (!_faults.isClosed) _faults.add(fault);
  }

  /// Watch [sink]'s `done` future — the ONLY channel an [IOSink] has for
  /// a write failure. Never awaited: it completes when the sink closes.
  void _watchSinkDone(IOSink sink, String where) {
    unawaited(sink.done.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) =>
          _recordFault(ActiveTripWalFaultKind.write, where, e, st),
    ));
  }

  Future<File?> _resolveFile() async {
    try {
      final dir = _supportDirOverride?.call() ??
          await getApplicationSupportDirectory();
      return File('${dir.path}/$fileName');
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'ActiveTripSampleWal.resolveFile'});
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
      final sink = file.openWrite(mode: FileMode.writeOnly);
      _sink = sink;
      _appended = 0;
      _lastFault = null;
      _watchSinkDone(sink, 'ActiveTripSampleWal.openFresh sink');
    } catch (e, st) {
      _sink = null;
      _recordFault(ActiveTripWalFaultKind.open, 'ActiveTripSampleWal.openFresh',
          e, st);
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
      final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
      _sink = sink;
      _lastFault = null;
      _watchSinkDone(sink, 'ActiveTripSampleWal.openAppend sink');
    } catch (e, st) {
      _sink = null;
      _recordFault(ActiveTripWalFaultKind.open,
          'ActiveTripSampleWal.openAppend', e, st);
    }
  }

  /// Append one accepted sample — a single JSON line, O(1) memory.
  ///
  /// No explicit flush: a file IOSink drains its queue to disk
  /// continuously (flush() would only AWAIT that), and an interleaved
  /// flush actually THROWS on concurrent writes ("StreamSink is bound
  /// to a stream"). A hard kill loses only the unprocessed tail of the
  /// event queue — at 1 Hz effectively the last line at most.
  ///
  /// #4357 — "queued" is therefore not "written". The sink's `done`
  /// future carries the verdict; [_watchSinkDone] turns it into a
  /// [ActiveTripWalFault] and [isDurable] goes false. A `writeln` that
  /// throws outright (the sink already torn down) is recorded here and
  /// does NOT increment [appendedCount].
  void append(TripSample sample) {
    final sink = _sink;
    if (sink == null) return;
    // A sink that has already failed accepts `writeln` without a word
    // and drops it — which is how [appendedCount] used to keep
    // climbing past a dead WAL. Stop at the first fault: the count then
    // means what it says, and the caller sees [isDurable] false.
    if (_lastFault != null) return;
    try {
      sink.writeln(jsonEncode(sampleToJson(sample)));
      _appended++;
    } catch (e, st) {
      _recordFault(
          ActiveTripWalFaultKind.write, 'ActiveTripSampleWal.append', e, st);
    }
  }

  /// Read every parseable sample line — used by launch recovery after a
  /// process death. Corrupt lines (the possible torn final write) are
  /// skipped. Heavy parsing runs in a background isolate; only the
  /// final sample list crosses the boundary, once.
  Future<List<TripSample>> readAll() async {
    try {
      // A flush on a sink whose underlying open failed never completes
      // — bound it, or the read of what IS on disk hangs forever.
      if (_lastFault == null) {
        await _sink?.flush().timeout(_flushTimeout);
      }
    } catch (e, st) {
      // Best-effort pre-read flush: a broken sink must not block
      // reading what is already on disk.
      log.warn('ActiveTripSampleWal: pre-read flush failed',
          error: e, stack: st, layer: ErrorLayer.storage);
    }
    try {
      final file = _file ?? await _resolveFile();
      if (file == null || !file.existsSync()) return const [];
      return await compute(parseActiveTripWalFile, file.path);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'ActiveTripSampleWal.readAll'});
      return const [];
    }
  }

  /// Close the sink (flushing) without deleting — used at pause /
  /// process-teardown points.
  ///
  /// The flush/close is where a queued write failure finally surfaces
  /// synchronously; it is recorded as a fault so a trip is never
  /// reported as fully persisted on a sink that could not drain.
  Future<void> close() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      // Same bound as [readAll]: a flush behind a failed open never
      // completes, and a WAL close that hangs stalls the stop path.
      if (_lastFault == null) await sink.flush().timeout(_flushTimeout);
      await sink.close().timeout(_flushTimeout);
    } catch (e, st) {
      _recordFault(
          ActiveTripWalFaultKind.close, 'ActiveTripSampleWal.close', e, st);
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
      log.error(e, st, layer: ErrorLayer.storage, context: const {'where': 'ActiveTripSampleWal.clear'});
    }
  }
}

/// Which stage of the WAL failed (#4357).
enum ActiveTripWalFaultKind {
  /// The file could not be resolved or the sink could not be opened —
  /// the WAL never started, and the caller degrades to the fat row.
  open,

  /// A line did not reach the file: the sink's `done` future completed
  /// with an error, or `writeln` threw on a torn-down sink.
  write,

  /// The flush/close at pause or teardown failed — whatever was still
  /// queued did not land.
  close,
}

/// One observed WAL failure (#4357) — the unit S6's persistence
/// observation consumes.
///
/// Carries no timestamp on purpose: this layer has no clock, and the
/// observer that renders a fault is the one that knows which clock to
/// stamp it with (`appClockProvider`).
@immutable
class ActiveTripWalFault {
  const ActiveTripWalFault({
    required this.kind,
    required this.where,
    required this.error,
  });

  /// Which stage failed.
  final ActiveTripWalFaultKind kind;

  /// The `where` tag already used in the error-log context, e.g.
  /// `ActiveTripSampleWal.append`.
  final String where;

  /// The underlying fault — a `FileSystemException` for a full disk or
  /// an iOS file-protection refusal, a `StateError` for a torn-down
  /// sink.
  final Object error;

  @override
  String toString() => 'ActiveTripWalFault(${kind.name}, $where, $error)';
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
      log.warn('ActiveTripSampleWal: skipping corrupt line',
          error: e, stack: st, layer: ErrorLayer.storage);
    }
  }
  return samples;
}
