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

/// Hard upper bound (UTF-8 bytes) on what [OcrTesterExport.copyAsJson] will
/// hand to the system clipboard (#2853). Android marshals clipboard data
/// over a Binder transaction capped near 1 MB; well above this and
/// `Clipboard.setData` throws `TransactionTooLargeException`. The
/// image-elided trace is normally a few KB, so this is a defensive ceiling
/// that routes any pathological payload to the file export instead.
const int kOcrPackageClipboardMaxBytes = 256 * 1024;

/// Local-only export of a built [OcrTracePackage] for the gated OCR tester
/// (#2518, Epic #2516 Child 2). No paid services, no network — the JSON
/// (and, when present, the capture image) lands in the device's Downloads
/// folder via [PublicFileExporter], with a share-sheet fallback feeding the
/// widget-test seam. Kept as a thin function library so the screen file
/// stays under the 400-line norm.
class OcrTesterExport {
  OcrTesterExport._();

  /// Copies the pretty-printed trace JSON to the clipboard, WITHOUT the
  /// base64 capture image (#2853): the image is ~5 MB and meaningless as
  /// pasted text, and the full payload tripped Android's ~1 MB Binder limit
  /// (`TransactionTooLargeException`). The capture still rides alongside the
  /// JSON via [exportPackage] / [saveAsFixture], which keep the image.
  ///
  /// Returns `true` when the JSON reached the clipboard, `false` when even
  /// the image-elided document exceeds [kOcrPackageClipboardMaxBytes] — in
  /// which case nothing is written and the caller should fall back to the
  /// file export.
  static Future<bool> copyAsJson(OcrTracePackage package) async {
    final json = formatOcrTracePackageJson(package, includeImage: false);
    if (utf8.encode(json).length > kOcrPackageClipboardMaxBytes) {
      return false;
    }
    await Clipboard.setData(ClipboardData(text: json));
    return true;
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

  /// Saves [package] as a regression FIXTURE (#2519): a slugged source
  /// image (`<slug>.jpg`) plus a `<slug>.ocrpkg.json` whose `expected`
  /// block is filled from the final read (hand-correctable after export).
  /// Both land in the device Downloads folder; the maintainer then moves
  /// the pair under `test/fixtures/pump_displays/` and runs
  /// `tool/promote_ocr_fixture.dart` to generate the pure-Dart replay test.
  ///
  /// Returns the slug used (for the snackbar / a test assertion), or null
  /// when there was no image to anchor the fixture on.
  static Future<String?> saveAsFixture(OcrTracePackage package) async {
    final image = package.image;
    if (image == null) return null;
    final slug = fixtureSlug(package);

    // Fold the final read into `expected` so the generated test asserts
    // it; the maintainer hand-corrects the JSON if the read was wrong.
    final withExpected = _withExpectedFromResult(package, image, slug);
    final json = formatOcrTracePackageJson(withExpected);

    try {
      await PublicFileExporter.saveBytesToDownloads(
        bytes: base64Decode(image.base64),
        fileName: '$slug.jpg',
        mimeType: 'image/jpeg',
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'OcrTesterExport.saveAsFixture: image write',
      }));
    }
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: json,
        fileName: '$slug.ocrpkg.json',
        mimeType: 'application/json',
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'OcrTesterExport.saveAsFixture: json write',
      }));
    }
    return slug;
  }

  /// Builds the fixture slug from the country + read values, mirroring the
  /// committed `fr_tokheim_18_59eur_23_30l` naming so a maintainer can drop
  /// the pair straight into `test/fixtures/pump_displays/`.
  static String fixtureSlug(OcrTracePackage package) {
    final parts = <String>[package.kind.name];
    final country = package.input.country;
    if (country != null && country.isNotEmpty) {
      parts.add(country.toLowerCase());
    }
    final r = package.result;
    if (r?.totalCost != null) parts.add('${_money(r!.totalCost!)}eur');
    if (r?.liters != null) parts.add('${_money(r!.liters!)}l');
    if (parts.length == 1) {
      // No read to describe — fall back to a timestamp so two captures of
      // an unreadable display don't collide.
      parts.add(package.capturedAt.millisecondsSinceEpoch.toString());
    }
    return parts.join('_');
  }

  /// Formats a money/volume double into a slug fragment: `18.59` → `18_59`.
  static String _money(double v) =>
      v.toStringAsFixed(2).replaceAll('.', '_');

  /// Returns a copy of [package] with `expected` seeded from `result` (when
  /// not already set) and the image filename pinned to `<slug>.jpg` so the
  /// generator's sibling-image lookup finds the committed source.
  static OcrTracePackage _withExpectedFromResult(
    OcrTracePackage package,
    OcrTraceImage image,
    String slug,
  ) {
    final r = package.result;
    final expected = package.expected ??
        (r == null
            ? null
            : OcrTraceExpected(
                totalCost: r.totalCost,
                liters: r.liters,
                pricePerLiter: r.pricePerLiter,
              ));
    return OcrTracePackage(
      kind: package.kind,
      capturedAt: package.capturedAt,
      input: package.input,
      preprocess: package.preprocess,
      mlkit: package.mlkit,
      classification: package.classification,
      assembledLabels: package.assembledLabels,
      anchors: package.anchors,
      magnitudeFallback: package.magnitudeFallback,
      crossCheck: package.crossCheck,
      confidence: package.confidence,
      gate: package.gate,
      receipt: package.receipt,
      result: package.result,
      expected: expected,
      image: OcrTraceImage(fileName: '$slug.jpg', base64: image.base64),
    );
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
