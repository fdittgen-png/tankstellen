// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Threshold above which the error-log export switches from clipboard
/// to the OS share sheet. Some Samsung clipboard managers silently drop
/// large payloads — see #1301.
const int kErrorLogClipboardThresholdBytes = 64 * 1024;

/// Test-only override for the share-sheet handoff used by the
/// large-log export path. Production sends [ShareParams] straight to
/// [SharePlus.instance.share]; widget tests substitute a fake to assert
/// the outgoing payload without launching the real OS share sheet
/// (#1301). Shared by the privacy dashboard and the Developer tools
/// screen (#2248) so there is a SINGLE export implementation.
typedef ErrorLogShareSink = Future<void> Function(ShareParams params);

/// See [ErrorLogShareSink].
@visibleForTesting
ErrorLogShareSink? debugErrorLogShareSinkOverride;

/// Test-only override for the temporary-directory lookup used by the
/// large-log share path. Returns a [Directory] the export is allowed to
/// write into. (#1301)
typedef ErrorLogTempDirectoryProvider = Future<Directory> Function();

/// See [ErrorLogTempDirectoryProvider].
@visibleForTesting
ErrorLogTempDirectoryProvider? debugErrorLogTempDirectoryOverride;

/// The error-log Save + Clear row, plus (optionally) a View action
/// (#2248). Extracted from the privacy dashboard so the SAME
/// single-write export logic is reused by both the privacy dashboard and
/// the Developer tools screen — the #2236 double-write fix is preserved
/// because the Downloads write happens exactly once in
/// [_saveExportToDownloads]; the share-sheet seam never writes to
/// Downloads itself.
///
/// [onView] is null on the privacy dashboard (no raw viewer there) and
/// wired on the Developer tools screen to push the in-app trace viewer.
class ErrorLogExportRow extends ConsumerStatefulWidget {
  /// Optional View action — surfaces a third button that opens the raw
  /// trace viewer. Null hides the button (privacy dashboard parity).
  final VoidCallback? onView;

  const ErrorLogExportRow({super.key, this.onView});

  @override
  ConsumerState<ErrorLogExportRow> createState() => _ErrorLogExportRowState();
}

class _ErrorLogExportRowState extends ConsumerState<ErrorLogExportRow> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final errorLogCount = ref.watch(traceStorageProvider).count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('error-log-export-button'),
                onPressed: _exportErrorLog,
                icon: const Icon(Icons.bug_report_outlined),
                label: Text(
                  l?.developerToolsExportErrorLog(errorLogCount) ??
                      'Save error log ($errorLogCount)',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('error-log-clear-button'),
              onPressed: errorLogCount == 0 ? null : _clearErrorLog,
              icon: const Icon(Icons.delete_outline),
              tooltip: l?.developerToolsClearErrorLog ?? 'Clear error log',
            ),
          ],
        ),
        if (widget.onView != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('error-log-view-button'),
            onPressed: widget.onView,
            icon: const Icon(Icons.list_alt_outlined),
            label: Text(l?.developerToolsViewErrorLog ?? 'View error log'),
          ),
        ],
      ],
    );
  }

  Future<void> _exportErrorLog() async {
    final traces = ref.read(traceStorageProvider);
    final json = traces.exportAsJson();
    final byteSize = utf8.encode(json).length;
    final kb = (byteSize / 1024).toStringAsFixed(1);
    final parsed = traces.parsedCount;
    final unparsed = traces.unparsedCount;
    final totalEntries = parsed + unparsed;

    // Large payloads exceed Samsung One UI's clipboard preview budget
    // (#1301); hand off to the OS share sheet instead.
    if (byteSize > kErrorLogClipboardThresholdBytes) {
      try {
        await _shareErrorLogAsFile(json);
      } on Object catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
          'where': 'ErrorLogExportRow._exportErrorLog: share fallback',
        }));
        await Clipboard.setData(ClipboardData(text: json));
        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          _formatCopySnackbar(parsed: parsed, unparsed: unparsed, kb: kb),
        );
        return;
      }
      if (!mounted) return;
      // #2236 — SINGLE Downloads write for the large-log path;
      // [_shareErrorLogAsFile] only feeds the widget-test share seam.
      await _saveExportToDownloads(
        text: json,
        copySnackbar: 'Error log shared ($kb KB, $totalEntries entries)',
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: json));
    await _saveExportToDownloads(
      text: json,
      copySnackbar:
          _formatCopySnackbar(parsed: parsed, unparsed: unparsed, kb: kb),
    );
  }

  String _formatCopySnackbar({
    required int parsed,
    required int unparsed,
    required String kb,
  }) {
    if (unparsed > 0) {
      return 'Error log copied ($parsed parsed + $unparsed raw entries, '
          '$kb KB) — some entries failed to parse';
    }
    return 'Error log copied to clipboard — $kb KB, $parsed entries';
  }

  Future<void> _clearErrorLog() async {
    await ref.read(traceStorageProvider).clearAll();
    if (!mounted) return;
    ref.invalidate(traceStorageProvider);
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.privacyErrorLogCleared ?? 'Error log cleared',
    );
  }

  /// Routes the large payload to the widget-test share seam only. The
  /// actual Downloads write happens exactly once in the caller via
  /// [_saveExportToDownloads] — preserving the #2236 single-write fix.
  Future<void> _shareErrorLogAsFile(String json) async {
    final sink = debugErrorLogShareSinkOverride;
    if (sink == null) return;
    final tempDirProvider =
        debugErrorLogTempDirectoryOverride ?? getTemporaryDirectory;
    final tempDir = await tempDirProvider();
    final filePath = '${tempDir.path}/tankstellen-error-log.json';
    final file = File(filePath);
    await file.writeAsString(json, flush: true);
    final params = ShareParams(
      files: [XFile(filePath, mimeType: 'application/json')],
      subject: 'tankstellen-error-log.json',
    );
    await sink(params);
  }

  Future<void> _saveExportToDownloads({
    required String text,
    required String copySnackbar,
  }) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: text,
        fileName: 'tankstellen-error-log.json',
        mimeType: 'application/json',
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        l?.savedToDownloadsFolder ?? 'Saved to your Downloads folder',
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
        'where': 'ErrorLogExportRow._saveExportToDownloads',
        'fileName': 'tankstellen-error-log.json',
      }));
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, copySnackbar);
    }
  }
}
