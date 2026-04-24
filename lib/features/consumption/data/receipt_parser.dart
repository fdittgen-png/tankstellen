import '../../search/domain/entities/fuel_type.dart';
import 'receipt_override_registry.dart';
import 'receipt_parser/brand_detection.dart';
import 'receipt_parser/brand_layouts.dart';
import 'receipt_parser/receipt_field_extractors.dart';
import 'receipt_parser/receipt_parse_result.dart';

// Re-export the result type so every existing caller that does
// `import 'receipt_parser.dart'` continues to see `ReceiptParseResult`
// without touching its own import list (#563 phase: file split only).
export 'receipt_parser/receipt_parse_result.dart' show ReceiptParseResult;

/// Parses raw OCR text from a fuel station receipt into a
/// [ReceiptParseResult].
///
/// Dispatches to brand-aware rules when the first lines match a known
/// retailer (Super U, Carrefour today — more as we collect samples) and
/// falls back to a best-effort generic matcher otherwise. The generic
/// matcher covers common French / German layouts (TOTAL / MONTANT /
/// BETRAG + Volume / Quantité + Prix/L / Literpreis).
class ReceiptParser {
  /// Optional per-station override registry (phase 1 of #759). `null`
  /// disables override dispatch — the parser behaves exactly as before.
  final ReceiptOverrideRegistry? _overrideRegistry;

  const ReceiptParser({ReceiptOverrideRegistry? overrideRegistry})
      : _overrideRegistry = overrideRegistry;

  /// Parse OCR [text] from a fuel receipt and return the extracted fields.
  ///
  /// The result is always non-null; check [ReceiptParseResult.hasData] to
  /// know whether the parser recognised anything useful.
  ///
  /// When [stationId] is provided and an [ReceiptOverrideRegistry] is
  /// wired up, every non-null field on the matching [OverrideSpec] wins
  /// over the brand-layout default. Overrides only replace values — they
  /// can't force `null` where the brand layout found something. The
  /// reconciliation guard (`liters × pricePerLiter ≈ totalCost`) runs
  /// AFTER overrides so a bad regex combo falls back gracefully.
  ReceiptParseResult parse(String text, {String? stationId}) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final fullText = lines.join(' ');

    final brand = detectBrand(lines, fullText);
    final initial = switch (brand) {
      'super_u' => parseSuperU(fullText, lines),
      'carrefour' => parseCarrefour(fullText, lines),
      _ => parseGeneric(fullText, lines),
    };

    final withOverrides = _applyOverrides(initial, text, stationId);
    return reconcile(withOverrides);
  }

  /// Apply per-station overrides on top of the brand-layout result. Any
  /// non-null field on the matching [OverrideSpec] replaces the default.
  /// If the override's regex doesn't match, the brand layout's value
  /// survives — an unmatched override is never worse than no override.
  ReceiptParseResult _applyOverrides(
    ReceiptParseResult result,
    String text,
    String? stationId,
  ) {
    if (stationId == null) return result;
    final registry = _overrideRegistry;
    if (registry == null) return result;
    final spec = registry.lookup(stationId);
    if (spec == null) return result;

    double? liters = result.liters;
    double? totalCost = result.totalCost;
    double? pricePerLiter = result.pricePerLiter;
    DateTime? date = result.date;
    String? stationName = result.stationName;
    FuelType? fuelType = result.fuelType;

    final overrideLiters = _overrideDecimal(spec.liters, text);
    if (overrideLiters != null) liters = overrideLiters;

    final overrideTotal = _overrideDecimal(spec.totalCost, text);
    if (overrideTotal != null) totalCost = overrideTotal;

    final overridePpl = _overrideDecimal(spec.pricePerLiter, text);
    if (overridePpl != null) pricePerLiter = overridePpl;

    final overrideDateRaw = spec.date?.extract(text);
    if (overrideDateRaw != null) {
      // Delegate to the generic extractor so 2-digit years, "-"/"/" /
      // "." separators all work exactly the way they do elsewhere.
      final parsed = extractDate(overrideDateRaw);
      if (parsed != null) date = parsed;
    }

    final overrideStationName = spec.stationName?.extract(text);
    if (overrideStationName != null && overrideStationName.isNotEmpty) {
      stationName = overrideStationName;
    }

    final overrideFuel = spec.fuelType?.extract(text);
    if (overrideFuel != null && overrideFuel.isNotEmpty) {
      final mapped = extractFuelType(overrideFuel);
      if (mapped != null) fuelType = mapped;
    }

    return ReceiptParseResult(
      liters: liters,
      totalCost: totalCost,
      pricePerLiter: pricePerLiter,
      date: date,
      stationName: stationName,
      fuelType: fuelType,
      brandLayout: result.brandLayout,
    );
  }

  /// Extract and decimal-parse a captured group from [field] against
  /// [text]. Returns `null` if the group misses or isn't a decimal.
  double? _overrideDecimal(OverrideFieldSpec? field, String text) {
    if (field == null) return null;
    final raw = field.extract(text);
    if (raw == null) return null;
    return parseDecimal(raw);
  }
}
