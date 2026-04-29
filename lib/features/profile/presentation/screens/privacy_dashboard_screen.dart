import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

    return PageScaffold(
      title: l?.privacyDashboardTitle ?? 'Privacy Dashboard',
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
          // #476 — give users a way to share the locally-recorded error
          // traces with the maintainer (or with their own bug report)
          // even when Sentry is not configured. Uses Clipboard so we
          // don't need a share_plus dependency.
          OutlinedButton.icon(
            key: const ValueKey('privacy-export-error-log-button'),
            onPressed: _exportErrorLog,
            icon: const Icon(Icons.bug_report_outlined),
            label: Text(
              l?.privacyCopyErrorLog(ref.watch(traceStorageProvider).count) ??
                  'Copy error log to clipboard '
                      '(${ref.watch(traceStorageProvider).count})',
            ),
          ),
          const SizedBox(height: 12),
          PrivacyDeleteAllButton(onPressed: _deleteAllData),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final json = ref.read(exportPrivacyDataProvider);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.privacyExportSuccess ?? 'Data exported to clipboard',
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
        // If share sheet wiring fails we still want to give the user
        // something — fall back to clipboard so the bug report doesn't
        // get blocked on a platform-channel hiccup.
        debugPrint('privacy: error-log share fallback to clipboard: $e\n$st');
        await Clipboard.setData(ClipboardData(text: json));
        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          _formatCopySnackbar(
            parsed: parsed,
            unparsed: unparsed,
            kb: kb,
          ),
        );
        return;
      }
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Error log shared ($kb KB, $totalEntries entries)',
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    SnackBarHelper.showSuccess(
      context,
      _formatCopySnackbar(
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

  Future<void> _shareErrorLogAsFile(String json) async {
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
    final sink = debugPrivacyShareSinkOverride ?? _defaultShareSink;
    await sink(params);
  }

  static Future<void> _defaultShareSink(ShareParams params) =>
      SharePlus.instance.share(params);

  Future<void> _exportDataCsv() async {
    final storage = ref.read(storageRepositoryProvider);
    final exporter = DataExporter(storage);
    final parts = exporter.exportAllAsCsv();
    final buf = StringBuffer();
    parts.forEach((name, csv) {
      buf
        ..writeln('# $name')
        ..writeln(csv);
    });
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l?.privacyExportCsvSuccess ?? 'CSV data exported to clipboard',
    );
  }

  Future<void> _deleteAllData() async {
    final confirmed = await _confirmDelete();
    if (confirmed != true || !mounted) return;

    final storageMgmt = ref.read(storageManagementProvider);
    await storageMgmt.clearCache();
    await storageMgmt.clearPriceHistory();
    await storageMgmt.deleteApiKey();
    for (final boxName in ['settings', 'favorites', 'profiles']) {
      final box = Hive.box(boxName);
      await box.clear();
    }
    if (mounted) {
      context.go('/setup');
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
        title: Text(l?.privacyDeleteTitle ?? 'Delete all data?'),
        content: Text(
          l?.privacyDeleteBody ??
              'This will permanently delete:\n\n'
                  '- All favorites and station data\n'
                  '- All search profiles\n'
                  '- All price alerts\n'
                  '- All price history\n'
                  '- All cached data\n'
                  '- Your API key\n'
                  '- All app settings\n\n'
                  'The app will reset to its initial state. '
                  'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l?.privacyDeleteConfirm ?? 'Delete everything',
            ),
          ),
        ],
      ),
    );
  }
}
