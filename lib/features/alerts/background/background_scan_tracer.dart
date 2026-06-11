// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'
    show MissingPluginException, RootIsolateToken;
import 'package:hive/hive.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../core/services/diagnostics/data_access_recorder.dart';
import '../../../core/services/diagnostics/data_access_trace_export.dart';

/// #2933 (error-log #25) test seam: force the background-isolate verdict so a
/// foreground unit test can drive both branches of [exportIfEnabled] without a
/// real WorkManager isolate. Null ⇒ the real `RootIsolateToken.instance == null`
/// probe. The platform-channel-bound `RootIsolateToken.instance` can't be
/// mutated from a test, so this override is the only way to exercise the skip.
@visibleForTesting
bool? debugIsBackgroundIsolateOverride;

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
  ///
  /// #2933 (error-log #25) — the Downloads write goes through the
  /// `tankstellen/public_files` platform channel, which is UNAVAILABLE in the
  /// WorkManager background isolate (no plugin registrant) — it threw
  /// `MissingPluginException` and spooled a spurious background ERROR. This is
  /// inherently a foreground/UI sink, so in a background isolate we SKIP the
  /// Downloads export entirely (debug breadcrumb only); the in-app
  /// Developer-tools export still writes it from the root isolate.
  /// [DataAccessTraceExport.export] also degrades a stray
  /// [MissingPluginException] to a skip; the defensive catch here is the
  /// second line of the same never-throws contract.
  Future<void> exportIfEnabled({String? comment}) async {
    final r = recorder;
    if (r == null) return;
    if (_isBackgroundIsolate()) {
      // The public-files channel has no registrant here; writing to Downloads
      // is a foreground operation. Skip gracefully — no ERROR spool.
      debugPrint('BackgroundScanTracer.exportIfEnabled: background isolate — '
          'skipping Downloads export (foreground-only sink).');
      return;
    }
    try {
      final trace = r.build(
        comment: comment ?? 'Background multi-country alert scan (#2866).',
      );
      await DataAccessTraceExport.export(trace);
    } on MissingPluginException {
      // Defensive: the channel was unavailable despite the root-isolate probe
      // (e.g. an isolate without a registrant). Degrade to a skip, not ERROR
      // — but leave a release-visible breadcrumb (#3143).
      BreadcrumbCollector.add('bg-trace-export-skipped',
          detail: 'public_files channel unavailable');
      debugPrint('BackgroundScanTracer.exportIfEnabled: public_files channel '
          'unavailable — skipping Downloads export.');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'BackgroundScanTracer.exportIfEnabled',
      }));
    }
  }

  /// #2933 — true when this code is running in a non-root (background) isolate,
  /// where platform channels have no registrant. `RootIsolateToken.instance` is
  /// non-null ONLY on the root isolate; a WorkManager-spawned isolate returns
  /// null. Honours [debugIsBackgroundIsolateOverride] for tests.
  static bool _isBackgroundIsolate() {
    final override = debugIsBackgroundIsolateOverride;
    if (override != null) return override;
    return RootIsolateToken.instance == null;
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
