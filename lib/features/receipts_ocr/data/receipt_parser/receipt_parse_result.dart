// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/fuel_type.dart';
import 'receipt_fiscal_extractors.dart';

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

  /// Brand layout the parser used — "super_u", "carrefour", "generic", or
  /// "fuel_station" (the #2848 geometry-aware label-anchored read).
  /// Exposed so tests and telemetry can verify dispatch went to the
  /// specialised branch when a well-known receipt layout is scanned.
  final String brandLayout;

  /// Read confidence in [0, 1] (#2848). Only the geometry-aware
  /// fuel-station path scores this; the flat-string paths leave it 0.
  final double confidence;

  /// `true` when the geometry-aware read passed the per-country
  /// validation gate (in-range + `litres × €/L ≈ total`) — #2848. The
  /// flat-string paths leave it false, exactly as before.
  final bool validated;

  /// Machine-readable validation reason code (diagnostics, not
  /// user-facing); null on the flat-string paths.
  final String? validationReason;

  /// Fields whose value the cross-check DERIVED rather than read directly
  /// (`'totalCost'` / `'liters'` / `'pricePerLiter'`) — #2848.
  final Set<String> derived;

  /// VAT amount as printed, in the major unit of [currency] (#4215).
  /// Null on every receipt that prints no VAT line — and on every
  /// pre-#4215 caller, which is why the whole fiscal block is additive
  /// and nullable: no existing consumption path changes behaviour.
  final double? vatAmount;

  /// VAT rate in percent as printed (`20.0` for `TVA 20,00 %`) — #4215.
  final double? vatRate;

  /// ISO 4217 code the amounts are denominated in (`EUR`, `GBP`, …),
  /// never a symbol (#4215). Null when the paper is silent and no
  /// locale profile was threaded.
  final String? currency;

  /// Masked payment / fuel-card reference (`****1234`) or the printed
  /// document reference. Never a full card number — the masking
  /// happens in the extractor, not at the render site (#4215).
  final String? paymentReference;

  /// Odometer reading in kilometres when the forecourt printed one
  /// (#4215). Fleet pumps routinely ask the driver to key it in.
  final double? odometerKm;

  const ReceiptParseResult({
    this.liters,
    this.totalCost,
    this.pricePerLiter,
    this.date,
    this.stationName,
    this.fuelType,
    this.brandLayout = 'generic',
    this.confidence = 0,
    this.validated = false,
    this.validationReason,
    this.derived = const {},
    this.vatAmount,
    this.vatRate,
    this.currency,
    this.paymentReference,
    this.odometerKm,
  });

  /// `true` when the parser extracted at least volume or total cost.
  bool get hasData => liters != null || totalCost != null;

  /// This result with [fiscal] attached (#4215).
  ///
  /// The fiscal read is a separate, additive pass over the same text,
  /// applied at the very END of a parse so the brand-layout merge, the
  /// per-station override merge and the cross-field reconciliation —
  /// all of which rebuild a result — cannot drop it on the way.
  ReceiptParseResult withFiscal(ReceiptFiscalFields fiscal) =>
      ReceiptParseResult(
        liters: liters,
        totalCost: totalCost,
        pricePerLiter: pricePerLiter,
        date: date,
        stationName: stationName,
        fuelType: fuelType,
        brandLayout: brandLayout,
        confidence: confidence,
        validated: validated,
        validationReason: validationReason,
        derived: derived,
        vatAmount: fiscal.vatAmount,
        vatRate: fiscal.vatRate,
        currency: fiscal.currency,
        paymentReference: fiscal.paymentReference,
        odometerKm: fiscal.odometerKm,
      );
}
