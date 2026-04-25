import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';
import 'bad_scan_diff_table.dart';

/// Pure formatting helpers split out of [BadScanReportSheet]. Keeping
/// them as top-level functions (rather than methods on the
/// `_BadScanReportSheetState`) makes the rendering side of the sheet
/// easier to read and trivially unit-testable in isolation.
///
/// Functions in this file MUST stay pure — no `BuildContext`, no
/// reading provider state. They only consume the scan outcome the
/// caller already holds plus the user-entered values.

/// Builds the field-by-field diff table rendered above the action
/// buttons. Receipt shows the rich layout (brand, station, fuel,
/// date); pump-display shows only the three transaction numbers
/// plus the pump number when available (#953).
List<BadScanDiffRow> buildBadScanDiffRows({
  required ScanKind kind,
  required ReceiptScanOutcome? receiptScan,
  required PumpDisplayScanOutcome? pumpScan,
  required double? enteredLiters,
  required double? enteredTotalCost,
  required AppLocalizations? l,
}) {
  if (kind == ScanKind.receipt) {
    final p = receiptScan!.parse;
    return [
      BadScanDiffRow(
        l?.badScanReportFieldBrandLayout ?? 'Brand layout',
        p.brandLayout,
        p.brandLayout,
      ),
      BadScanDiffRow(
        l?.liters ?? 'Liters',
        p.liters?.toStringAsFixed(2) ?? '—',
        enteredLiters?.toStringAsFixed(2) ?? '—',
      ),
      BadScanDiffRow(
        l?.badScanReportFieldTotal ?? 'Total',
        p.totalCost?.toStringAsFixed(2) ?? '—',
        enteredTotalCost?.toStringAsFixed(2) ?? '—',
      ),
      BadScanDiffRow(
        l?.badScanReportFieldPricePerLiter ?? 'Price/L',
        p.pricePerLiter?.toStringAsFixed(3) ?? '—',
        '—',
      ),
      BadScanDiffRow(
        l?.badScanReportFieldStation ?? 'Station',
        p.stationName ?? '—',
        '—',
      ),
      BadScanDiffRow(
        l?.badScanReportFieldFuel ?? 'Fuel',
        p.fuelType?.displayName ?? '—',
        '—',
      ),
      BadScanDiffRow(
        l?.badScanReportFieldDate ?? 'Date',
        p.date?.toIso8601String().split('T').first ?? '—',
        '—',
      ),
    ];
  }
  final p = pumpScan!.parse;
  return [
    BadScanDiffRow(
      l?.liters ?? 'Liters',
      p.liters?.toStringAsFixed(2) ?? '—',
      enteredLiters?.toStringAsFixed(2) ?? '—',
    ),
    BadScanDiffRow(
      l?.badScanReportFieldTotal ?? 'Total',
      p.totalCost?.toStringAsFixed(2) ?? '—',
      enteredTotalCost?.toStringAsFixed(2) ?? '—',
    ),
    BadScanDiffRow(
      l?.badScanReportFieldPricePerLiter ?? 'Price/L',
      p.pricePerLiter?.toStringAsFixed(3) ?? '—',
      '—',
    ),
  ];
}

/// Builds the multi-line plaintext body shipped via the SharePlus
/// fallback when GitHub submission is not available (no PAT
/// configured, consent denied, network failure). Mirrors the diff
/// table rows but in a format that survives the system share sheet.
String buildBadScanShareBody({
  required ScanKind kind,
  required ReceiptScanOutcome? receiptScan,
  required PumpDisplayScanOutcome? pumpScan,
  required double? enteredLiters,
  required double? enteredTotalCost,
  required String appVersion,
  required String ocrText,
}) {
  final buffer = StringBuffer();
  if (kind == ScanKind.receipt) {
    final p = receiptScan!.parse;
    buffer
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
      ..writeln('Date:     ${p.date?.toIso8601String() ?? '—'}');
  } else {
    final p = pumpScan!.parse;
    buffer
      ..writeln('Tankstellen pump-display scan report')
      ..writeln('=====================================')
      ..writeln('App version: $appVersion')
      ..writeln()
      ..writeln('Scanned → Corrected')
      ..writeln('-------------------')
      ..writeln('Liters:   ${p.liters?.toStringAsFixed(2) ?? '—'}'
          '   →   ${enteredLiters?.toStringAsFixed(2) ?? '(please fill)'}')
      ..writeln('Total:    ${p.totalCost?.toStringAsFixed(2) ?? '—'}'
          '   →   ${enteredTotalCost?.toStringAsFixed(2) ?? '(please fill)'}')
      ..writeln('Price/L:  ${p.pricePerLiter?.toStringAsFixed(3) ?? '—'}')
      ..writeln('Pump #:   ${p.pumpNumber?.toString() ?? '—'}')
      ..writeln('Confidence: ${p.confidence.toStringAsFixed(2)}');
  }
  buffer
    ..writeln()
    ..writeln('Raw OCR text')
    ..writeln('------------')
    ..writeln(ocrText);
  return buffer.toString();
}

/// Builds the structured `parsedFields` map handed to
/// [GithubIssueReporter.reportBadScan]. Receipt and pump-display
/// flows ship different keys; the reporter encodes them into the
/// issue body.
Map<String, String?> buildBadScanParsedFields({
  required ScanKind kind,
  required ReceiptScanOutcome? receiptScan,
  required PumpDisplayScanOutcome? pumpScan,
}) {
  if (kind == ScanKind.receipt) {
    final p = receiptScan!.parse;
    return <String, String?>{
      'brandLayout': p.brandLayout,
      'liters': p.liters?.toStringAsFixed(2),
      'totalCost': p.totalCost?.toStringAsFixed(2),
      'pricePerLiter': p.pricePerLiter?.toStringAsFixed(3),
      'stationName': p.stationName,
      'fuelType': p.fuelType?.apiValue,
      'date': p.date?.toIso8601String(),
    };
  }
  final p = pumpScan!.parse;
  return <String, String?>{
    'liters': p.liters?.toStringAsFixed(2),
    'totalCost': p.totalCost?.toStringAsFixed(2),
    'pricePerLiter': p.pricePerLiter?.toStringAsFixed(3),
    'pumpNumber': p.pumpNumber?.toString(),
    'confidence': p.confidence.toStringAsFixed(2),
  };
}

/// Builds the `userCorrections` map handed to
/// [GithubIssueReporter.reportBadScan]. Same shape across both kinds:
/// only the two transaction numbers the user can re-type.
Map<String, String?> buildBadScanUserCorrections({
  required double? enteredLiters,
  required double? enteredTotalCost,
}) {
  return <String, String?>{
    'liters': enteredLiters?.toStringAsFixed(2),
    'totalCost': enteredTotalCost?.toStringAsFixed(2),
  };
}

/// Resolves the kind-aware sheet title. Falls back to the original
/// "Report a scan error" string for both kinds when localization is
/// not available, then layers per-kind suffixes on top via the
/// kind-specific keys (#953).
String resolveBadScanTitle(ScanKind kind, AppLocalizations? l) {
  switch (kind) {
    case ScanKind.receipt:
      return l?.badScanReportTitleReceipt ??
          l?.badScanReportTitle ??
          'Report a scan error — Receipt';
    case ScanKind.pumpDisplay:
      return l?.badScanReportTitlePumpDisplay ??
          'Report a scan error — Pump display';
  }
}
