import 'dart:convert';

/// Shared CSV parsing utility for services that download bulk datasets
/// (MISE Italy, Argentina).
///
/// Eliminates duplicated CSV line splitting and field extraction code.
class CsvParser {
  CsvParser._();

  /// Parse a CSV line handling quoted fields.
  /// Handles: "field1","field with, comma","field3"
  static List<String> parseLine(String line, {String separator = ','}) {
    if (!line.contains('"')) {
      return line.split(separator).map((s) => s.trim()).toList();
    }

    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == separator[0] && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  /// Parse entire CSV string into rows, skipping header lines.
  static List<List<String>> parseAll(
    String csv, {
    int skipLines = 1,
    String separator = ',',
  }) {
    final lines = const LineSplitter().convert(csv);
    final rows = <List<String>>[];
    for (var i = skipLines; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      rows.add(parseLine(lines[i], separator: separator));
    }
    return rows;
  }

  /// Parse a number string that uses comma as decimal separator.
  /// "1,817" → 1.817, "" → null
  static double? parseCommaDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }
}
