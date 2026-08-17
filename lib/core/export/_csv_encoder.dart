// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// RFC 4180 CSV encoder used by [DataExporter].
///
/// Kept as a sibling helper (private to the package via the leading
/// underscore filename convention) to keep `data_exporter.dart` focused
/// on the per-category serialization logic.
library;

/// Encodes a list of rows into an RFC 4180 CSV string.
///
/// - Uses `,` separator and `\r\n` line ending (Excel-friendly).
/// - Wraps fields in `"` when they contain `,`, `"`, `\r`, or `\n`.
/// - Doubles embedded `"` characters inside quoted fields.
/// - `null` renders as an empty cell.
/// - #3740 — defuses spreadsheet formula injection (OWASP CSV injection):
///   a **text** cell starting with `=`, `+`, `-`, `@`, tab, or CR is
///   prefixed with `'` so Excel/LibreOffice render it as literal text
///   instead of executing it (attacker-controlled station names flow into
///   the GDPR export verbatim). Numeric/bool cells are exempt — they
///   cannot carry a formula, and prefixing would corrupt negative numbers
///   (e.g. western-hemisphere longitudes).
String encodeCsv(List<List<Object?>> rows) {
  final buf = StringBuffer();
  for (final row in rows) {
    for (var i = 0; i < row.length; i++) {
      if (i > 0) buf.write(',');
      buf.write(_encodeCell(row[i]));
    }
    buf.write('\r\n');
  }
  return buf.toString();
}

/// Leading characters a spreadsheet interprets as the start of a formula
/// (OWASP CSV-injection set): `=`, `+`, `-`, `@`, tab, carriage return.
const _formulaTriggers = {'=', '+', '-', '@', '\t', '\r'};

String _encodeCell(Object? value) {
  if (value == null) return '';
  var s = value.toString();
  // #3740 — formula-injection defusal for text cells only (see encodeCsv
  // doc). Applied BEFORE the quoting decision so a defused `\t`/`\r`
  // trigger still gets quoted below when required.
  if (value is! num &&
      value is! bool &&
      s.isNotEmpty &&
      _formulaTriggers.contains(s[0])) {
    s = "'$s";
  }
  final needsQuoting = s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r');
  if (!needsQuoting) return s;
  return '"${s.replaceAll('"', '""')}"';
}
