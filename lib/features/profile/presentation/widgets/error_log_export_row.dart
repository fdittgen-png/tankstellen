// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sharing/share_seam.dart';
import '../../../../core/sharing/size_gated_text_export.dart';
import '../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';

/// Threshold above which the error-log export switches from clipboard
/// to the OS share sheet (#1301) — the shared size gate.
const int kErrorLogClipboardThresholdBytes = kExportClipboardThresholdBytes;

/// Test-only override for the share-sheet handoff used by the
/// large-log export path — the shared [ShareSink] seam (#1301). Shared
/// by the privacy dashboard and the Developer tools screen (#2248) so
/// there is a SINGLE export implementation.
@visibleForTesting
ShareSink? debugErrorLogShareSinkOverride;

/// Test-only override for the temporary-directory lookup used by the
/// large-log share path — the shared [ShareTempDirectoryProvider]
/// seam (#1301).
@visibleForTesting
ShareTempDirectoryProvider? debugErrorLogTempDirectoryOverride;

/// The error-log Save + Clear row, plus (optionally) a View action
/// (#2248). Extracted from the privacy dashboard so the SAME
/// single-write export logic is reused by both the privacy dashboard and
/// the Developer tools screen. The size-gated clipboard/share/Downloads
/// flow itself lives in the shared [exportTextSizeGated] helper — the
/// #2236 single-write fix and the #3611 sensitive-clipboard hygiene are
/// preserved there.
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
                label: Text(l.developerToolsExportErrorLog(errorLogCount)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('error-log-clear-button'),
              onPressed: errorLogCount == 0 ? null : _clearErrorLog,
              icon: const Icon(Icons.delete_outline),
              tooltip: l.developerToolsClearErrorLog,
            ),
          ],
        ),
        if (widget.onView != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('error-log-view-button'),
            onPressed: widget.onView,
            icon: const Icon(Icons.list_alt_outlined),
            label: Text(l.developerToolsViewErrorLog),
          ),
        ],
      ],
    );
  }

  Future<void> _exportErrorLog() async {
    final traces = ref.read(traceStorageProvider);
    final json = traces.exportAsJson();
    final kb = (utf8.encode(json).length / 1024).toStringAsFixed(1);
    final parsed = traces.parsedCount;
    final unparsed = traces.unparsedCount;
    final totalEntries = parsed + unparsed;

    final outcome = await exportErrorLogSizeGated(
      json: json,
      logWhere: 'ErrorLogExportRow._exportErrorLog',
      shareSink: debugErrorLogShareSinkOverride,
      tempDirectoryProvider: debugErrorLogTempDirectoryOverride,
    );
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      errorLogExportSnackbar(
        outcome: outcome,
        savedToDownloadsMessage: l.savedToDownloadsFolder,
        parsed: parsed,
        unparsed: unparsed,
        totalEntries: totalEntries,
        kb: kb,
      ),
    );
  }

  Future<void> _clearErrorLog() async {
    await ref.read(traceStorageProvider).clearAll();
    if (!mounted) return;
    ref.invalidate(traceStorageProvider);
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(context, l.privacyErrorLogCleared);
  }
}

/// Runs the shared size-gated export flow for an error-log JSON blob —
/// the ONE implementation both the Developer tools row and the privacy
/// dashboard call (#2248).
Future<SizeGatedTextExportOutcome> exportErrorLogSizeGated({
  required String json,
  required String logWhere,
  ShareSink? shareSink,
  ShareTempDirectoryProvider? tempDirectoryProvider,
}) {
  return exportTextSizeGated(
    text: json,
    fileName: 'tankstellen-error-log.json',
    mimeType: 'application/json',
    logWhere: logWhere,
    shareSink: shareSink,
    tempDirectoryProvider: tempDirectoryProvider,
  );
}

/// Maps a [SizeGatedTextExportOutcome] onto the error-log snackbar
/// wording both call sites shared verbatim.
String errorLogExportSnackbar({
  required SizeGatedTextExportOutcome outcome,
  required String savedToDownloadsMessage,
  required int parsed,
  required int unparsed,
  required int totalEntries,
  required String kb,
}) {
  if (outcome.savedToDownloads) return savedToDownloadsMessage;
  if (outcome == SizeGatedTextExportOutcome.sharedOnly) {
    return 'Error log shared ($kb KB, $totalEntries entries)';
  }
  // Clipboard fallback (small path save failure, or large-path share
  // failure).
  if (unparsed > 0) {
    return 'Error log copied ($parsed parsed + $unparsed raw entries, '
        '$kb KB) — some entries failed to parse';
  }
  return 'Error log copied to clipboard — $kb KB, $parsed entries';
}
