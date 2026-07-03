// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../ocr/ocr_trace_recorder.dart';
import '../ocr/pump_ocr_config.dart';
import '../ocr/pump_validation_gate.dart';
import '../ocr/recognized_text_block.dart';
import 'brand_detection.dart';
import 'receipt_field_extractors.dart';
import 'receipt_parse_result.dart';
import 'receipt_spatial_lexicon.dart';
import 'receipt_spatial_parser.dart';
import 'receipt_value_token.dart';

/// Orchestrates the spatial fuel-receipt read (#3458, rewriting #2848).
///
/// Runs the pure [parseReceiptSpatially] over ML Kit's [blocks], then
/// applies the HONEST gate rules the Pézenas E85 field failure demanded:
///
///  * **Confidence counts only independently-READ fields** — 0.3 per
///    read field, +0.1 only when all THREE were read and satisfy the
///    identity. A derived field can never raise confidence.
///  * **The gate sees only read fields.** 3 read → identity check;
///    2 read → range/partial acceptance. The old flow derived the third
///    value first and then let the gate "verify" `litres × €/L ≈ total`
///    on the number it had just computed from those same two — the
///    tautology that stamped confidence 1.0 on a scrambled read.
///  * **Derivation happens AFTER acceptance, at reduced confidence**
///    (the 2-read score stands; the derived field is flagged in
///    [ReceiptParseResult.derived]).
///  * **Rejection is honest**: the read fields are still returned as
///    prefill candidates (`validated: false` + reason), so the caller's
///    existing form-prefill path becomes assisted manual entry — the
///    user verifies; nothing is silently accepted.
///
/// The per-currency plausibility band comes from the threaded
/// [OcrLocaleProfile] when the active country is known, else from the
/// currency symbol printed on the paper (€, Kč, Ft, zł, CHF, £, kr),
/// else the EUR default — so range validation ALWAYS runs (#3458
/// defect 3: 41.39 €/L must be absurd even with no profile threaded).
ReceiptParseResult orchestrateReceiptParse({
  required List<RecognizedTextBlock> blocks,
  required String text,
  required List<String> lines,
  OcrLocaleProfile? profile,
  PumpValidationGate gate = const PumpValidationGate(),
  OcrTraceRecorder? trace,
}) {
  final rangeOverride = profile == null
      ? null
      : ReceiptCurrencyRange(
          code: profile.currency,
          priceMin: profile.priceMin,
          priceMax: profile.priceMax,
          totalMax: profile.totalMax,
        );
  final read = parseReceiptSpatially(
    blocks,
    rangeOverride: rangeOverride,
    volumeMax: profile?.volumeMax,
    trace: trace,
  );

  // Prose fields the geometry path never produces — read from flat text.
  final date = extractDate(text);
  final stationName = extractStationName(lines);
  final fuelType = extractFuelType(text);

  // HONEST confidence — read fields only; derived never raises it.
  final readCount = read.readFields.length;
  final isConsistent = read.isConsistentRead;
  var confidence = 0.3 * readCount;
  if (isConsistent) confidence += 0.1;
  confidence = confidence.clamp(0.0, 1.0);
  trace?.confidence(
    hasTotal: read.totalCost != null,
    hasVolume: read.liters != null,
    hasPrice: read.pricePerLiter != null,
    isConsistent: isConsistent,
    total: confidence,
  );

  // The gate evaluates READ fields only. Range checks always run: the
  // threaded profile wins, else a profile synthesized from the currency
  // printed on the paper (or the EUR default).
  final gateProfile = profile ?? _profileFromRange(read.range);
  final result = gate.evaluate(
    total: read.totalCost,
    volume: read.liters,
    pricePerLitre: read.pricePerLiter,
    confidence: confidence,
    profile: gateProfile,
    trace: trace,
  );

  // Derive the missing third ONLY after acceptance, flagged, at the
  // unchanged 2-read confidence.
  var total = read.totalCost;
  var liters = read.liters;
  var price = read.pricePerLiter;
  final derivedNames = <String>{};
  if (result.accepted && readCount == 2) {
    if (total == null && liters != null && price != null) {
      total = double.parse((liters * price).toStringAsFixed(2));
      derivedNames.add('totalCost');
      trace?.crossCheck(
          volume: liters, price: price, derivedPath: 'total', computed: total);
    } else if (liters == null && total != null && price != null && price > 0) {
      liters = double.parse((total / price).toStringAsFixed(2));
      derivedNames.add('liters');
      trace?.crossCheck(
          total: total, price: price, derivedPath: 'volume', computed: liters);
    } else if (price == null && total != null && liters != null && liters > 0) {
      price = double.parse((total / liters).toStringAsFixed(3));
      derivedNames.add('pricePerLiter');
      trace?.crossCheck(
          total: total, volume: liters, derivedPath: 'price', computed: price);
    }
  }

  trace?.result(
    totalCost: total,
    liters: liters,
    pricePerLiter: price,
    derived: derivedNames,
    confidence: confidence,
    validated: result.accepted,
    validationReason: result.reason,
  );

  return ReceiptParseResult(
    liters: liters,
    totalCost: total,
    pricePerLiter: price,
    date: date,
    stationName: stationName,
    fuelType: fuelType,
    brandLayout: 'fuel_station',
    confidence: confidence,
    validated: result.accepted,
    validationReason: result.reason,
    derived: derivedNames,
  );
}

/// `true` when [text] / [blocks] look like a fuel-station receipt that
/// should route to [orchestrateReceiptParse] instead of the generic
/// flat-string parser: either the legacy flat-text markers (#2848) or —
/// language-agnostic — the classified blocks themselves carry two
/// distinct transaction labels plus value tokens (#3458).
bool shouldUseReceiptLabelAnchor(
  String text,
  List<RecognizedTextBlock> blocks,
) {
  if (blocks.length < 2) return false;
  if (looksLikeFuelStationReceipt(text)) return true;
  return hasSpatialRoutingSignal(blocks);
}

/// Synthesizes the gate profile from the plausibility band the spatial
/// read used (paper-detected currency or the EUR default), so range
/// checks run even when no country/locale profile is threaded.
OcrLocaleProfile _profileFromRange(ReceiptCurrencyRange range) =>
    OcrLocaleProfile(
      // i18n-ignore: trace-only diagnostics marker, not UI.
      country: 'auto',
      currency: range.code,
      decimalSeparator: ',',
      priceMin: range.priceMin,
      priceMax: range.priceMax,
      volumeMax: kReceiptVolumeMax,
      totalMax: range.totalMax,
    );
