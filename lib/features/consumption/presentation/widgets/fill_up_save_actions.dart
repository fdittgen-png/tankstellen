import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Bottom action block on the Add-Fill-Up form: the primary Save
/// button plus the conditional "Report scan error" follow-up that
/// only appears when the form was pre-filled from a receipt/pump
/// scan (a non-null `_lastScan` on the parent screen).
///
/// Keeping the two buttons together in one widget mirrors how they
/// relate visually — the report button is an affordance tied to
/// the last scan, not a standalone action.
///
/// Pulled out of `add_fill_up_screen.dart` (#727) so the screen's
/// `build` method drops the ~13-line inline block and the two
/// buttons can be rendered in isolation by widget tests.
class FillUpSaveActions extends StatelessWidget {
  final VoidCallback onSave;

  /// Non-null when the form was pre-filled from a scan; null when
  /// the user is entering the fill-up manually. The report button
  /// renders only when this is set.
  final VoidCallback? onReportBadScan;

  const FillUpSaveActions({
    super.key,
    required this.onSave,
    this.onReportBadScan,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save),
          label: Text(l?.save ?? 'Save'),
        ),
        if (onReportBadScan != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onReportBadScan,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: Text(l?.reportScanError ?? 'Report scan error'),
          ),
        ],
      ],
    );
  }
}
