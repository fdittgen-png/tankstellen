// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';
import '../../../trips/api.dart' show RecordingSessionJournal;

import 'package:flutter/foundation.dart';

import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';
import '../protocol/diagnostics/diagnostic_health_plan.dart';
import '../../domain/pid_scheduler.dart';
import '../diagnostics/obd2_diagnostic_trace.dart';

/// #4548 / #4549 / #4550 (Epic #4547) — the opt-in full diagnostic
/// recording of one trip, as an owned collaborator of
/// `TripRecordingController` (the #4032 rule: the state lives here, the
/// controller only calls in).
///
/// * [begin] / [end] open and close the trip's raw trace
///   ([Obd2DiagnosticTrace]); every adapter command of the session is
///   teed into it by the raw-send funnel.
/// * [subscribe] adds the continuous health plan
///   ([buildDiagnosticHealthPlan]) to the trip scheduler in the
///   expendable [PidTier.diagnosticSweep] tier. Replies need no parsing
///   here — the trace keeps them — so each callback only watches for
///   `NO DATA`: three in a row drop that command for the trip.
/// * [snapshot] runs the one-shot identity / ECU sequence at trip start
///   and stop; the CALLER provides the quiet window (scheduler paused).
class TripFullDiagnostics {
  TripFullDiagnostics({
    required this._header,
    this.noDataLimit = 3,
    this.commandTimeout = const Duration(seconds: 3),
    Future<Obd2DiagnosticTrace?> Function(Map<String, Object?> header)?
        beginTrace,
  }) : _beginTrace = beginTrace ??
            ((h) => Obd2DiagnosticTrace.begin(header: h));

  final Map<String, Object?> _header;
  final Future<Obd2DiagnosticTrace?> Function(Map<String, Object?>) _beginTrace;

  /// Consecutive `NO DATA` replies after which a health command is
  /// unsubscribed for the rest of the trip.
  final int noDataLimit;

  /// Per-command budget inside [snapshot].
  final Duration commandTimeout;

  Obd2DiagnosticTrace? _trace;
  final Map<String, int> _noData = {};
  final Set<String> _subscribed = {};

  /// The open trace, or null before [begin] / after [end] / when the file
  /// could not be created.
  Obd2DiagnosticTrace? get trace => _trace;

  /// The trace file, kept after [end] so tests can read it.
  @visibleForTesting
  File? get debugTraceFile => _lastFile;
  File? _lastFile;

  /// The health commands this collaborator subscribed (tests, trace).
  @visibleForTesting
  Set<String> get subscribedCommands => Set.unmodifiable(_subscribed);

  /// Open the trace. Never throws.
  Future<void> begin({RecordingSessionJournal? journal}) async {
    _trace = await _beginTrace(_header);
    _lastFile = _trace?.file;
    journal?.diagnosticRecordingFile = _lastFile?.uri.pathSegments.last;
  }

  /// Annotate the trace (identity reads, termination).
  void mark(String phase, [Map<String, Object?> data = const {}]) =>
      _trace?.mark(phase, data);

  /// Subscribe the health plan into [scheduler]. [advertised] is the
  /// car's supported-PID bitmap check (strict: false while unresolved,
  /// which limits the plan to the named health set). Idempotent across
  /// the engine-off → engine-on start path.
  void subscribe(PidScheduler scheduler, {bool Function(int pid)? advertised}) {
    final others = scheduler.subscribedCommands.difference(_subscribed);
    final plan = buildDiagnosticHealthPlan(
      alreadyPolled: others,
      advertised: advertised,
    );
    for (final entry in plan) {
      if (_noData[entry.command] case final n? when n >= noDataLimit) continue;
      _subscribed.add(entry.command);
      scheduler.subscribe(
        entry.command,
        ScheduledPid(
          hz: entry.hz,
          priority: PidPriority.low,
          tier: PidTier.diagnosticSweep,
        ),
        (reply) => _onReply(scheduler, entry.command, reply),
      );
    }
    _trace?.mark('health-plan', {
      'commands': [for (final e in plan) e.toString()],
    });
  }

  void _onReply(PidScheduler scheduler, String command, String reply) {
    final upper = reply.toUpperCase();
    final empty = upper.contains('NO DATA') ||
        upper.contains('NODATA') ||
        upper.trim() == '?' ||
        upper.contains('UNABLE TO CONNECT');
    if (!empty) {
      _noData[command] = 0;
      return;
    }
    final n = (_noData[command] ?? 0) + 1;
    _noData[command] = n;
    if (n < noDataLimit) return;
    scheduler.unsubscribe(command);
    _subscribed.remove(command);
    _trace?.mark('health-dropped', {'c': command, 'noData': n});
  }

  /// Run the one-shot snapshot for [phase] (`start` / `stop`) through
  /// [send] — the raw session send, so every reply lands in the trace.
  /// Then switch headers on (`ATH1`), repeat `0100` to record WHICH ECUs
  /// answer (engine, gearbox, …), and restore `ATH0` whenever `ATH1` was
  /// sent. Each command is bounded by [commandTimeout]; the whole
  /// sequence by [budget], and two failures in a row (a silent bus at an
  /// engine-off stop) end it early — a stop must never hang on a dead
  /// ECU. Never throws.
  Future<void> snapshot(
    String phase,
    Future<String> Function(String command) send, {
    Duration budget = const Duration(seconds: 8),
    DateTime Function() now = DateTime.now,
  }) async {
    if (_trace == null) return;
    _trace!.mark('snapshot-$phase');
    final deadline = now().add(budget);
    var failures = 0;
    bool exhausted() => failures >= 2 || !now().isBefore(deadline);
    for (final command in kDiagnosticSnapshotCommands) {
      if (exhausted()) break;
      failures = await _bounded(send, command) ? 0 : failures + 1;
    }
    if (!exhausted()) {
      try {
        for (final c in kDiagnosticEcuScanCommands) {
          await _bounded(send, c);
        }
      } finally {
        await _bounded(send, kDiagnosticHeadersOffCommand);
      }
    }
    _trace?.mark('snapshot-$phase-done', {'aborted': exhausted()});
  }

  /// Send [command] within [commandTimeout]; true when it answered.
  Future<bool> _bounded(
    Future<String> Function(String command) send,
    String command,
  ) async {
    try {
      await send(command).timeout(commandTimeout);
      return true;
    } catch (e, st) {
      // Expected on many cars (Mode 0A / 09 0A are optional) and on a
      // link that is going away at stop; the trace already carries the
      // error line. Warn-level, never the user error log.
      log.warn('TripFullDiagnostics: $command failed',
          error: e, stack: st, layer: ErrorLayer.other);
      return false;
    }
  }

  /// Full-diagnostic `ATRV` cadence (normal recording: 10 s).
  Duration get voltageInterval => DiagnosticHealthRates.batteryVoltageInterval;

  /// Close the trace, stamping how the trip ended. Idempotent.
  Future<void> end({String? reason}) async {
    _trace?.mark('termination', {'reason': reason});
    final trace = _trace;
    _trace = null;
    if (trace != null && identical(Obd2DiagnosticTrace.current, trace)) {
      await Obd2DiagnosticTrace.end();
    }
  }
}
