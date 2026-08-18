// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/services/sensitive_clipboard.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/sharing/share_seam.dart';
import '../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../core/export/data_exporter.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/privacy_data_provider.dart';
import '../widgets/config_verification_widget.dart';
import '../widgets/error_log_export_row.dart'
    show exportErrorLogSizeGated, errorLogExportSnackbar;
import '../widgets/privacy_dashboard/local_data_card.dart';
import '../widgets/privacy_dashboard/privacy_action_buttons.dart';
import '../widgets/privacy_dashboard/privacy_banner.dart';
import '../widgets/privacy_dashboard/synced_data_card.dart';
import '../../../../core/utils/unit_formatter.dart';

/// Test-only override for the share-sheet handoff used by
/// [_PrivacyDashboardScreenState._exportErrorLog] — the shared
/// [ShareSink] seam (#1301).
@visibleForTesting
ShareSink? debugPrivacyShareSinkOverride;

/// Test-only override for the temporary-directory lookup used by the
/// large-log share path — the shared [ShareTempDirectoryProvider] seam
/// (#1301).
@visibleForTesting
ShareTempDirectoryProvider? debugPrivacyTempDirectoryOverride;

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
    // #3611 — the export blob aggregates the user's stored data; use
    // SensitiveClipboard so the clipboard is auto-cleared after 60 s.
    await SensitiveClipboard.copy(json);
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
    final kb = UnitFormatter.formatDecimal(byteSize / 1024);
    final parsed = traces.parsedCount;
    final unparsed = traces.unparsedCount;
    final totalEntries = parsed + unparsed;

    // The ONE size-gated clipboard / share-seam / single-Downloads-write
    // flow (#1301 / #1993 / #2236 / #3611), shared with the Developer
    // tools row (#2248) via `exportErrorLogSizeGated`.
    final outcome = await exportErrorLogSizeGated(
      json: json,
      logWhere: 'PrivacyDashboard._exportErrorLog',
      shareSink: debugPrivacyShareSinkOverride,
      tempDirectoryProvider: debugPrivacyTempDirectoryOverride,
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
    // #3611 — same hygiene as the JSON export: auto-clear after 60 s.
    await SensitiveClipboard.copy(csvText);
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
      logFailure(
        e,
        st,
        where: 'PrivacyDashboard._saveExportToDownloads',
        layer: ErrorLayer.storage,
        extra: {'fileName': fileName},
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
    // #3682 — the ONE shared destructive-action dialog.
    return confirmDestructiveAction(
      context,
      title: l.privacyDeleteTitle,
      message: l.privacyDeleteBody,
      confirmLabel: l.privacyDeleteConfirm,
    );
  }
}
