// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Full-width outlined button exporting the privacy data as JSON.
class PrivacyExportJsonButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrivacyExportJsonButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.download),
        label: Text(l.privacyExportButton),
      ),
    );
  }
}

/// Full-width outlined button exporting the privacy data as CSV.
class PrivacyExportCsvButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrivacyExportCsvButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.table_chart),
        label: Text(l.privacyExportCsvButton),
      ),
    );
  }
}

/// Destructive button that triggers the "delete everything" flow.
class PrivacyDeleteAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrivacyDeleteAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
        ),
        icon: const Icon(Icons.delete_forever),
        label: Text(l.privacyDeleteButton),
      ),
    );
  }
}

/// #3869 (Epic #3865, GDPR Art. 20) — the ONE export: every local
/// category (incl. trips as JSON + GPX, vehicles, fill-ups, baselines,
/// reminders, the consent record) and every server table, as a ZIP.
class PrivacyExportAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PrivacyExportAllButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('privacy-export-all-button'),
      onPressed: onPressed,
      icon: const Icon(Icons.archive_outlined),
      label: Text(AppLocalizations.of(context).privacyExportAllButton),
    );
  }
}
