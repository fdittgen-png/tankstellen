// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_log.dart';
import '../../core/logging/error_logger.dart';
import '../../core/telemetry/storage/isolate_error_spool.dart';
import '../../core/telemetry/trace_recorder.dart';

/// Background-isolate telemetry replay — extracted from
/// `AppInitializer._launch` by the #3139 phase decomposition.
///
/// ## Ordering contract (#3139)
///
/// Scheduled by `_launch` post-first-frame, AFTER
/// `errorLogger.bind(container)` (the drain reads
/// `traceRecorderProvider` from the bound container) and after the trip
/// recovery + warm-up defers, preserving the pre-decomposition
/// registration order. The sibling #3149 startup-failure replay stays in
/// `AppInitializer._launch` itself — its source placement is pinned by
/// the startup-brick structural tests.
class TelemetryReplayPhase {
  TelemetryReplayPhase._();

  /// #1105 — drain the background-isolate error spool through the
  /// foreground TraceRecorder. WorkManager runs without Riverpod, so
  /// every BG failure is parked in a Hive ring buffer until the app
  /// is in the foreground; replaying here puts those errors in the
  /// same observability pipeline as foreground exceptions (and into
  /// Sentry when the user has consented). Deferred to the post-frame
  /// microtask so the first paint isn't delayed by Hive reads /
  /// recorder writes.
  static Future<void> drainIsolateErrorSpool(
    ProviderContainer container,
  ) async {
    try {
      final recorder = container.read(traceRecorderProvider);
      final replayed = await IsolateErrorSpool.drain(recorder);
      if (replayed > 0) {
        log.info(
            'AppInitializer: drained $replayed isolate error(s) into TraceRecorder');
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st,
          context: {'where': 'isolate spool drain'}));
    }
  }
}
