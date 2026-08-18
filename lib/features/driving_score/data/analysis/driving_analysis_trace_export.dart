// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import 'driving_analysis_trace.dart';

/// Local-only export of a [DrivingAnalysisTrace] for the dev-gated trip-detail
/// calibration tool (#2804). Writes the JSON as a FILE into the device's
/// public Downloads folder via [PublicFileExporter] — no share sheet (#2817),
/// matching the app's files-only export stance (#2014). The maintainer fills
/// in the `comment` field and sends the file from the file manager. No paid
/// services, no network.
class DrivingAnalysisTraceExport {
  DrivingAnalysisTraceExport._();

  /// Writes the trace JSON to the Downloads folder. Returns `true` when the
  /// write succeeded, `false` (logged) otherwise.
  static Future<bool> export(DrivingAnalysisTrace trace) async {
    final json = formatDrivingAnalysisTraceJson(trace);
    final stamp =
        trace.capturedAt.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'tankstellen-driving-$stamp.json';
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: fileName,
        mimeType: 'application/json',
      );
      return true;
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'DrivingAnalysisTraceExport.export: json write',
      }));
      return false;
    }
  }
}
