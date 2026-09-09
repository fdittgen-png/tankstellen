// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../core/utils/unit_formatter.dart';
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

/// Placeholder for a field the scan (or the user) left empty.
const String _kMissing = '—';

/// A displayed figure, in the reader's number format (#3996).
///
/// This is the DISPLAY path, unlike [buildBadScanShareBody] and
/// [buildBadScanParsedFields] below: the diff table is a Table the user
/// reads, so its numbers follow the same locale rules as every other
/// figure in the app. Comparing "what the scan read" with "what I
/// typed" only works if both are written the way the reader writes
/// numbers.
String _shown(double? value, int fractionDigits) => value == null
    ? _kMissing
    : UnitFormatter.formatDecimal(value, fractionDigits: fractionDigits);

/// Builds the field-by-field diff table rendered above the action
/// buttons: the rich receipt layout (brand, station, fuel, date).
///
/// [locale] is the UI locale (`Localizations.localeOf(context)
/// .toString()`) — this function stays pure, so the caller reads it.
List<BadScanDiffRow> buildBadScanDiffRows({
  required ReceiptScanOutcome? receiptScan,
  required double? enteredLiters,
  required double? enteredTotalCost,
  required AppLocalizations l,
  required String locale,
}) {
  final p = receiptScan!.parse;
  final date = p.date;
  return [
    BadScanDiffRow(
      l.badScanReportFieldBrandLayout,
      p.brandLayout,
      p.brandLayout,
    ),
    BadScanDiffRow(l.liters, _shown(p.liters, 2), _shown(enteredLiters, 2)),
    BadScanDiffRow(
      l.badScanReportFieldTotal,
      _shown(p.totalCost, 2),
      _shown(enteredTotalCost, 2),
    ),
    BadScanDiffRow(
      l.badScanReportFieldPricePerLiter,
      _shown(p.pricePerLiter, 3),
      _kMissing,
    ),
    BadScanDiffRow(
      l.badScanReportFieldStation,
      p.stationName ?? _kMissing,
      _kMissing,
    ),
    BadScanDiffRow(
      l.badScanReportFieldFuel,
      p.fuelType?.displayName ?? _kMissing,
      _kMissing,
    ),
    BadScanDiffRow(
      l.badScanReportFieldDate,
      // The ISO date stays in the PAYLOAD builders; here the reader
      // gets their own date format.
      date == null
          ? _kMissing
          : UnitFormatter.formatMediumDate(date, locale: locale),
      _kMissing,
    ),
  ];
}

/// Builds the multi-line plaintext body shipped via the SharePlus
/// fallback when GitHub submission is not available (no PAT
/// configured, consent denied, network failure). Mirrors the diff
/// table rows but in a format that survives the system share sheet.
String buildBadScanShareBody({
  required ReceiptScanOutcome? receiptScan,
  required double? enteredLiters,
  required double? enteredTotalCost,
  required String appVersion,
  required String ocrText,
}) {
  final buffer = StringBuffer();
  final p = receiptScan!.parse;
  buffer
    ..writeln('Sparkilo receipt scan report')
    ..writeln('================================')
    ..writeln('App version: $appVersion')
    ..writeln('Brand layout: ${p.brandLayout}')
    ..writeln()
    ..writeln('Scanned → Corrected')
    ..writeln('-------------------')
    ..writeln(
      // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
      'Liters:   ${p.liters?.toStringAsFixed(2) ?? '—'}'
      // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
      '   →   ${enteredLiters?.toStringAsFixed(2) ?? '(please fill)'}',
    )
    ..writeln(
      // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
      'Total:    ${p.totalCost?.toStringAsFixed(2) ?? '—'}'
      // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
      '   →   ${enteredTotalCost?.toStringAsFixed(2) ?? '(please fill)'}',
    )
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    ..writeln('Price/L:  ${p.pricePerLiter?.toStringAsFixed(3) ?? '—'}')
    ..writeln('Station:  ${p.stationName ?? '—'}')
    ..writeln('Fuel:     ${p.fuelType?.apiValue ?? '—'}')
    ..writeln('Date:     ${p.date?.toIso8601String() ?? '—'}');
  buffer
    ..writeln()
    ..writeln('Raw OCR text')
    ..writeln('------------')
    ..writeln(ocrText);
  return buffer.toString();
}

/// Builds the structured `parsedFields` map handed to
/// [GithubIssueReporter.reportBadScan]; the reporter encodes it into
/// the issue body.
Map<String, String?> buildBadScanParsedFields({
  required ReceiptScanOutcome? receiptScan,
}) {
  final p = receiptScan!.parse;
  return <String, String?>{
    'brandLayout': p.brandLayout,
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    'liters': p.liters?.toStringAsFixed(2),
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    'totalCost': p.totalCost?.toStringAsFixed(2),
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    'pricePerLiter': p.pricePerLiter?.toStringAsFixed(3),
    'stationName': p.stationName,
    'fuelType': p.fuelType?.apiValue,
    'date': p.date?.toIso8601String(),
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
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    'liters': enteredLiters?.toStringAsFixed(2),
    // i18n-ignore-format: developer-facing bad-scan report payload — machine-readable dot decimals
    'totalCost': enteredTotalCost?.toStringAsFixed(2),
  };
}

/// Resolves the kind-aware sheet title. Falls back to the original
/// "Report a scan error" string for both kinds when localization is
/// not available, then layers per-kind suffixes on top via the
/// kind-specific keys (#953).
String resolveBadScanTitle(ScanKind kind, AppLocalizations l) {
  switch (kind) {
    case ScanKind.receipt:
      return l.badScanReportTitleReceipt;
  }
}
