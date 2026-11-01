// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';
import '../protocol/diagnostics/dtc_decoder.dart';
import 'obd2_diagnostic_recordings.dart';

/// #4548 (Epic #4547) — the raw per-response trace of the opt-in full
/// diagnostic recording.
///
/// One NDJSON file per recorded trip under
/// [Obd2DiagnosticRecordings.directory]: a `header` line, then one
/// `cmd` line per adapter command — `{"k":"cmd","t":1761900000000,
/// "c":"010C","r":"41 0C 1A F8","ms":42}` (`t` = epoch ms) (an `"e"` error string in
/// place of `"r"` when the command threw) — interleaved with `mark`
/// lines for phase boundaries and decoded trouble codes. Every reply is
/// kept at its own millisecond timestamp: nothing is thinned, so a
/// sub-second event (a 2→1 downshift) survives intact.
///
/// The tee point is the ONE raw-send funnel (`Obd2ServiceSession.send`),
/// so every command of the session lands here — the scheduler's polls,
/// the `ATRV` voltage watch, the odometer and OEM reads, the health
/// snapshot — without any caller knowing about the trace.
///
/// Writes go through an [IOSink], which buffers and writes
/// asynchronously: [observe] costs one `jsonEncode` of a small map on
/// the UI isolate and never blocks on file I/O. The file stops growing
/// at [maxBytes] with a final `truncated` mark.
class Obd2DiagnosticTrace {
  Obd2DiagnosticTrace._(this._sink, this.file, this._now);

  /// The trace of the trip being recorded, or null when no full
  /// diagnostic recording is running. Single-isolate (the OBD2 stack
  /// lives on the UI isolate), so a plain static is enough — the same
  /// shape as `Obd2DebugSessionRecorder`.
  static Obd2DiagnosticTrace? get current => _current;
  static Obd2DiagnosticTrace? _current;

  /// Stop growing a trace past this size (≈14 h of driving at the
  /// measured ~1 KB/s).
  static const int maxBytes = 50 * 1024 * 1024;

  /// Trace format version, stamped on the header line.
  static const int schemaVersion = 1;

  final IOSink _sink;
  final DateTime Function() _now;

  /// The file this trace writes.
  final File file;

  int _bytes = 0;
  bool _closed = false;
  bool _truncated = false;
  final Map<String, List<String>> _lastDtcs = {};

  /// Open a new trace file and make it [current]. [header] is written as
  /// the first line (vehicle, adapter, start reason). Returns null — and
  /// logs — when the file cannot be created: a diagnostic trace must
  /// never stop the recording it observes.
  static Future<Obd2DiagnosticTrace?> begin({
    required Map<String, Object?> header,
    Directory? directory,
    DateTime Function()? now,
  }) async {
    await end();
    final clock = now ?? DateTime.now;
    try {
      final dir = directory ?? await Obd2DiagnosticRecordings.directory();
      await Obd2DiagnosticRecordings.prune(dir);
      final started = clock();
      final file = File('${dir.path}/${Obd2DiagnosticRecordings.fileNameFor(started)}');
      final trace =
          Obd2DiagnosticTrace._(file.openWrite(mode: FileMode.append), file, clock);
      trace._write({
        'k': 'header',
        'schema': schemaVersion,
        't': started.millisecondsSinceEpoch,
        'startedAt': started.toIso8601String(),
        ...header,
      });
      _current = trace;
      return trace;
    } catch (e, st) {
      log.error(e, st,
          layer: ErrorLayer.storage,
          context: const {'where': 'Obd2DiagnosticTrace.begin'});
      return null;
    }
  }

  /// Flush and close the [current] trace. Idempotent.
  static Future<void> end() async {
    final trace = _current;
    _current = null;
    await trace?._close();
  }

  /// Record the outcome of one adapter [command]: awaits [reply], writes
  /// a `cmd` line with the reply (or the error) and the round-trip time,
  /// and hands the original result / error back unchanged.
  Future<String> observe(String command, Future<String> reply) {
    final sentAt = _now();
    return reply.then((r) {
      _recordCommand(command, sentAt, reply: r);
      return r;
    }, onError: (Object e, StackTrace st) {
      _recordCommand(command, sentAt, error: e);
      Error.throwWithStackTrace(e, st);
    });
  }

  /// A phase boundary or annotation (`snapshot-start`, `vin`, …).
  void mark(String phase, [Map<String, Object?> data = const {}]) => _write({
        'k': 'mark',
        't': _now().millisecondsSinceEpoch,
        'p': phase,
        ...data,
      });

  void _recordCommand(String command, DateTime sentAt,
      {String? reply, Object? error}) {
    final done = _now();
    _write({
      'k': 'cmd',
      't': sentAt.millisecondsSinceEpoch,
      'c': command.trim(),
      if (reply != null) 'r': _clean(reply),
      if (error != null) 'e': error.runtimeType.toString(),
      'ms': done.difference(sentAt).inMilliseconds,
    });
    if (reply != null) _noteDtcs(command.trim(), reply);
  }

  /// Decoded trouble codes: a `dtc` mark whenever the set reported by
  /// [command] changes (also the first time it answers), so a code that
  /// appears mid-trip is stamped at the moment the ECU reported it.
  void _noteDtcs(String command, String reply) {
    final c = command.toUpperCase();
    if (c != '03' && c != '07' && c != '0A' && c != '020200') return;
    if (!isCompleteDtcReply(c, reply)) return;
    final codes = decodeDtcReply(c, reply);
    final previous = _lastDtcs[c];
    if (previous != null && listEquals(previous, codes)) return;
    _lastDtcs[c] = codes;
    mark('dtc', {'c': c, 'codes': codes});
  }

  /// One line per reply: the prompt dropped, ECU lines joined by ` | `.
  static String _clean(String reply) => reply
      .replaceAll('>', '')
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .join(' | ');

  void _write(Map<String, Object?> line) {
    if (_closed || _truncated) return;
    final text = jsonEncode(line);
    _bytes += text.length + 1;
    if (_bytes > maxBytes) {
      _truncated = true;
      _sink.writeln(jsonEncode({
        'k': 'mark',
        't': _now().millisecondsSinceEpoch,
        'p': 'truncated',
        'maxBytes': maxBytes,
      }));
      return;
    }
    _sink.writeln(text);
  }

  Future<void> _close() async {
    if (_closed) return;
    mark('end');
    _closed = true;
    try {
      await _sink.flush();
      await _sink.close();
    } catch (e, st) {
      log.error(e, st,
          layer: ErrorLayer.storage,
          context: const {'where': 'Obd2DiagnosticTrace.close'});
    }
  }

  /// Test reset — drops [current] without closing it.
  @visibleForTesting
  static void debugReset() => _current = null;
}
