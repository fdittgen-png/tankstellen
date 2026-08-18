// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../error/guarded.dart';
import '../logging/error_logger.dart';
import '../services/sensitive_clipboard.dart';
import 'public_file_exporter.dart';
import 'share_seam.dart';

/// Threshold above which a text export switches from clipboard to the
/// OS share sheet. Some Samsung clipboard managers silently drop large
/// payloads — see #1301.
const int kExportClipboardThresholdBytes = 64 * 1024;

/// What [exportTextSizeGated] did — the caller maps this onto its
/// localized snackbars (no BuildContext crosses into this helper).
enum SizeGatedTextExportOutcome {
  /// Small payload: copied to the clipboard AND saved to Downloads.
  copiedAndSaved,

  /// Small payload: copied to the clipboard; the Downloads write
  /// failed (logged) — announce the clipboard copy.
  copiedOnly,

  /// Large payload: handed to the share seam and saved to Downloads
  /// exactly once (#2236 single-write fix).
  sharedAndSaved,

  /// Large payload: shared via the seam; the Downloads write failed
  /// (logged) — announce the share.
  sharedOnly,

  /// Large payload: the share seam failed (logged); fell back to a
  /// clipboard copy — announce the clipboard copy.
  shareFailedCopied,
}

extension SizeGatedTextExportOutcomeX on SizeGatedTextExportOutcome {
  /// Whether the text ended up in the Downloads folder.
  bool get savedToDownloads =>
      this == SizeGatedTextExportOutcome.copiedAndSaved ||
      this == SizeGatedTextExportOutcome.sharedAndSaved;

  /// Whether the announce-worthy fallback is the clipboard copy.
  bool get announcedViaClipboard =>
      this == SizeGatedTextExportOutcome.copiedOnly ||
      this == SizeGatedTextExportOutcome.shareFailedCopied;
}

/// The ONE 'export text with size-gated clipboard fallback' flow the
/// error-log exports (privacy dashboard + Developer tools row, #2248)
/// share (#1301 / #1993 / #2236 / #3611):
///
///  - **small payload** (≤ [kExportClipboardThresholdBytes]): copy to
///    the auto-clearing [SensitiveClipboard] (#3611), then save one
///    copy to the public Downloads folder (#1993);
///  - **large payload**: hand a temp file to the [shareSink] seam
///    (widget tests observe the [ShareParams]; production installs no
///    sink → no-op), then perform the SINGLE Downloads write (#2236);
///    if the share path throws, fall back to a clipboard copy.
///
/// All failures are logged via [logFailure] under [logWhere]; no
/// exception escapes. The caller maps the returned outcome onto its
/// localized snackbars.
Future<SizeGatedTextExportOutcome> exportTextSizeGated({
  required String text,
  required String fileName,
  required String mimeType,
  required String logWhere,
  ShareSink? shareSink,
  ShareTempDirectoryProvider? tempDirectoryProvider,
  int clipboardThresholdBytes = kExportClipboardThresholdBytes,
}) async {
  final byteSize = utf8.encode(text).length;

  // Large payloads exceed Samsung One UI's clipboard preview budget
  // (#1301); hand off to the OS share sheet instead.
  if (byteSize > clipboardThresholdBytes) {
    try {
      await _shareAsFile(
        text: text,
        fileName: fileName,
        mimeType: mimeType,
        shareSink: shareSink,
        tempDirectoryProvider: tempDirectoryProvider,
      );
    } on Object catch (e, st) {
      logFailure(e, st, where: '$logWhere: share fallback');
      await SensitiveClipboard.copy(text); // #3611 — auto-clears in 60 s
      return SizeGatedTextExportOutcome.shareFailedCopied;
    }
    // #2236 — SINGLE Downloads write for the large path; [_shareAsFile]
    // only feeds the widget-test share seam.
    final saved = await _saveToDownloads(
      text: text,
      fileName: fileName,
      mimeType: mimeType,
      logWhere: logWhere,
    );
    return saved
        ? SizeGatedTextExportOutcome.sharedAndSaved
        : SizeGatedTextExportOutcome.sharedOnly;
  }

  // #3611 — the payload may carry pre-scrub data; use SensitiveClipboard
  // so the clipboard is auto-cleared after 60 s.
  await SensitiveClipboard.copy(text);
  final saved = await _saveToDownloads(
    text: text,
    fileName: fileName,
    mimeType: mimeType,
    logWhere: logWhere,
  );
  return saved
      ? SizeGatedTextExportOutcome.copiedAndSaved
      : SizeGatedTextExportOutcome.copiedOnly;
}

/// Routes the large payload to the widget-test share seam only. The
/// actual Downloads write happens exactly once in the caller — the
/// #2236 single-write fix.
Future<void> _shareAsFile({
  required String text,
  required String fileName,
  required String mimeType,
  required ShareSink? shareSink,
  required ShareTempDirectoryProvider? tempDirectoryProvider,
}) async {
  if (shareSink == null) return;
  final tempDirProvider = tempDirectoryProvider ?? getTemporaryDirectory;
  final tempDir = await tempDirProvider();
  final filePath = '${tempDir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsString(text, flush: true);
  final params = ShareParams(
    files: [XFile(filePath, mimeType: mimeType)],
    subject: fileName,
  );
  await shareSink(params);
}

/// Writes [text] to the device's public Downloads folder via
/// [PublicFileExporter] (#2014). Returns false (after logging) on
/// failure so the caller can fall back to its copy/share snackbar.
Future<bool> _saveToDownloads({
  required String text,
  required String fileName,
  required String mimeType,
  required String logWhere,
}) async {
  try {
    await PublicFileExporter.saveTextToDownloads(
      text: text,
      fileName: fileName,
      mimeType: mimeType,
    );
    return true;
  } on Object catch (e, st) {
    logFailure(
      e,
      st,
      where: '$logWhere: save to Downloads',
      layer: ErrorLayer.storage,
      extra: {'fileName': fileName},
    );
    return false;
  }
}
