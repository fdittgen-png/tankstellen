import '../../../search/domain/entities/fuel_type.dart';

/// Structured fields extracted from a fuel receipt by `ReceiptParser`.
///
/// All fields are nullable because OCR is best-effort: any combination
/// may be missing depending on the receipt layout. Use [hasData] to check
/// whether the parser found anything actionable.
class ReceiptParseResult {
  /// Volume dispensed in litres, or `null` if no volume could be parsed.
  final double? liters;

  /// Total amount charged (currency is implicit — typically EUR).
  final double? totalCost;

  /// Unit price per litre as printed on the receipt.
  final double? pricePerLiter;

  /// Receipt date if a recognised format was found.
  final DateTime? date;

  /// Detected station brand (matched against a small built-in list).
  final String? stationName;

  /// Detected fuel type from the receipt, e.g. "SP95-E10" → [FuelType.e10].
  /// Null when the receipt doesn't name a recognisable product.
  final FuelType? fuelType;

  /// Brand layout the parser used — "super_u", "carrefour", or "generic".
  /// Exposed so tests and telemetry can verify dispatch went to the
  /// specialised branch when a well-known receipt layout is scanned.
  final String brandLayout;

  const ReceiptParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.date,
    this.stationName,
    this.fuelType,
    this.brandLayout = 'generic',
  });

  /// `true` when the parser extracted at least volume or total cost.
  bool get hasData => liters != null || totalCost != null;
}
