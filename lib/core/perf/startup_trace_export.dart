// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import '../constants/app_constants.dart';
import '../logging/error_logger.dart';
import '../sharing/public_file_exporter.dart';
import '../storage/hive_open_timing.dart';
import '../telemetry/storage/trace_storage.dart';
import 'startup_timer.dart';

/// #3383 — file export + canonical JSON for the startup-initialization trace
/// (the [StartupTimer] milestones). Local-only, files-only: writes JSON to the
/// device's public Downloads folder via [PublicFileExporter] — the same path
/// every other trace uses — and also rides the standard error-log export via
/// [TraceStorage.extraExportSections]. No share sheet, no network, no paid
/// services.
///
/// The milestones are absolute checkpoints (`elapsedMs` since
/// `StartupTimer.start`); this turns each consecutive pair into a PHASE with a
/// duration, so a reader (and the dev-tools waterfall) sees where cold-start
/// time goes and which serial phase is the bottleneck to parallelise.
class StartupTraceExport {
  StartupTraceExport._();

  /// v2 (#3445): adds the `spans` section — the post-first-frame
  /// launch-sync spans (`tanksync_init`, `trips_merge`, per-table entity
  /// merges, `sync_phase_done`) recorded after `StartupTimer.finish()`.
  ///
  /// v3 (#4110): adds `slowestBoxOpen`. The `hive_init` phase owned
  /// 8,855 ms of an 8,891 ms cold start in the 2026-09-12 field export,
  /// and `HiveBoxes.init` now marks its four sub-phases — but the box
  /// opens are PARALLEL, so their durations overlap and the phase alone
  /// cannot say which one is the long pole. This names it.
  static const int schemaVersion = 3;

  /// The export-section key registered into the error-log export.
  static const String exportSectionKey = 'startupTrace';

  /// Turn the absolute [milestones] into ordered phase spans. Each phase is
  /// the segment LEADING UP TO its milestone: `atMs` is the milestone's
  /// elapsed time, `durationMs` the delta from the previous milestone (or 0).
  static List<Map<String, Object?>> phases(List<StartupMilestone> milestones) {
    final out = <Map<String, Object?>>[];
    var previousMs = 0;
    for (final m in milestones) {
      out.add({
        'name': m.name,
        'atMs': m.elapsedMs,
        'durationMs': m.elapsedMs - previousMs,
      });
      previousMs = m.elapsedMs;
    }
    return out;
  }

  /// Serialize [spans] (#3445 — the post-first-frame launch-sync spans)
  /// into export rows. Attributes (per-table row counts) travel verbatim.
  static List<Map<String, Object?>> spanMaps(List<StartupSpan> spans) => [
        for (final s in spans)
          {
            'name': s.name,
            'startMs': s.startMs,
            'endMs': s.endMs,
            'durationMs': s.durationMs,
            if (s.attributes.isNotEmpty) 'attributes': s.attributes,
          },
      ];

  /// Pure builder for the canonical export document — no I/O, no globals, so
  /// it is unit-testable directly.
  static Map<String, Object?> buildDocument({
    required List<StartupMilestone> milestones,
    required int? totalMs,
    required DateTime exportedAt,
    required String appVersion,
    List<StartupSpan> spans = const [],
    (String, int)? slowestBoxOpen,
  }) {
    return {
      'schema': schemaVersion,
      'kind': 'startupTrace',
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'totalMs': totalMs,
      'phases': phases(milestones),
      'spans': spanMaps(spans),
      // #4110 — omitted rather than null-filled when init has not run
      // (a test, or an export before storage came up): an absent field
      // is honest, a `{"name": null}` row invites a reader to conclude
      // something.
      if (slowestBoxOpen != null)
        'slowestBoxOpen': {
          'box': slowestBoxOpen.$1,
          'durationMs': slowestBoxOpen.$2,
        },
    };
  }

  /// Pretty-printed JSON of the current [StartupTimer] trace.
  static String currentJson({DateTime? exportedAt}) {
    final timer = StartupTimer.instance;
    final doc = buildDocument(
      milestones: timer.milestones,
      totalMs: timer.totalMs,
      exportedAt: exportedAt ?? DateTime.now(),
      appVersion: AppConstants.appVersion,
      spans: timer.spans,
      slowestBoxOpen: HiveOpenTiming.slowest,
    );
    return const JsonEncoder.withIndent('  ').convert(doc);
  }

  /// Write the current trace as a JSON file to public Downloads. Returns
  /// `true` on success, `false` (logged) otherwise. Best-effort — an export
  /// is never important enough to throw.
  static Future<bool> export({DateTime? exportedAt}) async {
    final now = exportedAt ?? DateTime.now();
    final stamp = now.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: currentJson(exportedAt: now),
        fileName: 'tankstellen-startuptrace-$stamp.json',
        mimeType: 'application/json',
      );
      return true;
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'StartupTraceExport.export: json write',
      }));
      return false;
    }
  }

  /// Register the startup trace as an extra section of the standard error-log
  /// export (so it travels with the diagnostics bundle). Idempotent.
  static void ensureExtraExportSectionRegistered() {
    TraceStorage.extraExportSections[exportSectionKey] = () => {
          'totalMs': StartupTimer.instance.totalMs,
          'phases': phases(StartupTimer.instance.milestones),
          'spans': spanMaps(StartupTimer.instance.spans),
          if (HiveOpenTiming.slowest case final slowest?)
            'slowestBoxOpen': {
              'box': slowest.$1,
              'durationMs': slowest.$2,
            },
        };
  }
}
