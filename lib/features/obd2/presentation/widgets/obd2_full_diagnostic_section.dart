// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/logging/app_log.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/sharing/public_file_exporter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/obd2_full_diagnostic_provider.dart';
import '../screens/obd2_diagnostic_report_screen.dart';

/// #4548 / #4551 (Epic #4547) — the "Full diagnostic recording" switch and
/// the list of stored recordings, each downloadable to the public
/// Downloads folder (the path every other trace export uses) or
/// deletable. Lives in the OBD2 Troubleshooting settings group.
class Obd2FullDiagnosticSection extends ConsumerWidget {
  const Obd2FullDiagnosticSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final enabled = ref.watch(obd2FullDiagnosticRecordingProvider);
    final recordings = ref.watch(obd2DiagnosticRecordingsProvider);
    final rows = recordings.value ?? const <Obd2DiagnosticRecording>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('obd2FullDiagnosticToggle'),
          value: enabled,
          title: Text(l.obd2FullDiagnosticTitle),
          subtitle: Text(
            l.obd2FullDiagnosticSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          onChanged: (v) =>
              ref.read(obd2FullDiagnosticRecordingProvider.notifier).set(v),
          contentPadding: EdgeInsets.zero,
        ),
        if (enabled || rows.isNotEmpty) ...[
          Text(l.obd2DiagnosticRecordingsTitle,
              style: theme.textTheme.titleSmall),
          if (rows.isEmpty)
            Text(
              l.obd2DiagnosticRecordingsEmpty,
              key: const Key('obd2DiagnosticRecordingsEmpty'),
              style: theme.textTheme.bodySmall,
            )
          else
            for (final r in rows) _RecordingRow(recording: r),
        ],
      ],
    );
  }
}

class _RecordingRow extends ConsumerWidget {
  const _RecordingRow({required this.recording});

  final Obd2DiagnosticRecording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when =
        DateFormat.yMMMd(locale).add_Hm().format(recording.startedAt.toLocal());
    return ListTile(
      key: ValueKey('obd2DiagnosticRecording-${recording.fileName}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(when),
      subtitle: Text(formatRecordingSize(l, recording.sizeBytes)),
      // #4552 — tap opens the per-system health report.
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Obd2DiagnosticReportScreen(recording: recording),
      )),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('obd2DiagnosticDownload-${recording.fileName}'),
            tooltip: l.obd2DiagnosticRecordingDownload,
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _download(context),
          ),
          IconButton(
            key: ValueKey('obd2DiagnosticDelete-${recording.fileName}'),
            tooltip: l.obd2DiagnosticRecordingDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await recording.file.delete();
              if (!context.mounted) return;
              ref.invalidate(obd2DiagnosticRecordingsProvider);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final l = AppLocalizations.of(context);
    try {
      final bytes = await recording.file.readAsBytes();
      await PublicFileExporter.saveBytesToDownloads(
        bytes: bytes,
        fileName: recording.fileName,
        mimeType: 'application/x-ndjson',
      );
      if (!context.mounted) return;
      SnackBarHelper.showSuccess(context, l.savedToDownloadsFolder);
    } catch (e, st) {
      log.error(e, st,
          layer: ErrorLayer.storage,
          context: const {'where': 'Obd2FullDiagnosticSection download'});
      if (!context.mounted) return;
      SnackBarHelper.showError(context, l.obd2DiagnosticRecordingExportFailed);
    }
  }
}

/// `840 KB` / `3,4 MB` — the locale's decimal mark, binary units.
String formatRecordingSize(AppLocalizations l, int bytes) {
  const mb = 1024 * 1024;
  return bytes < mb
      ? l.obd2RecordingSizeKb(UnitFormatter.formatDecimal(bytes / 1024))
      : l.obd2RecordingSizeMb(UnitFormatter.formatDecimal(bytes / mb));
}
