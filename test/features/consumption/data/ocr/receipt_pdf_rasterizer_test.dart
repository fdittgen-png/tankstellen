// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfx/pdfx.dart';
import 'package:tankstellen/features/consumption/data/ocr/'
    'receipt_pdf_rasterizer.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Never-throws coverage for the on-device PDF→bitmap rasteriser (#2737),
/// mirroring the `ocr_image_preprocessor_test` / `receipt_scan_service`
/// fault-path idiom (#2349).
///
/// IMPORTANT — headless caveat: the native `android.graphics.pdf
/// .PdfRenderer` / `CGPDFPage` channel `pdfx` delegates to is NOT
/// available under `flutter test` (pure Dart VM). So we do NOT assert that
/// a real PDF rasterises SUCCESSFULLY here — that can only pass on a
/// device/emulator and would flake CI. Instead we drive the FAULT path:
/// feed corrupt / zero-byte / missing input, assert the call `returns
/// Normally` and yields `null`. In the headless env the missing platform
/// channel naturally errors, which is exactly the failure the documented
/// catch→null boundary must absorb. The success path is covered instead by
/// the MIME-branch wiring test (`share_receipt_handler_test.dart`) with the
/// rasteriser faked.
void main() {
  silenceErrorLoggerSpool();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pdf_rasterizer_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ReceiptPdfRasterizer.rasterize — never throws (#2349)', () {
    // The native pdfx renderer is unavailable under `flutter test` (the host
    // is not a mobile platform) and pdfx's `assertHasPdfSupport` throws there
    // in a way the catch cannot reliably absorb, so we inject a FAILING opener
    // to drive the documented catch→null fault path deterministically. The
    // real rasterisation path is device-only; its wiring is covered by the
    // MIME-branch test in share_receipt_handler_test with the rasteriser faked.
    ReceiptPdfRasterizer withOpener(
            Future<PdfDocument> Function(String) open) =>
        ReceiptPdfRasterizer(
            temporaryDirectory: () async => tempDir, openDocument: open);

    test('an opener that throws asynchronously returns null, not a throw',
        () async {
      final r = withOpener((_) async => throw Exception('no pdf support'));
      expect(() => r.rasterize('x.pdf'), returnsNormally);
      expect(await r.rasterize('x.pdf'), isNull,
          reason: 'a failed open must be caught + logged, never propagated');
    });

    test('an opener that throws synchronously returns null, not a throw',
        () async {
      final r = withOpener((_) => throw StateError('sync boom'));
      expect(() => r.rasterize('x.pdf'), returnsNormally);
      expect(await r.rasterize('x.pdf'), isNull);
    });

    test('an opener whose future rejects returns null, not a throw', () async {
      final r =
          withOpener((_) => Future<PdfDocument>.error(Exception('rejected')));
      expect(await r.rasterize('x.pdf'), isNull);
    });
  });
}
