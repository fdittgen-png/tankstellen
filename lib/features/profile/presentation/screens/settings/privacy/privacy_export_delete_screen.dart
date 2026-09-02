// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../../core/widgets/section_card.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../widgets/privacy/export_format_sheet.dart';
import '../settings_topic_scaffold.dart';
import 'privacy_export_actions.dart';

/// Privacy & data → Export or delete (#3912, Epic #3907): ONE export
/// button that opens the format chooser (ZIP / JSON / CSV), the error-log
/// row with its Save and Clear actions, and the danger zone with the
/// delete-everything button. The handlers live in [PrivacyExportActions]
/// — the former dashboard's, moved unchanged.
class PrivacyExportDeleteScreen extends ConsumerStatefulWidget {
  const PrivacyExportDeleteScreen({super.key});

  @override
  ConsumerState<PrivacyExportDeleteScreen> createState() =>
      _PrivacyExportDeleteScreenState();
}

class _PrivacyExportDeleteScreenState
    extends ConsumerState<PrivacyExportDeleteScreen>
    with PrivacyExportActions<PrivacyExportDeleteScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final errorLogCount = ref.watch(traceStorageProvider).count;

    return SettingsTopicScaffold(
      title: l.privacyTopicExportDeleteTitle,
      children: [
        SettingsGroupHeader(
          icon: Icons.download_outlined,
          title: l.privacyExportSectionTitle,
        ),
        SectionCard(
          child: FilledButton.icon(
            key: const ValueKey('privacy-export-button'),
            onPressed: _chooseExportFormat,
            icon: const Icon(Icons.download),
            label: Text(l.privacyExportMyData),
          ),
        ),
        const SizedBox(height: 16),
        SettingsGroupHeader(
          icon: Icons.bug_report_outlined,
          title: l.privacyErrorLogTitle,
        ),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, size: 20),
                title: Text(l.privacyErrorLogTitle),
                subtitle: Text(
                  l.privacyErrorLogCount(errorLogCount),
                  key: const Key('privacyErrorLogCount'),
                ),
              ),
              // #476 — share locally-recorded error traces; #1971 the
              // reset action (disabled when the log is empty); #2145 the
              // label reflects the dominant behaviour (save to Downloads —
              // clipboard / share fallbacks by payload size).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  overflowSpacing: 8,
                  children: [
                    TextButton.icon(
                      key: const ValueKey('privacy-clear-error-log-button'),
                      onPressed: errorLogCount == 0 ? null : clearErrorLog,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l.privacyErrorLogClear),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('privacy-export-error-log-button'),
                      onPressed: exportErrorLog,
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: Text(l.privacyErrorLogSave),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsGroupHeader(
          icon: Icons.warning_amber_rounded,
          title: l.privacyDangerZoneTitle,
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.privacyDangerZoneBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('privacy-delete-all-button'),
                onPressed: deleteAllData,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.delete_forever),
                label: Text(l.privacyDeleteAllMyData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseExportFormat() async {
    final format = await showPrivacyExportFormatSheet(context);
    if (format == null || !mounted) return;
    switch (format) {
      case PrivacyExportFormat.zip:
        await exportAll();
      case PrivacyExportFormat.json:
        await exportJson();
      case PrivacyExportFormat.csv:
        await exportCsv();
    }
  }
}
