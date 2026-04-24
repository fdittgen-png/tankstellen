import 'brand_detection.dart';
import 'receipt_field_extractors.dart';
import 'receipt_parse_result.dart';

// Per-brand dispatch + cross-field reconciliation. These functions
// compose the pure extractors from `receipt_field_extractors.dart`
// into a `ReceiptParseResult`. Split out of `ReceiptParser` so each
// layout is independently readable + unit-testable.

/// Super U / Système U layout. Labels observed on real receipts:
///   Volume   5.24 L
///   Prix     € 1.999/L
///   TOT TTC  € 10.47
ReceiptParseResult parseSuperU(String text, List<String> lines) {
  return ReceiptParseResult(
    liters: extractLiters(text),
    totalCost: matchFirst(text, [
      RegExp(r'tot\s*ttc\s*:?\s*€?\s*(\d+[.,]\d+)', caseSensitive: false),
      RegExp(r'total\s*ttc\s*:?\s*€?\s*(\d+[.,]\d+)', caseSensitive: false),
    ]) ?? extractTotalCost(text),
    pricePerLiter: extractPricePerLiter(text),
    date: extractDate(text),
    stationName: extractStationName(lines),
    fuelType: extractFuelType(text),
    brandLayout: 'super_u',
  );
}

/// Carrefour / Carrefour Market / Carrefour Express layout. Observed:
///   No pompe    = 6
///   Carburant   = SP95
///   Quantite    = 5.27 L
///   Prix unit.  = 2,028 EUR
///   MONTANT REEL : 10.69 EUR
ReceiptParseResult parseCarrefour(String text, List<String> lines) {
  return ReceiptParseResult(
    liters: matchFirst(text, [
      RegExp(r'quantit[eé]\s*[:=]\s*(\d+[.,]\d+)', caseSensitive: false),
    ]) ?? extractLiters(text),
    totalCost: matchFirst(text, [
      RegExp(r'montant\s*(?:reel|r[eé]el|ttc)?\s*[:=]?\s*€?\s*(\d+[.,]\d+)',
          caseSensitive: false),
    ]) ?? extractTotalCost(text),
    pricePerLiter: matchFirst(text, [
      RegExp(r'prix\s*unit\.?\s*[:=]?\s*€?\s*(\d+[.,]\d{2,3})',
          caseSensitive: false),
    ]) ?? extractPricePerLiter(text),
    date: extractDate(text),
    stationName: extractStationName(lines),
    fuelType: extractFuelType(text),
    brandLayout: 'carrefour',
  );
}

/// Generic fallback — everything that isn't a known retailer.
ReceiptParseResult parseGeneric(String text, List<String> lines) {
  return ReceiptParseResult(
    liters: extractLiters(text),
    totalCost: extractTotalCost(text),
    pricePerLiter: extractPricePerLiter(text),
    date: extractDate(text),
    stationName: extractStationName(lines),
    fuelType: extractFuelType(text),
  );
}

// ---------------------------------------------------------------------------
// Cross-field reconciliation
// ---------------------------------------------------------------------------

/// Enforce the `liters × pricePerLiter ≈ totalCost` invariant. OCR
/// routinely loses one of the three, and sometimes grabs the unit
/// price as the total (the "2 €" vs "10.47 €" bug on a column-layout
/// Super U receipt). Post-process so:
///
/// - any two known values derive the third;
/// - when all three are known but the product check disagrees by
///   more than 15 %, trust the PAIR that agrees (the two biggest
///   hints: total + pricePerLiter are most often correct from the
///   label regex, so liters gets recomputed);
/// - nothing is overwritten when only one field is known.
ReceiptParseResult reconcile(ReceiptParseResult r) {
  final liters = r.liters;
  final total = r.totalCost;
  final ppl = r.pricePerLiter;

  // Fill in any single missing field from the other two.
  if (liters == null && total != null && ppl != null && ppl > 0) {
    return _copyWith(r, liters: _round(total / ppl, 2));
  }
  if (total == null && liters != null && ppl != null) {
    return _copyWith(r, totalCost: _round(liters * ppl, 2));
  }
  if (ppl == null && liters != null && total != null && liters > 0) {
    return _copyWith(r, pricePerLiter: _round(total / liters, 3));
  }

  // All three known: sanity-check their product. OCR's most common
  // mistake is grabbing the unit price as the total (€ 1.999 instead
  // of € 10.47), which blows this check by an order of magnitude.
  if (liters != null && total != null && ppl != null) {
    final expected = liters * ppl;
    if (expected > 0 && (total - expected).abs() / expected > 0.15) {
      // Trust the larger-signal pair. pricePerLiter comes from a
      // label with a "/L" marker — very reliable. liters comes from
      // an "X L" suffix — reliable too. Recompute the total.
      return _copyWith(r, totalCost: _round(expected, 2));
    }
  }
  return r;
}

ReceiptParseResult _copyWith(
  ReceiptParseResult r, {
  double? liters,
  double? totalCost,
  double? pricePerLiter,
}) {
  return ReceiptParseResult(
    liters: liters ?? r.liters,
    totalCost: totalCost ?? r.totalCost,
    pricePerLiter: pricePerLiter ?? r.pricePerLiter,
    date: r.date,
    stationName: r.stationName,
    fuelType: r.fuelType,
    brandLayout: r.brandLayout,
  );
}

double _round(double value, int digits) {
  const pow10 = [1, 10, 100, 1000];
  final p = pow10[digits.clamp(0, pow10.length - 1)];
  return (value * p).round() / p;
}
