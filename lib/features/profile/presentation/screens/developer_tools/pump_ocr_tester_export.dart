// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/logging/error_logger.dart';
import '../../../../../core/sharing/public_file_exporter.dart';
import '../../../../consumption/data/ocr/ocr_trace_package.dart';
import '../../../../consumption/data/ocr/ocr_trace_serializer.dart';

/// Test-only override for the OCR-package share-sheet handoff, mirroring
/// `error_log_export_row.debugErrorLogShareSinkOverride` (#2518). Widget
/// tests substitute a fake to assert the outgoing payload without
/// launching the real OS share sheet.
typedef OcrPackageShareSink = Future<void> Function(ShareParams params);

/// See [OcrPackageShareSink].
@visibleForTesting
OcrPackageShareSink? debugOcrPackageShareSinkOverride;

/// Test-only override for the temp-directory lookup used by the
/// share-sheet path (#2518).
@visibleForTesting
Future<Directory> Function()? debugOcrPackageTempDirectoryOverride;

/// Byte threshold above which the JSON export prefers the OS share sheet
/// over the clipboard — same rationale as the error-log export (#1301):
/// some clipboard managers silently drop large payloads.
const int kOcrPackageClipboardThresholdBytes = 64 * 1024;

/// Local-only export of a built [OcrTracePackage] for the gated OCR tester
/// (#2518, Epic #2516 Child 2). No paid services, no network — the JSON
/// (and, when present, the capture image) lands in the device's Downloads
/// folder via [PublicFileExporter], with a share-sheet fallback feeding the
/// widget-test seam. Kept as a thin function library so the screen file
/// stays under the 400-line norm.
class OcrTesterExport {
  OcrTesterExport._();

  /// Copies the pretty-printed trace JSON to the clipboard. Returns the
  /// JSON so the caller can size / log it.
  static Future<String> copyAsJson(OcrTracePackage package) async {
    final json = formatOcrTracePackageJson(package);
    await Clipboard.setData(ClipboardData(text: json));
    return json;
  }

  /// Writes the trace JSON (and the sibling capture image, when the
  /// recorder attached one) to the Downloads folder, routing large
  /// payloads through the share-sheet seam first. Returns `true` on a
  /// successful Downloads write, `false` when it fell back / failed.
  static Future<bool> exportPackage(OcrTracePackage package) async {
    final json = formatOcrTracePackageJson(package);
    final stamp = package.capturedAt
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-');
    final jsonName = 'tankstellen-ocr-$stamp.json';

    // Large payloads: hand the JSON file to the share sheet seam first.
    if (utf8.encode(json).length > kOcrPackageClipboardThresholdBytes) {
      await _shareAsFile(json, jsonName);
    }

    var ok = false;
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: jsonName,
        mimeType: 'application/json',
      );
      ok = true;
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'OcrTesterExport.exportPackage: json write',
      }));
    }

    // The capture image rides alongside the JSON so the maintainer can
    // re-view the source frame next to the reasoning chain.
    final image = package.image;
    if (image != null) {
      try {
        await PublicFileExporter.saveBytesToDownloads(
          bytes: base64Decode(image.base64),
          fileName: image.fileName,
          mimeType: 'image/jpeg',
        );
      } on Object catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
          'where': 'OcrTesterExport.exportPackage: image write',
        }));
      }
    }
    return ok;
  }

  /// Routes the JSON to the widget-test share seam only (production has no
  /// sink installed → no-op). The real Downloads write happens once in the
  /// caller, mirroring the #2236 single-write contract.
  static Future<void> _shareAsFile(String json, String fileName) async {
    final sink = debugOcrPackageShareSinkOverride;
    if (sink == null) return;
    final tempDirProvider =
        debugOcrPackageTempDirectoryOverride ?? getTemporaryDirectory;
    final tempDir = await tempDirProvider();
    final filePath = '${tempDir.path}/$fileName';
    await File(filePath).writeAsString(json, flush: true);
    await sink(ShareParams(
      files: [XFile(filePath, mimeType: 'application/json')],
      subject: fileName,
    ));
  }
}
