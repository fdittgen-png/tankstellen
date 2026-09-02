// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// The three data-export formats (#3912, Epic #3907).
enum PrivacyExportFormat { zip, json, csv }

/// Bottom sheet offering the three export formats as list rows; resolves
/// to the chosen format, or null when dismissed.
Future<PrivacyExportFormat?> showPrivacyExportFormatSheet(
    BuildContext context) {
  return showModalBottomSheet<PrivacyExportFormat>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => const _ExportFormatSheet(),
  );
}

class _ExportFormatSheet extends StatelessWidget {
  const _ExportFormatSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l.privacyExportSheetTitle,
                style: theme.textTheme.titleMedium),
          ),
          ListTile(
            key: const Key('privacyExportZipOption'),
            leading: const Icon(Icons.archive_outlined),
            title: Text(l.privacyExportZipTitle),
            subtitle: Text(l.privacyExportZipSubtitle),
            onTap: () => Navigator.pop(context, PrivacyExportFormat.zip),
          ),
          ListTile(
            key: const Key('privacyExportJsonOption'),
            leading: const Icon(Icons.data_object),
            title: Text(l.privacyExportJsonTitle),
            subtitle: Text(l.privacyExportJsonSubtitle),
            onTap: () => Navigator.pop(context, PrivacyExportFormat.json),
          ),
          ListTile(
            key: const Key('privacyExportCsvOption'),
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l.privacyExportCsvTitle),
            subtitle: Text(l.privacyExportCsvSubtitle),
            onTap: () => Navigator.pop(context, PrivacyExportFormat.csv),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
