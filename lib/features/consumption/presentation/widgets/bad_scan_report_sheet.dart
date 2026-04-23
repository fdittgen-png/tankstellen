import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';

/// Bottom sheet the user opens when the scanned receipt values are
/// wrong. Shows a side-by-side of the scanned fields vs. the form's
/// current values (which the user has typed by hand), and shares a
/// pre-filled report via the system share sheet so the user can send
/// it to GitHub Mobile / email / wherever.
///
/// The receipt photo is attached as an [XFile] so the share sheet
/// delivers both text + image in a single intent. The next build of
/// the app can use the report to tighten the parser without the user
/// having to describe the layout from memory (#713).
class BadScanReportSheet extends StatelessWidget {
  final ReceiptScanOutcome scan;
  final double? enteredLiters;
  final double? enteredTotalCost;
  final String appVersion;

  const BadScanReportSheet({
    super.key,
    required this.scan,
    required this.enteredLiters,
    required this.enteredTotalCost,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final p = scan.parse;
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
              l?.badScanReportTitle ?? 'Report a scan error',
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
            _DiffTable(
              rows: [
                _DiffRow(
                  l?.badScanReportFieldBrandLayout ?? 'Brand layout',
                  p.brandLayout,
                  p.brandLayout,
                ),
                _DiffRow(
                  l?.liters ?? 'Liters',
                  p.liters?.toStringAsFixed(2) ?? '—',
                  enteredLiters?.toStringAsFixed(2) ?? '—',
                ),
                _DiffRow(
                  l?.badScanReportFieldTotal ?? 'Total',
                  p.totalCost?.toStringAsFixed(2) ?? '—',
                  enteredTotalCost?.toStringAsFixed(2) ?? '—',
                ),
                _DiffRow(
                  l?.badScanReportFieldPricePerLiter ?? 'Price/L',
                  p.pricePerLiter?.toStringAsFixed(3) ?? '—',
                  '—',
                ),
                _DiffRow(
                  l?.badScanReportFieldStation ?? 'Station',
                  p.stationName ?? '—',
                  '—',
                ),
                _DiffRow(
                  l?.badScanReportFieldFuel ?? 'Fuel',
                  p.fuelType?.displayName ?? '—',
                  '—',
                ),
                _DiffRow(
                  l?.badScanReportFieldDate ?? 'Date',
                  p.date?.toIso8601String().split('T').first ?? '—',
                  '—',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _share();
              },
              icon: const Icon(Icons.send),
              label: Text(
                l?.badScanReportShareAction ?? 'Share report + photo',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l?.cancel ?? 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    final p = scan.parse;
    final buffer = StringBuffer()
      ..writeln('Tankstellen receipt scan report')
      ..writeln('================================')
      ..writeln('App version: $appVersion')
      ..writeln('Brand layout: ${p.brandLayout}')
      ..writeln()
      ..writeln('Scanned → Corrected')
      ..writeln('-------------------')
      ..writeln('Liters:   ${p.liters?.toStringAsFixed(2) ?? '—'}'
          '   →   ${enteredLiters?.toStringAsFixed(2) ?? '(please fill)'}')
      ..writeln('Total:    ${p.totalCost?.toStringAsFixed(2) ?? '—'}'
          '   →   ${enteredTotalCost?.toStringAsFixed(2) ?? '(please fill)'}')
      ..writeln('Price/L:  ${p.pricePerLiter?.toStringAsFixed(3) ?? '—'}')
      ..writeln('Station:  ${p.stationName ?? '—'}')
      ..writeln('Fuel:     ${p.fuelType?.apiValue ?? '—'}')
      ..writeln('Date:     ${p.date?.toIso8601String() ?? '—'}')
      ..writeln()
      ..writeln('Raw OCR text')
      ..writeln('------------')
      ..writeln(scan.ocrText);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(scan.imagePath)],
        text: buffer.toString(),
        subject: 'Tankstellen receipt scan issue',
      ),
    );
  }
}

class _DiffRow {
  final String label;
  final String scanned;
  final String real;
  const _DiffRow(this.label, this.scanned, this.real);
}

class _DiffTable extends StatelessWidget {
  final List<_DiffRow> rows;
  const _DiffTable({required this.rows});

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
