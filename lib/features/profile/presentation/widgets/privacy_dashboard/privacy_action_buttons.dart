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
        label: Text(l?.privacyExportButton ?? 'Export all data as JSON'),
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
        label: Text(l?.privacyExportCsvButton ?? 'Export all data as CSV'),
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
        label: Text(l?.privacyDeleteButton ?? 'Delete all data'),
      ),
    );
  }
}
