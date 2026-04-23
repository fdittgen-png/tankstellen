/// Fields extracted from a fuel pump display (the 7-segment / LCD
/// panel on the pump itself, NOT the paper receipt).
///
/// All fields are nullable because OCR is best-effort: bright
/// sunlight, glare, a partially-visible display, or an unfamiliar
/// layout can all blank a field. Use [hasUsableData] to decide
/// whether the result is worth prefilling a form with.
class PumpDisplayParseResult {
  /// Volume dispensed in litres (the "Abgabe" / "Volume" line).
  final double? liters;

  /// Total amount charged on the pump (the "Betrag" / "€" line).
  final double? totalCost;

  /// Unit price per litre as shown on the pump (the "Preis/Liter" /
  /// "€/L" line). This is typically 3-decimal precision (e.g. 1.849).
  final double? pricePerLiter;

  /// Pump number printed or displayed on the housing (e.g. "3" in a
  /// large standalone digit on the cabinet). Optional — helps the
  /// user confirm which pump they scanned.
  final int? pumpNumber;

  /// Confidence ∈ [0, 1] based on how many of the three primary
  /// fields were extracted AND whether they are internally consistent
  /// (totalCost ≈ liters * pricePerLiter within tolerance).
  final double confidence;

  const PumpDisplayParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.pumpNumber,
    this.confidence = 0,
  });

  /// `true` when the parser extracted at least two of the three
  /// primary numeric fields. One alone (e.g. just a total) is rarely
  /// enough to auto-fill a fill-up log.
  bool get hasUsableData {
    final count = [liters, totalCost, pricePerLiter]
        .where((v) => v != null)
        .length;
    return count >= 2;
  }

  /// `true` when totalCost, liters and pricePerLiter are all present
  /// AND they satisfy `totalCost ≈ liters * pricePerLiter` within a
  /// small rounding tolerance. The three-way agreement is the
  /// strongest signal that OCR actually read the right numbers.
  bool get isConsistent {
    if (liters == null || totalCost == null || pricePerLiter == null) {
      return false;
    }
    final predicted = liters! * pricePerLiter!;
    final delta = (predicted - totalCost!).abs();
    // Pump displays round to the cent. A 2 cent tolerance covers
    // the rounding plus small OCR jitter on the last digit.
    return delta <= 0.02;
  }
}
