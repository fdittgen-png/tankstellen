// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../core/export/data_exporter.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/privacy_data_provider.dart';
import '../widgets/config_verification_widget.dart';
import '../widgets/privacy_dashboard/local_data_card.dart';
import '../widgets/privacy_dashboard/privacy_action_buttons.dart';
import '../widgets/privacy_dashboard/privacy_banner.dart';
import '../widgets/privacy_dashboard/synced_data_card.dart';

/// Threshold above which the error-log export switches from clipboard
/// to the OS share sheet. Some Samsung clipboard managers silently drop
/// large payloads — see #1301.
const int _errorLogClipboardThresholdBytes = 64 * 1024;

/// Test-only override for the share-sheet handoff used by
/// [_PrivacyDashboardScreenState._exportErrorLog]. Production sends
/// [ShareParams] straight to [SharePlus.instance.share]; widget tests
/// substitute a fake to assert the outgoing payload without launching
/// the real OS share sheet. (#1301)
typedef PrivacyShareSink = Future<void> Function(ShareParams params);

/// See [PrivacyShareSink].
@visibleForTesting
PrivacyShareSink? debugPrivacyShareSinkOverride;

/// Test-only override for the temporary-directory lookup used by the
/// large-log share path. Returns a [Directory] the dashboard is allowed
/// to write into. (#1301)
typedef PrivacyTempDirectoryProvider = Future<Directory> Function();

/// See [PrivacyTempDirectoryProvider].
@visibleForTesting
PrivacyTempDirectoryProvider? debugPrivacyTempDirectoryOverride;

/// GDPR-compliant privacy dashboard showing all locally stored data
/// with options to export as JSON or delete everything.
///
/// Accessible from the profile/settings screen. Designed to give users
/// full transparency about what data the app stores on their device
/// and optionally in the cloud via TankSync.
class PrivacyDashboardScreen extends ConsumerStatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  ConsumerState<PrivacyDashboardScreen> createState() =>
      _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState
    extends ConsumerState<PrivacyDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(privacyDataProvider);
    final l = AppLocalizations.of(context);
    final errorLogCount = ref.watch(traceStorageProvider).count;

    return PageScaffold(
      title: l.privacyDashboardTitle,
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PrivacyBanner(),
          const SizedBox(height: 16),
          // #519 — Configuration & Privacy summary card (moved from the
          // Settings screen). All privacy information now lives inside
          // the Privacy Dashboard; the Settings screen links here.
          const ConfigVerificationWidget(),
          const SizedBox(height: 16),
          LocalDataCard(snapshot: snapshot),
          const SizedBox(height: 16),
          SyncedDataCard(snapshot: snapshot),
          const SizedBox(height: 24),
          PrivacyExportJsonButton(onPressed: _exportData),
          const SizedBox(height: 12),
          PrivacyExportCsvButton(onPressed: _exportDataCsv),
          const SizedBox(height: 12),
          // #476 — share locally-recorded error traces. #1971 added
          // the reset button (clears the buffer once shared / for a
          // clean slate; disabled when the log is empty).
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('privacy-export-error-log-button'),
                  onPressed: _exportErrorLog,
                  icon: const Icon(Icons.bug_report_outlined),
                  label: Text(
                    // #2145 — label reflects the dominant behaviour
                    // (save to Downloads); clipboard/share fallbacks
                    // happen automatically based on payload size.
                    l.privacySaveErrorLog(errorLogCount),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey('privacy-clear-error-log-button'),
                onPressed: errorLogCount == 0 ? null : _clearErrorLog,
                icon: const Icon(Icons.delete_outline),
                tooltip: l.privacyClearErrorLog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrivacyDeleteAllButton(onPressed: _deleteAllData),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    // Grab the localizations BEFORE any async gap so the analyzer is
    // satisfied that we never reach across one to look up `context`.
    final l = AppLocalizations.of(context);
    final json = ref.read(exportPrivacyDataProvider);
    await Clipboard.setData(ClipboardData(text: json));
    // #1993 — also save a copy to the on-device Downloads folder so the
    // user can find the file later via any file manager. The clipboard
    // path stays so existing copy-paste workflows are unchanged.
    await _saveExportToDownloads(
      text: json,
      fileName: 'tankstellen-data.json',
      copySnackbar: l.privacyExportSuccess,
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
    // (#1301); hand off to the OS share sheet instead so the user can
    // route the JSON to email / files / a chat reliably.
    if (byteSize > _errorLogClipboardThresholdBytes) {
      try {
        await _shareErrorLogAsFile(json);
      } on Object catch (e, st) {
        // Share-sheet wiring failed; fall back to clipboard so the bug
        // report isn't blocked on a platform-channel hiccup. #2146 —
        // also surface on the exportable log.
        unawaited(
          errorLogger.log(
            ErrorLayer.ui,
            e,
            st,
            context: const {
              'where': 'PrivacyDashboard._exportErrorLog: share fallback',
            },
          ),
        );
        await Clipboard.setData(ClipboardData(text: json));
        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          _formatCopySnackbar(parsed: parsed, unparsed: unparsed, kb: kb),
        );
        return;
      }
      if (!mounted) return;
      // #1993 — drop a copy into Downloads so the user can grab the file
      // from the file manager. This is the SINGLE Downloads write for the
      // large-log path: [_shareErrorLogAsFile] no longer saves to
      // Downloads itself (it only feeds the widget-test share seam), so
      // the file is written exactly once instead of twice (the double
      // `tankstellen-error-log.json` + `… (1).json` field bug).
      await _saveExportToDownloads(
        text: json,
        fileName: 'tankstellen-error-log.json',
        copySnackbar: 'Error log shared ($kb KB, $totalEntries entries)',
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: json));
    // #1993 — also persist to Downloads (small-path); snackbar now reports
    // the saved path. Falls back to the legacy copy snackbar on save failure.
    await _saveExportToDownloads(
      text: json,
      fileName: 'tankstellen-error-log.json',
      copySnackbar: _formatCopySnackbar(
        parsed: parsed,
        unparsed: unparsed,
        kb: kb,
      ),
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

  /// Clears every buffered error trace and refreshes the dashboard so
  /// the copy button's count drops to 0 (#1971 follow-up).
  Future<void> _clearErrorLog() async {
    await ref.read(traceStorageProvider).clearAll();
    if (!mounted) return;
    // `traceStorageProvider` hands back a stable wrapper over the Hive
    // box, so invalidate it to force `build`'s `count` read to re-run.
    ref.invalidate(traceStorageProvider);
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(context, l.privacyErrorLogCleared);
  }

  /// Routes the large error-log payload to the widget-test share seam
  /// only. The actual Downloads write happens exactly once in the caller
  /// via [_saveExportToDownloads] — see the duplicate-write fix note in
  /// [_exportErrorLog].
  ///
  /// 2026-05-24 follow-up — file exports go straight to the device's
  /// public Downloads folder. The test seam below is preserved so widget
  /// tests can still observe the outgoing [ShareParams] payload; in
  /// production (no sink installed) this is a no-op and the single save
  /// is owned by the caller.
  Future<void> _shareErrorLogAsFile(String json) async {
    final sink = debugPrivacyShareSinkOverride;
    if (sink == null) return;
    final tempDirProvider =
        debugPrivacyTempDirectoryOverride ?? getTemporaryDirectory;
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

  Future<void> _exportDataCsv() async {
    // Grab localizations pre-await — see `_exportData` for the same
    // analyser-friendly pattern.
    final l = AppLocalizations.of(context);
    final storage = ref.read(storageRepositoryProvider);
    final exporter = DataExporter(storage);
    final parts = exporter.exportAllAsCsv();
    final buf = StringBuffer();
    parts.forEach((name, csv) {
      buf
        ..writeln('# $name')
        ..writeln(csv);
    });
    final csvText = buf.toString();
    await Clipboard.setData(ClipboardData(text: csvText));
    // #1993 — also save a copy to the Downloads folder for offline retrieval.
    await _saveExportToDownloads(
      text: csvText,
      fileName: 'tankstellen-data.csv',
      copySnackbar: l.privacyExportCsvSuccess,
    );
  }

  /// Writes [text] to the device's public Downloads folder via
  /// [PublicFileExporter] (#2014) and announces the outcome. When the
  /// save succeeds, the snackbar shows `savedToDownloadsFolder`; on
  /// failure (no permission, no space) it falls back to [copySnackbar]
  /// so the user still gets the original clipboard/share confirmation.
  Future<void> _saveExportToDownloads({
    required String text,
    required String fileName,
    required String copySnackbar,
  }) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    try {
      await PublicFileExporter.saveTextToDownloads(
        text: text,
        fileName: fileName,
        mimeType: fileName.endsWith('.csv') ? 'text/csv' : 'application/json',
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, l.savedToDownloadsFolder);
    } on Object catch (e, st) {
      // #2146 — surface on the user-exportable log.
      unawaited(
        errorLogger.log(
          ErrorLayer.storage,
          e,
          st,
          context: {
            'where': 'PrivacyDashboard._saveExportToDownloads',
            'fileName': fileName,
          },
        ),
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, copySnackbar);
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _confirmDelete();
    if (confirmed != true || !mounted) return;

    final storageMgmt = ref.read(storageManagementProvider);
    await storageMgmt.clearCache();
    await storageMgmt.clearPriceHistory();
    await storageMgmt.deleteApiKey();
    for (final boxName in ['settings', 'favorites', 'profiles']) {
      final box = Hive.box<dynamic>(boxName);
      await box.clear();
    }
    if (mounted) {
      context.go(RoutePaths.setup);
    }
  }

  Future<bool?> _confirmDelete() {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 48,
        ),
        title: Text(l.privacyDeleteTitle),
        content: Text(l.privacyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.privacyDeleteConfirm),
          ),
        ],
      ),
    );
  }
}
