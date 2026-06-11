// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../telemetry/collectors/breadcrumb_collector.dart';
import 'error_logger.dart';

/// Severity levels of the [AppLog] facade (#3144).
enum LogLevel {
  /// Developer chatter: visible on the debug console only, fully
  /// invisible in release builds (no logcat / os_log emission).
  debug,

  /// User-flow milestones ("sync ready", "migrated N profiles"): debug
  /// console + a [BreadcrumbCollector] breadcrumb, so the last
  /// [BreadcrumbCollector.maxBreadcrumbs] of them ride along inside
  /// every persisted error trace — release-visible without consuming a
  /// slot in the bounded trace ring.
  info,

  /// Unexpected-but-survivable conditions: full [errorLogger] pipeline
  /// (persisted trace, export, opt-in Sentry) tagged `level: warn` so
  /// triage can separate warnings from hard errors.
  warn,

  /// Hard failures: delegates to [errorLogger] unchanged.
  error,
}

/// Leveled logging facade over the existing `errorLogger` / `debugPrint`
/// split (#3144).
///
/// Before this facade a call site had exactly two choices: `debugPrint`
/// (release-invisible — `_bootstrap()` no-ops it in release builds, and
/// even when emitted it never reaches the trace export) or a full
/// `errorLogger.log(...)` ERROR trace (which consumes one of the 50
/// ring slots). The four levels above fill the gap; see [LogLevel] for
/// the routing of each.
///
/// ## Contract
/// Every method never throws — logging must never derail the caller.
/// The error/warn path inherits [ErrorLogger.log]'s own never-throws
/// contract; the debug/info path catches locally and falls back to a
/// bare [debugPrint].
///
/// ## Why a singleton, not a Riverpod provider
/// Same rationale as [ErrorLogger]: the facade must be callable from
/// background isolates and pre-container startup phases, so it cannot
/// depend on a provider scope. `errorLogger` already routes to the
/// isolate spool when unbound, and the facade simply delegates.
class AppLog {
  AppLog._();

  /// Test seam: force the console gate on/off regardless of
  /// [kDebugMode] (which is always `true` under `flutter test`).
  @visibleForTesting
  bool? debugConsoleOverride;

  /// Test seam: capture console lines instead of [debugPrint].
  @visibleForTesting
  void Function(String line)? consoleSinkOverride;

  /// Reset all test seams.
  @visibleForTesting
  void resetForTest() {
    debugConsoleOverride = null;
    consoleSinkOverride = null;
  }

  bool get _consoleEnabled => debugConsoleOverride ?? kDebugMode;

  /// Developer-only chatter. Console in debug builds, a no-op in
  /// release. Never throws.
  void debug(String message, {String? tag}) {
    try {
      _console(tag, message);
    } catch (e, st) {
      debugPrint('AppLog.debug failed: $e\n$st');
    }
  }

  /// User-flow milestone. Console in debug builds + a breadcrumb that
  /// rides inside every subsequently persisted error trace, so the
  /// statement is release-visible in the field export without spending
  /// a trace-ring slot. Never throws.
  void info(String message, {String? tag}) {
    try {
      BreadcrumbCollector.add(tag ?? 'log', detail: message);
      _console(tag, message);
    } catch (e, st) {
      debugPrint('AppLog.info failed: $e\n$st');
    }
  }

  /// Unexpected-but-survivable condition. Routes through the full
  /// [errorLogger] pipeline (persisted + exportable + opt-in Sentry)
  /// tagged `level: warn`, so it is release-visible as a trace but
  /// distinguishable from a hard error during triage. Never throws.
  void warn(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stack,
    ErrorLayer layer = ErrorLayer.other,
    Map<String, Object?>? context,
  }) {
    try {
      _console(tag, message);
      unawaited(errorLogger.log(layer, error ?? message, stack, context: {
        'level': 'warn',
        'tag': ?tag,
        if (error != null) 'message': message,
        ...?context,
      }));
    } catch (e, st) {
      debugPrint('AppLog.warn failed: $e\n$st');
    }
  }

  /// Hard failure. Delegates to [errorLogger.log] unchanged — same
  /// pipeline, same routing (TraceRecorder when foreground-bound,
  /// isolate spool otherwise). Never throws.
  void error(
    Object error,
    StackTrace? stack, {
    ErrorLayer layer = ErrorLayer.other,
    Map<String, Object?>? context,
  }) {
    unawaited(errorLogger.log(layer, error, stack, context: context));
  }

  void _console(String? tag, String message) {
    if (!_consoleEnabled) return;
    final line = tag == null ? message : '[$tag] $message';
    final sink = consoleSinkOverride;
    if (sink != null) {
      sink(line);
    } else {
      debugPrint(line);
    }
  }
}

/// Process-wide singleton, mirroring [errorLogger]. Safe to call from
/// any isolate.
final AppLog log = AppLog._();
