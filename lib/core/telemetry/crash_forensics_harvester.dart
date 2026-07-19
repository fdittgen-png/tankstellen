// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/error_logger.dart';
import 'collectors/breadcrumb_persistence.dart';

/// #3580 — a death of the PREVIOUS app process, reconstructed on launch
/// from the native crash journal / `ApplicationExitInfo`. Raised only
/// into the local error log (never thrown).
class PreviousProcessDeath implements Exception {
  const PreviousProcessDeath(this.message);
  final String message;

  @override
  String toString() => 'PreviousProcessDeath: $message';
}

/// Drains the native crash-forensics captures once per launch and folds
/// them into the on-device error log, so crashes that previously
/// vanished (native plugin crashes, ANRs, OOM kills — the "recording
/// crashed with no traces" class) become analyzable traces with the
/// previous run's persisted breadcrumbs attached.
///
/// Android-only by construction: on platforms without the channel the
/// harvest is a silent no-op.
class CrashForensicsHarvester {
  CrashForensicsHarvester._();

  static const MethodChannel _channel =
      MethodChannel('tankstellen/crash_forensics');

  /// Exit reasons that indicate the OS reclaimed a healthy background
  /// process — routine on Android, breadcrumb-weight, never an ERROR.
  static const Set<String> _routineReasons = {'freezer', 'other'};

  static Future<void> harvestAndLog() async {
    final String? raw;
    try {
      raw = await _channel.invokeMethod<String>('harvest');
    } on MissingPluginException {
      return; // iOS / tests — no native side.
    } on PlatformException catch (e, st) {
      debugPrint('CrashForensics harvest failed: $e\n$st');
      return;
    }
    if (raw == null || raw.isEmpty) return;

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('CrashForensics payload unparseable: $e\n$st');
      return;
    }

    final breadcrumbs = BreadcrumbPersistence.lastRunSummary();

    for (final entry in (decoded['uncaught'] as List? ?? const [])) {
      if (entry is! Map) continue;
      final stamp = _stamp(entry['timestampMs']);
      unawaited(errorLogger.log(
        ErrorLayer.background,
        PreviousProcessDeath(
          'uncaught ${entry['error']} on thread ${entry['thread']} '
          '(previous run, $stamp)',
        ),
        // The JOURNALED stack is the real crash stack — surface it as the
        // trace's stack trace, not buried in context.
        StackTrace.fromString(entry['stack']?.toString() ?? ''),
        context: {
          'where': 'crash forensics: uncaught JVM exception (#3580)',
          'crashedAt': stamp,
          'lastBreadcrumbs': breadcrumbs,
        },
      ));
    }

    for (final entry in (decoded['exits'] as List? ?? const [])) {
      if (entry is! Map) continue;
      final reason = entry['reason']?.toString() ?? 'unknown';
      if (_routineReasons.contains(reason)) continue;
      final stamp = _stamp(entry['timestampMs']);
      final trace = entry['trace']?.toString() ?? '';
      unawaited(errorLogger.log(
        ErrorLayer.background,
        PreviousProcessDeath(
          'process died: $reason '
          '(${entry['importance']}, $stamp, '
          'pss=${entry['pssKb']}kB rss=${entry['rssKb']}kB) '
          '${entry['description'] ?? ''}',
        ),
        trace.isEmpty ? StackTrace.current : StackTrace.fromString(trace),
        context: {
          'where': 'crash forensics: ApplicationExitInfo (#3580)',
          'reason': reason,
          'importance': entry['importance']?.toString() ?? '',
          'crashedAt': stamp,
          'lastBreadcrumbs': breadcrumbs,
        },
      ));
    }
  }

  static String _stamp(dynamic timestampMs) {
    final ms = timestampMs is num ? timestampMs.toInt() : null;
    if (ms == null) return 'unknown time';
    return DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String();
  }
}
