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

String _encodeCell(Object? value) {
  if (value == null) return '';
  final s = value.toString();
  final needsQuoting = s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r');
  if (!needsQuoting) return s;
  return '"${s.replaceAll('"', '""')}"';
}
