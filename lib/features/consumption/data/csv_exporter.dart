import '../domain/entities/fill_up.dart';
import '../../search/domain/entities/fuel_type.dart';

/// Serializes a list of [FillUp] records into a spreadsheet-friendly CSV.
///
/// Used by the consumption screen "Export CSV" action. Output is a UTF-8
/// string with a header row followed by one data row per fill-up, sorted
/// oldest-first so power users can chart trends without re-sorting.
///
/// The format is deliberately conservative:
/// - Period (`.`) as the decimal separator for Excel/LibreOffice compatibility
/// - ISO-8601 dates (`YYYY-MM-DD HH:MM:SS`) — sortable as text
/// - Comma delimiter with RFC 4180 quoting (fields containing commas,
///   quotes, or newlines are wrapped in double quotes; internal quotes
///   are doubled)
class ConsumptionCsvExporter {
  static const List<String> headers = [
    'Date',
    'Station',
    'Fuel Type',
    'Liters',
    'Price per Liter',
    'Total Cost',
    'Odometer (km)',
    'CO2 (kg)',
    'Notes',
  ];

  /// Renders [fillUps] as a CSV string (header + data rows).
  ///
  /// An empty input returns just the header row (so the file is still
  /// valid and self-describing).
  static String toCsv(List<FillUp> fillUps) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escape).join(','));

    final sorted = List<FillUp>.from(fillUps)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final f in sorted) {
      buffer.writeln([
        _formatDate(f.date),
        f.stationName ?? '',
        _fuelTypeLabel(f.fuelType),
        _formatNumber(f.liters, 3),
        _formatNumber(f.pricePerLiter, 3),
        _formatNumber(f.totalCost, 2),
        _formatNumber(f.odometerKm, 1),
        _formatNumber(f.co2Kg, 2),
        f.notes ?? '',
      ].map(_escape).join(','));
    }

    return buffer.toString();
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  static String _formatNumber(double v, int decimals) =>
      v.toStringAsFixed(decimals);

  static String _fuelTypeLabel(FuelType t) => t.apiValue;

  /// RFC 4180 field escaping: wrap in quotes if the field contains the
  /// delimiter, a quote, or a line break; double any embedded quotes.
  static String _escape(String field) {
    final needsQuoting =
        field.contains(',') || field.contains('"') || field.contains('\n');
    if (!needsQuoting) return field;
    return '"${field.replaceAll('"', '""')}"';
  }
}
