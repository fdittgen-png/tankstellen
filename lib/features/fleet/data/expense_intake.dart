// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The ONE door every source document walks through on its way to an
/// [Expense] (#4215).
///
/// A photographed receipt, a shared e-receipt text, a rasterised PDF
/// and a received electronic invoice arrive in four different shapes
/// and leave here as the same [ExtractedReceiptFields] inside the same
/// [Expense]. That is the whole point of the boundary: France's
/// e-invoicing reform makes structured invoices routine from
/// 1 September 2026, and the downstream workflow must not fork.
///
/// What the boundary refuses to flatten is [Expense.authoritative]. A
/// structured invoice CAN be an authoritative record; a photograph
/// never is, whatever its OCR confidence — so the flag comes from the
/// channel, not from the parse quality.
library;

import '../domain/expense.dart';
import '../domain/expense_fields.dart';
import '../domain/money.dart';

/// A received electronic invoice, reduced to the fuel purchase it
/// records (#4215).
///
/// Deliberately not a full e-invoice model: this slice needs the same
/// ten facts a receipt carries, and a structured invoice supplies them
/// without a guess. Amounts arrive already denominated — a structured
/// document states its currency as an ISO code, so there is nothing to
/// infer from a symbol.
class StructuredFuelInvoice {
  const StructuredFuelInvoice({
    required this.sellerName,
    required this.issuedAt,
    required this.litres,
    required this.pricePerLitre,
    required this.total,
    this.fuelApiValue,
    this.vat,
    this.vatRate,
    this.paymentReference,
    this.odometerKm,
  });

  /// Reads the subset of a structured invoice payload this slice uses.
  /// Returns null when a mandatory fact is missing or mistyped — an
  /// invoice that cannot be read is not silently half-imported.
  static StructuredFuelInvoice? fromJson(Map<String, dynamic> json) {
    final seller = json['seller_name'];
    final issued = _utc(json['issued_at']);
    final litres = _asDouble(json['litres']);
    final price = _asDouble(json['price_per_litre']);
    final total = _money(json['total']);
    if (seller is! String || issued == null) return null;
    if (litres == null || price == null || total == null) return null;
    return StructuredFuelInvoice(
      sellerName: seller,
      issuedAt: issued,
      litres: litres,
      pricePerLitre: price,
      total: total,
      fuelApiValue: json['fuel'] as String?,
      vat: _money(json['vat']),
      vatRate: _asDouble(json['vat_rate']),
      paymentReference: json['payment_reference'] as String?,
      odometerKm: _asDouble(json['odometer_km']),
    );
  }

  final String sellerName;
  final DateTime issuedAt;
  final double litres;
  final double pricePerLitre;
  final Money total;
  final String? fuelApiValue;
  final Money? vat;
  final double? vatRate;
  final String? paymentReference;
  final double? odometerKm;

  /// The same field set an OCR read produces.
  ExtractedReceiptFields toFields() => ExtractedReceiptFields(
        stationName: sellerName,
        occurredAt: issuedAt,
        fuelApiValue: fuelApiValue,
        litres: litres,
        pricePerLitre: pricePerLitre,
        total: total,
        vat: vat,
        vatRate: vatRate,
        paymentReference: paymentReference,
        odometerKm: odometerKm,
      );

  static double? _asDouble(Object? raw) =>
      raw is num ? raw.toDouble() : (raw is String ? double.tryParse(raw) : null);

  static Money? _money(Object? raw) {
    if (raw is! Map) return null;
    final amount = _asDouble(raw['amount']);
    final currency = raw['currency'];
    if (amount == null || currency is! String || currency.length != 3) {
      return null;
    }
    return Money(amount: amount, currency: currency.toUpperCase());
  }

  static DateTime? _utc(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
}

/// A parsed receipt as the fleet domain sees it (#4215).
///
/// [fallbackCurrency] supplies the ISO code when the paper printed
//// What a parsed receipt states, as plain values (#4215).
///
/// Deliberately NOT `ReceiptParseResult`. `fill_ups` imports `fleet`
/// for the vehicle attribution a record is stamped with (#4213), so
/// fleet must stay a leaf of the feature graph — an import of
/// `receipts_ocr` puts it inside the big cycle that
/// `feature_boundary_test`'s barrel-aware SCC gate (#4346) rejects.
/// The same reasoning as [FillUpMatchCandidate].
///
/// The scanner owns OCR; fleet owns what an expense is. Mapping one to
/// the other is the integration point's job, and it is one line per
/// field.
class ParsedReceiptFacts {
  const ParsedReceiptFacts({
    this.stationName,
    this.date,
    this.fuelApiValue,
    this.liters,
    this.pricePerLiter,
    this.totalCost,
    this.vatAmount,
    this.vatRate,
    this.paymentReference,
    this.odometerKm,
    this.currency,
  });

  final String? stationName;
  final DateTime? date;

  /// `FuelType.apiValue`, not the enum — the enum lives in core, but
  /// passing the string keeps this type free of even that coupling and
  /// matches what [ExtractedReceiptFields] stores.
  final String? fuelApiValue;
  final double? liters;
  final double? pricePerLiter;
  final double? totalCost;
  final double? vatAmount;
  final double? vatRate;
  final String? paymentReference;
  final double? odometerKm;

  /// ISO code the document itself stated, or null when it stated none.
  final String? currency;
}

// none and no locale profile was threaded. Without a currency there
/// is no [Money] and therefore no total — which the reconciler turns
/// into [ExpenseStatus.needsReview] rather than a euro assumption.
ExtractedReceiptFields extractedFieldsFromReceipt(
  ParsedReceiptFacts parsed, {
  String? fallbackCurrency,
}) {
  final code = parsed.currency ?? fallbackCurrency;
  Money? amount(double? value) => value == null || code == null
      ? null
      : Money(amount: value, currency: code.toUpperCase());
  return ExtractedReceiptFields(
    stationName: parsed.stationName,
    occurredAt: parsed.date,
    fuelApiValue: parsed.fuelApiValue,
    litres: parsed.liters,
    pricePerLitre: parsed.pricePerLiter,
    total: amount(parsed.totalCost),
    vat: amount(parsed.vatAmount),
    vatRate: parsed.vatRate,
    paymentReference: parsed.paymentReference,
    odometerKm: parsed.odometerKm,
  );
}

/// Builds the expense candidate for a scanned or shared receipt.
///
/// `confirmed` starts equal to `extracted` — the employee has not
/// answered yet — and `authoritative` is hard-wired false: a
/// photograph is never an authoritative document. The status stays
/// [ExpenseStatus.draft] here; `ExpenseReconciler.intake` is what
/// decides whether it needs review.
Expense buildExpenseFromReceipt({
  required String id,
  required String orgId,
  required String userId,
  required ParsedReceiptFacts parsed,
  required ExpenseImportSource importSource,
  String? documentId,
  String? fallbackCurrency,
  FleetAttribution? fleetAttribution,
}) {
  final fields =
      extractedFieldsFromReceipt(parsed, fallbackCurrency: fallbackCurrency);
  return Expense(
    id: id,
    orgId: orgId,
    userId: userId,
    extracted: fields,
    confirmed: fields,
    documentId: documentId,
    importSource: importSource,
    fleetAttribution: fleetAttribution,
  );
}

/// Builds the expense candidate for a received structured invoice.
///
/// Same type, same fields, same downstream workflow — the only
/// difference is [authoritative], which a deployment sets when the
/// channel the invoice arrived on makes it a record rather than a
/// claim.
Expense buildExpenseFromInvoice({
  required String id,
  required String orgId,
  required String userId,
  required StructuredFuelInvoice invoice,
  String? documentId,
  bool authoritative = true,
  FleetAttribution? fleetAttribution,
}) {
  final fields = invoice.toFields();
  return Expense(
    id: id,
    orgId: orgId,
    userId: userId,
    extracted: fields,
    confirmed: fields,
    documentId: documentId,
    importSource: ExpenseImportSource.structuredInvoice,
    authoritative: authoritative,
    fleetAttribution: fleetAttribution,
  );
}
