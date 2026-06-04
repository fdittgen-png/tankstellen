// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../search/domain/entities/fuel_type.dart';
import 'ocr/ocr_trace_recorder.dart';
import 'ocr/pump_ocr_config.dart';
import 'ocr/pump_validation_gate.dart';
import 'ocr/recognized_text_block.dart';
import 'receipt_override_registry.dart';
import 'receipt_parser/brand_detection.dart';
import 'receipt_parser/brand_layouts.dart';
import 'receipt_parser/receipt_field_extractors.dart';
import 'receipt_parser/receipt_orchestrator.dart';
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
  ///
  /// #2273 — when [profile] is supplied (the active country's
  /// [OcrLocaleProfile], threaded from [PumpOcrConfig] by
  /// [ReceiptScanService]) the currency-aware field extractors read
  /// totals/prices in that country's currency (GBP/£/p, kr, $, …). With
  /// no [profile] the parser defaults to EUR, unchanged from before.
  ReceiptParseResult parse(
    String text, {
    String? stationId,
    OcrLocaleProfile? profile,
    OcrTraceRecorder? trace,
  }) {
    final lines = text.split('\n').map((l) => l.trim()).toList();
    final fullText = lines.join(' ');

    final brand = detectBrand(lines, fullText);
    final layout = switch (brand) {
      'super_u' => 'super_u',
      'carrefour' => 'carrefour',
      _ => 'generic',
    };
    trace?.brand(brand, layout);
    final initial = switch (brand) {
      'super_u' => parseSuperU(fullText, lines, profile: profile),
      'carrefour' => parseCarrefour(fullText, lines, profile: profile),
      _ => parseGeneric(fullText, lines, profile: profile),
    };

    final withOverrides = _applyOverrides(initial, text, stationId, trace);
    final reconciled = reconcile(withOverrides);
    trace?.reconcile(
      read: withOverrides.totalCost,
      derived: reconciled.totalCost,
      predictedTotal: (withOverrides.liters != null &&
              withOverrides.pricePerLiter != null)
          ? withOverrides.liters! * withOverrides.pricePerLiter!
          : null,
      delta: (withOverrides.totalCost != null && reconciled.totalCost != null)
          ? (reconciled.totalCost! - withOverrides.totalCost!).abs()
          : null,
    );
    trace?.result(
      totalCost: reconciled.totalCost,
      liters: reconciled.liters,
      pricePerLiter: reconciled.pricePerLiter,
    );
    return reconciled;
  }

  /// Geometry-aware parse for the receipt OCR path (#2848).
  ///
  /// When ML Kit's [blocks] (with their boxes) look like a fuel-station
  /// receipt — pump/volume/price markers plus a per-litre signal — the
  /// values sit in a right column row-aligned with their left-column
  /// labels, exactly the geometry the pump-display path already solves.
  /// We route those to the label-anchored extractor (binding Volume→
  /// litres, Prix→€/L, TOT TTC→total by row) + the SAME validation gate,
  /// so a fully-legible FR receipt comes back with all three fields and
  /// `validated:true`. Everything else falls back to the flat-string
  /// [parse], byte-for-byte unchanged — strictly additive.
  ReceiptParseResult parseBlocks(
    List<RecognizedTextBlock> blocks,
    String text, {
    String? stationId,
    OcrLocaleProfile? profile,
    PumpValidationGate gate = const PumpValidationGate(),
    OcrTraceRecorder? trace,
  }) {
    if (shouldUseReceiptLabelAnchor(text, blocks)) {
      final lines = text.split('\n').map((l) => l.trim()).toList();
      trace?.brand(null, 'fuel_station');
      final anchored = orchestrateReceiptParse(
        blocks: blocks,
        text: text,
        lines: lines,
        profile: profile,
        gate: gate,
        trace: trace,
      );
      // The geometry read found enough → use it. If it read fewer than two
      // fields (sparse/fused boxes), defer to the flat-string parser so we
      // never regress a receipt the generic path could still handle.
      if (anchored.derived.isNotEmpty ||
          [anchored.liters, anchored.totalCost, anchored.pricePerLiter]
                  .where((v) => v != null)
                  .length >=
              2) {
        return _applyOverrides(anchored, text, stationId, trace);
      }
    }
    return parse(text, stationId: stationId, profile: profile, trace: trace);
  }

  /// Apply per-station overrides on top of the brand-layout result. Any
  /// non-null field on the matching [OverrideSpec] replaces the default.
  /// If the override's regex doesn't match, the brand layout's value
  /// survives — an unmatched override is never worse than no override.
  ReceiptParseResult _applyOverrides(
    ReceiptParseResult result,
    String text,
    String? stationId, [
    OcrTraceRecorder? trace,
  ]) {
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
    if (overrideLiters != null) {
      liters = overrideLiters;
      _traceOverride(trace, 'liters', spec.liters, text, overrideLiters);
    }

    final overrideTotal = _overrideDecimal(spec.totalCost, text);
    if (overrideTotal != null) {
      totalCost = overrideTotal;
      _traceOverride(trace, 'totalCost', spec.totalCost, text, overrideTotal);
    }

    final overridePpl = _overrideDecimal(spec.pricePerLiter, text);
    if (overridePpl != null) {
      pricePerLiter = overridePpl;
      _traceOverride(
          trace, 'pricePerLiter', spec.pricePerLiter, text, overridePpl);
    }

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
      // #2848 — carry the geometry-aware path's validation metadata through
      // the override merge so a fuel_station read keeps validated/confidence.
      confidence: result.confidence,
      validated: result.validated,
      validationReason: result.validationReason,
      derived: result.derived,
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

  /// Records one fired override field on [trace] (no-op when null) —
  /// trace-only, never on the production parse path (#2517).
  void _traceOverride(
    OcrTraceRecorder? trace,
    String field,
    OverrideFieldSpec? spec,
    String text,
    double value,
  ) {
    if (trace == null || spec == null) return;
    trace.overrideField(
      field: field,
      pattern: spec.pattern,
      match: spec.extract(text) ?? '',
      value: value,
    );
  }
}
