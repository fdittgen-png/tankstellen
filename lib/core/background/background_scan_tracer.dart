// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';

import '../logging/error_logger.dart';
import '../services/diagnostics/data_access_recorder.dart';
import '../services/diagnostics/data_access_trace_export.dart';

/// Dev-gated #2824 data-access tracer for the background scan (Epic #2860 EXIT
/// GATE, #2866).
///
/// The foreground threads a [DataAccessRecorder] through its country services
/// only when developer mode is on (`dataAccessRecorderProvider`), so a trace
/// counts the user's in-app traffic. Until #2866 the OS-spawned background
/// isolate had no such recorder — its multi-country scan traffic was invisible
/// to the rate-limit/ToS audit. This helper closes that gap: when developer
/// mode is on it builds a recorder, threads it through the scan's per-country
/// services + bulk strategies (via `BackgroundPriceSource` /
/// `CountryAlertStrategyResolver`), then [exportIfEnabled] builds a
/// [DataAccessTrace] and writes it to Downloads — exactly the foreground path,
/// so the maintainer can read `aggregates().compliant` for the background scan.
///
/// In production (developer mode off — the default) [recorder] is null, so the
/// chain's `recordDataAccess` calls early-return and the scan carries ZERO
/// added cost — identical to before #2866.
class BackgroundScanTracer {
  BackgroundScanTracer._(this.recorder);

  /// The live recorder when developer mode is on, else null. Pass this through
  /// the scan's `BackgroundPriceSource` / `CountryAlertStrategyResolver`.
  final DataAccessRecorder? recorder;

  /// Whether this scan is being traced (developer mode is on).
  bool get isTracing => recorder != null;

  /// Build a tracer for one scan, gated on the persisted [_debugModeEnabled]
  /// flag. Best-effort: any read fault yields a no-op (null) tracer so a
  /// diagnostics hiccup can never affect the scan.
  static BackgroundScanTracer forScan() {
    DataAccessRecorder? recorder;
    try {
      if (_debugModeEnabled()) recorder = DataAccessRecorder();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'BackgroundScanTracer.forScan: dev-mode read',
      }));
    }
    return BackgroundScanTracer._(recorder);
  }

  /// When tracing, snapshot the recorder into a [DataAccessTrace] and export it
  /// to Downloads (the same dev-only sink the foreground uses). No-op + never
  /// throws when not tracing; a write fault is swallowed (logged downstream).
  Future<void> exportIfEnabled({String? comment}) async {
    final r = recorder;
    if (r == null) return;
    try {
      final trace = r.build(
        comment: comment ?? 'Background multi-country alert scan (#2866).',
      );
      await DataAccessTraceExport.export(trace);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'BackgroundScanTracer.exportIfEnabled',
      }));
    }
  }

  /// Read the persisted `debugMode` feature flag the foreground wrote to the
  /// `feature_flags` box. The box is uncipher'd (mirrors the foreground open),
  /// opened best-effort here so the isolate need not carry the whole feature
  /// system. Returns false when the box is unavailable / the flag is unset.
  static bool _debugModeEnabled() {
    // Feature.name for the developer-tools flag; the box stores one bool per
    // feature keyed by its enum name (see FeatureFlagsRepository).
    // i18n-ignore: storage key (Feature.debugMode.name), not user-facing.
    const debugModeKey = 'debugMode';
    // i18n-ignore: Hive box name, not user-facing.
    const boxName = 'feature_flags';
    final box = Hive.isBoxOpen(boxName) ? Hive.box<dynamic>(boxName) : null;
    if (box == null) return false;
    return box.get(debugModeKey) == true;
  }
}
