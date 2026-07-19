// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/error_trace.dart';
import 'breadcrumb_collector.dart';

/// #3580 — crash-surviving breadcrumbs.
///
/// The in-memory [BreadcrumbCollector] ring dies with the process, so a
/// native crash / ANR / OOM kill loses exactly the context that would
/// explain it. This helper mirrors the ring to a small on-disk JSON file
/// (debounced to at most one write per [flushInterval]) and, on the next
/// launch, hands the PREVIOUS run's ring to the crash-forensics harvester
/// so every harvested process death carries what the app was doing when
/// it died.
///
/// Local-only, same privacy envelope as the error log itself.
class BreadcrumbPersistence {
  BreadcrumbPersistence._();

  static const Duration flushInterval = Duration(seconds: 2);

  static File? _file;
  static Timer? _pending;
  static List<Breadcrumb> _lastRun = const [];

  /// Breadcrumbs persisted by the PREVIOUS process run — captured by
  /// [init] before this run starts overwriting the file. Empty when the
  /// previous run exited cleanly enough to leave nothing interesting or
  /// persistence never ran.
  static List<Breadcrumb> get lastRun => _lastRun;

  /// Read the previous run's ring, then start mirroring this run's.
  /// [directoryPath] is the app-support directory (injected by the
  /// caller so this file stays free of plugin lookups and trivially
  /// testable with a temp dir).
  static Future<void> init(String directoryPath) async {
    try {
      final dir = Directory('$directoryPath/crash_journal');
      await dir.create(recursive: true);
      final file = File('${dir.path}/breadcrumbs.json');
      if (file.existsSync()) {
        try {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is List) {
            _lastRun = decoded
                .whereType<Map<String, dynamic>>()
                .map(Breadcrumb.fromJson)
                .toList(growable: false);
          }
        } catch (e, st) {
          // A torn write from a mid-crash flush — previous ring is lost,
          // this run's mirroring still starts fresh.
          debugPrint('BreadcrumbPersistence: previous ring unreadable: $e\n$st');
        }
      }
      _file = file;
      await file.writeAsString('[]', flush: true);
      BreadcrumbCollector.onAdd = _scheduleFlush;
    } catch (e, st) {
      debugPrint('BreadcrumbPersistence: init failed: $e\n$st');
    }
  }

  static void _scheduleFlush() {
    if (_pending != null) return;
    _pending = Timer(flushInterval, () {
      _pending = null;
      unawaited(_flush());
    });
  }

  static Future<void> _flush() async {
    final file = _file;
    if (file == null) return;
    try {
      final ring = BreadcrumbCollector.snapshot()
          .map((b) => b.toJson())
          .toList(growable: false);
      await file.writeAsString(jsonEncode(ring), flush: true);
    } catch (e, st) {
      debugPrint('BreadcrumbPersistence: flush failed: $e\n$st');
    }
  }

  /// Render [lastRun] as compact context lines for a crash trace.
  static String lastRunSummary({int max = 15}) {
    final ring = _lastRun;
    if (ring.isEmpty) return '(no persisted breadcrumbs)';
    final tail = ring.length <= max ? ring : ring.sublist(ring.length - max);
    return tail
        .map((b) =>
            '${b.timestamp.toIso8601String()} ${b.action}'
            '${b.detail == null ? '' : ' — ${b.detail}'}')
        .join('\n');
  }

  /// Test seam — detach and reset all static state.
  @visibleForTesting
  static void resetForTest() {
    _pending?.cancel();
    _pending = null;
    _file = null;
    _lastRun = const [];
    BreadcrumbCollector.onAdd = null;
  }
}
