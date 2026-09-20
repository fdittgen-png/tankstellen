// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fleet/claim_class.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/fleet/domain/document_meta.dart';
import 'package:tankstellen/features/fleet/domain/expense.dart';
import 'package:tankstellen/features/fleet/domain/expense_fields.dart';
import 'package:tankstellen/features/fleet/domain/money.dart';

/// #4215 (F5) — the persisted contract of an expense and its document,
/// and the rule that keeps receipt IMAGE BYTES out of everything that
/// travels.
void main() {
  final at = DateTime.utc(2026, 3, 11, 14, 30);

  final fields = ExtractedReceiptFields(
    stationName: 'TotalEnergies Toulouse',
    occurredAt: at,
    fuelApiValue: 'diesel',
    litres: 62.4,
    pricePerLitre: 1.749,
    total: const Money(amount: 109.14, currency: 'EUR'),
    vat: const Money(amount: 18.19, currency: 'EUR'),
    vatRate: 20,
    paymentReference: '****4417',
    odometerKm: 128450,
  );

  final expense = Expense(
    id: 'exp-1',
    orgId: 'org-1',
    userId: 'user-1',
    fillUpId: 'fill-7',
    fleetAttribution: FleetAttribution(
      orgId: 'org-1',
      fleetVehicleId: 'veh-3',
      assignmentId: 'asg-9',
      capturedAt: at,
    ),
    extracted: fields,
    confirmed: fields.copyWith(litres: 62.35),
    corrections: [
      FieldCorrection(
        field: 'litres',
        before: '62.4',
        after: '62.35',
        correctedAt: at,
        correctedBy: 'user-1',
      ),
    ],
    documentId: 'doc-1',
    importSource: ExpenseImportSource.ocrPhoto,
    status: ExpenseStatus.needsReview,
    history: [
      ExpenseTransition(
        from: ExpenseStatus.draft,
        to: ExpenseStatus.needsReview,
        at: at,
        byUserId: 'user-1',
      ),
    ],
  );

  final document = DocumentMeta(
    id: 'doc-1',
    orgId: 'org-1',
    ownerId: 'user-1',
    type: FleetDocumentType.receiptPhoto,
    objectKey: 'org-1/2026/06/doc-1.jpg',
    sha256: 'a3f1b9c0d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1',
    capturedAt: at,
    ocrEngine: 'mlkit',
    ocrVersion: '0.20.0',
    confidence: 0.9,
    retentionClass: DocumentRetentionClass.accountingDocument,
  );

  group('JSON round-trip', () {
    test('an expense survives encode → decode unchanged, corrections and '
        'history included', () {
      final decoded =
          Expense.fromJson(jsonDecode(jsonEncode(expense.toJson()))
              as Map<String, dynamic>);
      expect(decoded, expense);
      expect(decoded.extracted.litres, 62.4,
          reason: 'the machine read must survive persistence');
      expect(decoded.confirmed.litres, 62.35);
      expect(decoded.corrections.single.correctedBy, 'user-1');
      expect(decoded.history.single.to, ExpenseStatus.needsReview);
      expect(decoded.claim, ClaimClass.accountingCandidate);
    });

    test('Money keeps its ISO code through the round-trip', () {
      final decoded =
          Expense.fromJson(jsonDecode(jsonEncode(expense.toJson()))
              as Map<String, dynamic>);
      expect(decoded.extracted.total, const Money(amount: 109.14, currency: 'EUR'));
      expect(decoded.extracted.vat?.currency, 'EUR');
    });

    test('a document meta survives encode → decode unchanged', () {
      final decoded =
          DocumentMeta.fromJson(jsonDecode(jsonEncode(document.toJson()))
              as Map<String, dynamic>);
      expect(decoded, document);
      expect(decoded.isReadable, isTrue);
      expect(decoded.isRetentionGoverned, isTrue);
    });
  });

  group('claim class', () {
    test('an expense is always an accounting CANDIDATE — never a fact', () {
      expect(expense.claim, ClaimClass.accountingCandidate);
      expect(expense.requiresConfirmation, isTrue);
      expect(expense.claim.requiresConfirmation, isTrue);
    });

    test('a photographed receipt can never be authoritative', () {
      expect(expense.authoritative, isFalse);
      expect(ExpenseImportSource.ocrPhoto.mayBeAuthoritative, isFalse);
      expect(ExpenseImportSource.ocrPdf.mayBeAuthoritative, isFalse);
      expect(ExpenseImportSource.eReceiptText.mayBeAuthoritative, isFalse);
      expect(
          ExpenseImportSource.structuredInvoice.mayBeAuthoritative, isTrue);
    });
  });

  group('no image bytes leave the pipeline', () {
    test('neither an expense nor a document meta can carry bytes — the '
        'JSON has no byte-shaped field at all', () {
      final blob = '${jsonEncode(expense.toJson())}'
          '${jsonEncode(document.toJson())}';
      for (final forbidden in ['base64', 'bytes', 'imageData', 'thumbnail']) {
        expect(blob.toLowerCase(), isNot(contains(forbidden.toLowerCase())),
            reason: 'ADR 0025: the image lives in private object storage; '
                'only its key travels');
      }
      expect(document.toJson()['objectKey'], isNotNull);
    });

    test('the fleet source itself cannot hold bytes — no Uint8List, no '
        'base64, no typed_data anywhere in the slice', () {
      final offenders = <String>[];
      for (final entity in Directory('lib/features/fleet')
          .listSync(recursive: true)
          .whereType<File>()) {
        final path = entity.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart')) continue;
        // Comments are prose ABOUT the rule (document_meta.dart spells
        // it out); the ban is on code.
        final code = entity
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final banned in ['Uint8List', 'dart:typed_data', 'base64']) {
          if (code.contains(banned)) offenders.add('$path: $banned');
        }
      }
      expect(offenders, isEmpty,
          reason: 'a receipt image must not be representable in the fleet '
              'domain — that is what makes "never in a log" structural');
    });

    test('the OCR trace serialiser elides the capture on the size-bounded '
        'sink, so a trace copied out of the app carries no image', () {
      final package = OcrTracePackage(
        kind: OcrTraceKind.receipt,
        capturedAt: at,
        input: const OcrTraceInput(country: 'FR'),
        image: const OcrTraceImage(fileName: 'scan.jpg', base64: 'AAAABBBB'),
      );
      expect(package.toJson(includeImage: false).containsKey('image'),
          isFalse);
      expect(jsonEncode(package.toJson(includeImage: false)),
          isNot(contains('AAAABBBB')));
    });
  });
}
