import 'package:flutter/material.dart';

import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';
import 'bad_scan_diff_table.dart';
import 'bad_scan_report_formatters.dart';

/// Pre-submission view of [BadScanReportSheet]: title + hint + diff
/// table + the "Create issue" / "Cancel" action pair. Pulled out of
/// the parent so the parent's `build()` method only has to choose
/// between this and [BadScanIssueCreatedSurface] depending on whether
/// a GitHub issue URL is already in hand.
class BadScanFormView extends StatelessWidget {
  final ScanKind kind;
  final ReceiptScanOutcome? receiptScan;
  final PumpDisplayScanOutcome? pumpScan;
  final double? enteredLiters;
  final double? enteredTotalCost;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const BadScanFormView({
    super.key,
    required this.kind,
    required this.receiptScan,
    required this.pumpScan,
    required this.enteredLiters,
    required this.enteredTotalCost,
    required this.submitting,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          resolveBadScanTitle(kind, l),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l?.badScanReportHint ??
              "We'll share the receipt photo and both sets of values so "
                  'the next build can learn this layout.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        BadScanDiffTable(
          rows: buildBadScanDiffRows(
            kind: kind,
            receiptScan: receiptScan,
            pumpScan: pumpScan,
            enteredLiters: enteredLiters,
            enteredTotalCost: enteredTotalCost,
            l: l,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.bug_report_outlined),
          label: Text(
            l?.badScanReportCreateTicket ?? 'Create issue',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: submitting ? null : onCancel,
          child: Text(l?.cancel ?? 'Cancel'),
        ),
      ],
    );
  }
}
