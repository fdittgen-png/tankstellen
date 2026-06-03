// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import 'driving_analysis_trace.dart';

/// Test-only override for the driving-trace share-sheet handoff, mirroring
/// `OcrTesterExport.debugOcrPackageShareSinkOverride` (#2804). Widget tests
/// substitute a fake to capture the outgoing payload without launching the
/// real OS share sheet.
typedef DrivingTraceShareSink = Future<void> Function(ShareParams params);

/// See [DrivingTraceShareSink].
@visibleForTesting
DrivingTraceShareSink? debugDrivingTraceShareSinkOverride;

/// Test-only override for the temp-directory lookup used by the share path
/// (#2804).
@visibleForTesting
Future<Directory> Function()? debugDrivingTraceTempDirectoryOverride;

/// Local-only export of a [DrivingAnalysisTrace] for the dev-gated trip-detail
/// calibration tool (#2804, Epic #2789 C6). No paid services, no network: the
/// JSON lands in the device Downloads folder via [PublicFileExporter] AND is
/// handed to the OS share sheet so the maintainer can send the annotated trace
/// straight back. Mirrors the #2518 OCR export, but its share sink defaults to
/// the real [SharePlus] (production sharing is the whole point) rather than a
/// no-op.
class DrivingAnalysisTraceExport {
  DrivingAnalysisTraceExport._();

  /// Writes the trace JSON to Downloads and opens the share sheet. Returns
  /// `true` when the Downloads write succeeded (the share sheet is best-effort
  /// — its failure is logged but does not flip the result).
  static Future<bool> export(DrivingAnalysisTrace trace) async {
    final json = formatDrivingAnalysisTraceJson(trace);
    final stamp =
        trace.capturedAt.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'tankstellen-driving-$stamp.json';

    var ok = false;
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: fileName,
        mimeType: 'application/json',
      );
      ok = true;
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'DrivingAnalysisTraceExport.export: json write',
      }));
    }

    // Hand the file to the share sheet so the maintainer can send it back.
    // Best-effort — a share failure must not mask a successful Downloads write.
    try {
      await _shareAsFile(json, fileName);
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'DrivingAnalysisTraceExport.export: share',
      }));
    }
    return ok;
  }

  static Future<void> _shareAsFile(String json, String fileName) async {
    final tempDirProvider =
        debugDrivingTraceTempDirectoryOverride ?? getTemporaryDirectory;
    final tempDir = await tempDirProvider();
    final filePath = '${tempDir.path}/$fileName';
    await File(filePath).writeAsString(json, flush: true);
    final params = ShareParams(
      files: [XFile(filePath, mimeType: 'application/json')],
      subject: fileName,
    );
    final sink = debugDrivingTraceShareSinkOverride ??
        (ShareParams p) => SharePlus.instance.share(p).then((_) {});
    await sink(params);
  }
}
