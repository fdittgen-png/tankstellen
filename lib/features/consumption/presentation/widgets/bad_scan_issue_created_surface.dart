import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Confirmation surface shown after a GitHub issue has been created
/// successfully. Replaces the form portion of [BadScanReportSheet]
/// once the reporter returns a non-null URL.
class BadScanIssueCreatedSurface extends StatelessWidget {
  final Uri issueUrl;
  final Future<void> Function() onOpenInBrowser;
  final VoidCallback onClose;

  const BadScanIssueCreatedSurface({
    super.key,
    required this.issueUrl,
    required this.onOpenInBrowser,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                issueUrl.toString(),
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onOpenInBrowser,
          icon: const Icon(Icons.open_in_new),
          label: Text(
            l?.badScanReportOpenInBrowser ?? 'Open in browser',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClose,
          child: Text(l?.close ?? 'Close'),
        ),
      ],
    );
  }
}
