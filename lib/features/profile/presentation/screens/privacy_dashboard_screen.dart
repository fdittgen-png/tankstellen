import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error_tracing/storage/trace_storage.dart';
import '../../../../core/export/data_exporter.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/privacy_data_provider.dart';
import '../widgets/config_verification_widget.dart';
import '../widgets/privacy_dashboard/local_data_card.dart';
import '../widgets/privacy_dashboard/privacy_action_buttons.dart';
import '../widgets/privacy_dashboard/privacy_banner.dart';
import '../widgets/privacy_dashboard/synced_data_card.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.privacyDashboardTitle ?? 'Privacy Dashboard'),
      ),
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
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    SnackBarHelper.showSuccess(
      context,
      'Error log copied to clipboard (${traces.count} entries)',
    );
  }

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
