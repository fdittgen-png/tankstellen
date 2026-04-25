import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Action picked from [PumpScanFailureSheet] after a pump-display scan
/// returns no usable data (#953). Returned via `Navigator.pop` so the
/// caller can dispatch on it without holding state inside the sheet.
enum PumpScanFailureAction {
  /// User picked "Corriger manuellement" — close the sheet and leave
  /// the form untouched so they can type the values.
  correctManually,

  /// User picked "Signaler" — open the [BadScanReportSheet] flow with
  /// `ScanKind.pumpDisplay` so the unreadable photo is shipped to the
  /// project's GitHub repo for triage.
  report,

  /// User picked "Retirer la photo" — delete the temp file and forget
  /// the scan completely.
  removePhoto,
}

/// Bottom sheet shown after a pump-display scan returns no usable data
/// (#953). The sheet replaces the previous "Pump display not readable"
/// snackbar so the user can opt to ship the failed photo back to the
/// project instead of seeing it silently dropped.
///
/// The sheet does not own the outcome itself — it simply returns a
/// typed [PumpScanFailureAction] value so the calling screen can react
/// (open the bad-scan report flow, delete the temp file, or close).
class PumpScanFailureSheet extends StatelessWidget {
  const PumpScanFailureSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l?.pumpScanFailureTitle ?? 'Display unreadable',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l?.pumpScanFailureBody ??
                  "We couldn't read the pump display. What would you like "
                      'to do?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context)
                  .pop(PumpScanFailureAction.correctManually),
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                l?.pumpScanFailureCorrectManually ?? 'Correct manually',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context)
                  .pop(PumpScanFailureAction.report),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l?.pumpScanFailureReport ?? 'Report'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context)
                  .pop(PumpScanFailureAction.removePhoto),
              icon: const Icon(Icons.delete_outline),
              label: Text(
                l?.pumpScanFailureRemove ?? 'Remove photo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
