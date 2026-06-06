// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import '../../../core/logging/error_logger.dart';
import '../../../core/sharing/public_file_exporter.dart';
import 'data_access_trace.dart';

/// Local-only export of a [DataAccessTrace] for the dev-gated Developer-tools
/// entry (#2824). Writes the JSON as a FILE into the device's public Downloads
/// folder via [PublicFileExporter] — no share sheet (#2817), matching the
/// app's files-only export stance (#2014). The maintainer opens it from the
/// file manager to read the cache-hit ratio + the per-provider request
/// intervals. No paid services, no network.
class DataAccessTraceExport {
  DataAccessTraceExport._();

  /// Writes the trace JSON to the Downloads folder. Returns `true` when the
  /// write succeeded, `false` (logged) otherwise.
  static Future<bool> export(DataAccessTrace trace) async {
    final json = formatDataAccessTraceJson(trace);
    final stamp =
        trace.capturedAt.toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'tankstellen-dataaccess-$stamp.json';
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: fileName,
        mimeType: 'application/json',
      );
      return true;
    } on MissingPluginException {
      // #2933 (error-log #25) — the `tankstellen/public_files` channel has no
      // registrant outside the root isolate (e.g. a WorkManager background
      // isolate). Writing to Downloads is a foreground sink; degrade to a skip
      // (debug breadcrumb) rather than spool a spurious ERROR trace.
      debugPrint('DataAccessTraceExport.export: public_files channel '
          'unavailable — skipping Downloads write.');
      return false;
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'DataAccessTraceExport.export: json write',
      }));
      return false;
    }
  }
}
