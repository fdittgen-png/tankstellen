import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Single row of the diff table rendered above the action buttons in
/// [BadScanReportSheet]. Captures the field label, the OCR-scanned
/// value, and the value the user typed by hand.
@immutable
class BadScanDiffRow {
  final String label;
  final String scanned;
  final String real;
  const BadScanDiffRow(this.label, this.scanned, this.real);
}

/// Field-by-field comparison of OCR output vs. user-entered values.
/// Receipt and pump-display flows feed it different rows; the widget
/// itself is kind-agnostic.
class BadScanDiffTable extends StatelessWidget {
  final List<BadScanDiffRow> rows;
  const BadScanDiffTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration:
              BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          children: [
            _cell(l?.badScanReportHeaderField ?? 'Field',
                bold: true, theme: theme),
            _cell(l?.badScanReportHeaderScanned ?? 'Scanned',
                bold: true, theme: theme),
            _cell(l?.badScanReportHeaderYouTyped ?? 'You typed',
                bold: true, theme: theme),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _cell(row.label, theme: theme),
              _cell(row.scanned, theme: theme),
              _cell(row.real, theme: theme),
            ],
          ),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
        ),
      ),
    );
  }
}
