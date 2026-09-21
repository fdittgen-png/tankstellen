// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/fleet/data/expense_intake.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/expense_reconciler.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';
import 'package:tankstellen/features/receipts_ocr/api.dart'
    show EReceiptTextParser, parsedReceiptFactsOf;

/// #4215 (F5) — the import boundary: a photographed receipt, an
/// e-receipt text and a structured electronic invoice must reach the
/// SAME [Expense] contract, differing only where they genuinely differ.
void main() {
  const parser = EReceiptTextParser();
  const reconciler = ExpenseReconciler();

  String fixture(String name) => File(
        'test/features/receipts_ocr/data/ereceipt/fixtures/$name',
      ).readAsStringSync();

  /// The same purchase as `totalfleet_toulouse_2026-06-08.txt`, as a
  /// structured invoice would deliver it.
  final invoicePayload = <String, dynamic>{
    'seller_name': 'TOTALENERGIES',
    'issued_at': '2026-06-08T00:00:00Z',
    'fuel': 'diesel',
    'litres': 62.40,
    'price_per_litre': 1.749,
    'total': {'amount': 109.14, 'currency': 'EUR'},
    'vat': {'amount': 18.19, 'currency': 'EUR'},
    'vat_rate': 20.0,
    'payment_reference': '****4417',
    'odometer_km': 128450,
  };

  test('an OCR read and a structured invoice produce the same field set',
      () {
    final parsed =
        parser.parse(fixture('totalfleet_toulouse_2026-06-08.txt'),
            countryCode: 'FR');
    final fromOcr = extractedFieldsFromReceipt(parsedReceiptFactsOf(parsed));
    final invoice = StructuredFuelInvoice.fromJson(invoicePayload)!;
    final fromInvoice = invoice.toFields();

    expect(fromOcr.litres, closeTo(fromInvoice.litres!, 0.001));
    expect(fromOcr.pricePerLitre, closeTo(fromInvoice.pricePerLitre!, 0.001));
    expect(fromOcr.total, fromInvoice.total);
    expect(fromOcr.vat, fromInvoice.vat);
    expect(fromOcr.vatRate, fromInvoice.vatRate);
    expect(fromOcr.paymentReference, fromInvoice.paymentReference);
    expect(fromOcr.odometerKm, fromInvoice.odometerKm);
    expect(fromOcr.fuelApiValue, fromInvoice.fuelApiValue);
    expect(fromOcr.occurredAt, DateTime(2026, 6, 8));
  });

  test('both reach the same Expense contract, and both reconcile', () {
    final parsed =
        parser.parse(fixture('totalfleet_toulouse_2026-06-08.txt'),
            countryCode: 'FR');
    final scanned = buildExpenseFromReceipt(
      id: 'exp-scan',
      orgId: 'org-1',
      userId: 'user-1',
      parsed: parsedReceiptFactsOf(parsed),
      importSource: ExpenseImportSource.ocrPhoto,
    );
    final imported = buildExpenseFromInvoice(
      id: 'exp-inv',
      orgId: 'org-1',
      userId: 'user-1',
      invoice: StructuredFuelInvoice.fromJson(invoicePayload)!,
    );

    for (final e in [scanned, imported]) {
      expect(e.status, ExpenseStatus.draft);
      expect(e.confirmed, e.extracted,
          reason: 'nothing is confirmed until the employee answers');
      expect(e.corrections, isEmpty);
      expect(reconciler.checkArithmetic(e.confirmed),
          ExpenseArithmetic.reconciled);
      expect(reconciler.statusForIntake(e.confirmed), ExpenseStatus.draft);
    }

    // The ONE difference the boundary refuses to flatten.
    expect(scanned.authoritative, isFalse);
    expect(scanned.importSource, ExpenseImportSource.ocrPhoto);
    expect(imported.authoritative, isTrue);
    expect(imported.importSource, ExpenseImportSource.structuredInvoice);
  });

  test('an e-receipt TEXT walks the same door as a photographed receipt',
      () {
    final parsed = parser.parse(fixture('aral_koeln_2026-05-28.txt'),
        countryCode: 'DE');
    final e = buildExpenseFromReceipt(
      id: 'exp-1',
      orgId: 'org-1',
      userId: 'user-1',
      parsed: parsedReceiptFactsOf(parsed),
      importSource: ExpenseImportSource.eReceiptText,
    );
    expect(e.extracted.total, const Money(amount: 77.52, currency: 'EUR'));
    expect(e.extracted.vat, const Money(amount: 12.38, currency: 'EUR'));
    expect(e.authoritative, isFalse);
  });

  test('no currency means no total — the euro is never assumed', () {
    const noCurrency = ExtractedReceiptFields(litres: 40, pricePerLitre: 1.6);
    expect(noCurrency.total, isNull);
    expect(reconciler.statusForIntake(noCurrency),
        ExpenseStatus.needsReview);
  });

  test('a structured invoice missing a mandatory fact is refused, not '
      'half-imported', () {
    expect(
        StructuredFuelInvoice.fromJson({
          ...invoicePayload,
          'total': null,
        }),
        isNull);
    expect(
        StructuredFuelInvoice.fromJson({
          ...invoicePayload,
          'issued_at': 'not a date',
        }),
        isNull);
    expect(
        StructuredFuelInvoice.fromJson({
          ...invoicePayload,
          'total': {'amount': 109.14, 'currency': '€'},
        }),
        isNull,
        reason: 'a symbol is not an ISO 4217 code');
  });
}
